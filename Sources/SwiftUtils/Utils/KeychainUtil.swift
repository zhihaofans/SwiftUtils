//
//  KeychainUtil.swift
//
//
//  Created by zzh on 2024/6/24.
//

import Foundation
import LocalAuthentication
import Security

/// 钥匙串工具。
///
/// **存储位置**：统一使用数据保护钥匙串（data protection keychain，即 iOS 默认使用的那套）。
/// 每个查询都带 `kSecUseDataProtectionKeychain: true` 与同一个 `service`。
///
/// macOS 上旧的文件钥匙串把「哪个签名的 App 能读」记录在每条 item 的 ACL 里，
/// 重签后读取会弹「想要使用您储存在钥匙串中的机密信息」，用户点不允许后
/// `SecItemCopyMatching` 返回 `CSSMERR_CSP_USER_CANCELED`，App 侧就表现为登录态莫名丢失。
/// 数据保护钥匙串没有 ACL，权限由签名 entitlement 决定，不会弹这个框。
///
/// **前置条件（macOS）**：宿主 App 必须带 `com.apple.application-identifier` 或
/// `keychain-access-groups` entitlement（Xcode 的 Signing & Capabilities 里勾选
/// Keychain Sharing 即可）。缺失时 `SecItemAdd` 返回 `errSecMissingEntitlement`(-34018)，
/// 本工具会**回退到旧文件钥匙串**并打错误日志——宁可暂时保留 ACL 弹窗，也不让数据直接丢；
/// 一旦宿主补上 entitlement，下次启动就会回到数据保护钥匙串。
///
/// **兼容旧记录**：读取时先查数据保护钥匙串，未命中再按旧查询（不带 flag、不带 service）
/// 并禁止授权弹窗试一次。ACL 需要授权的老记录会立刻失败而不是弹窗；
/// 只有能静默读到的老记录才会被搬进数据保护钥匙串并删除旧记录。
public class KeychainUtil {
    /// 数据保护钥匙串里所有条目共用的 service。
    ///
    /// 四个操作必须带完全相同的 service：只带 `kSecClass` + `kSecAttrAccount` 时，
    /// 写入和读取可能落在不同记录上，出现「写得进去但 update/delete 匹配不到」的静默失败。
    public static let defaultService = "me.zzhhoo.easyswift"

    private let service: String

    /// 宿主缺少数据保护钥匙串所需的 entitlement 时置位，避免每次调用都重复发同样的错误日志
    private var dataProtectionUnavailable = false

    /// - Parameter service: 数据保护钥匙串条目的 service，默认 `defaultService`；
    ///   同一个 App 的所有 KeychainUtil 必须用同一个值
    public init(service: String = KeychainUtil.defaultService) {
        self.service = service
    }

    // MARK: - 公开 API

    /// 写入。已存在同 key 的记录时自动转为 update。
    public func saveString(forKey key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            SU.log.error("keychain.save: 值无法编码为 UTF-8, id: \(key)")
            return false
        }

        if !dataProtectionUnavailable {
            let status = SecItemAdd(dataProtectionAddQuery(forKey: key, data: data) as CFDictionary, nil)
            switch status {
            case errSecSuccess:
                SU.log.info("keychain.save: 写入数据保护钥匙串成功, id: \(key)")
                return true
            case errSecDuplicateItem:
                SU.log.info("keychain.save: 记录已存在，转 update, id: \(key)")
                return update(forKey: key, value: value)
            case let status where handleUnavailable(status, key: key):
                break // 宿主没有 entitlement，落到下面的旧钥匙串兜底
            default:
                SU.log.error("keychain.save: 写入数据保护钥匙串失败, status: \(status), id: \(key)")
                return false
            }
        }

        return legacySave(forKey: key, data: data)
    }

    /// 更新已有记录。新钥匙串里没有时会去旧钥匙串里找（老记录），更新成功后顺手迁移。
    public func update(forKey key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            SU.log.error("keychain.update: 值无法编码为 UTF-8, id: \(key)")
            return false
        }
        let attributes: [String: Any] = [kSecValueData as String: data]

        if !dataProtectionUnavailable {
            let status = SecItemUpdate(dataProtectionQuery(forKey: key) as CFDictionary,
                                       attributes as CFDictionary)
            switch status {
            case errSecSuccess:
                SU.log.info("keychain.update: 更新数据保护钥匙串成功, id: \(key)")
                return true
            case errSecItemNotFound:
                break // 可能是升级前的老记录，下面去旧钥匙串兜底
            case let status where handleUnavailable(status, key: key):
                break
            default:
                SU.log.error("keychain.update: 更新数据保护钥匙串失败, status: \(status), id: \(key)")
                return false
            }
        }

        // 老记录：查询里禁止授权 UI，ACL 需要确认时立即失败而不是弹窗
        let legacyStatus = SecItemUpdate(legacyQuery(forKey: key) as CFDictionary,
                                         attributes as CFDictionary)
        if legacyStatus == errSecSuccess {
            SU.log.info("keychain.update: 更新旧钥匙串记录成功, id: \(key)")
            // 既然值已经在手里，直接搬进新钥匙串，省得下次读取再走一遍兜底
            migrateLegacyItemToDataProtection(forKey: key, data: data)
            return true
        }
        SU.log.error("keychain.update: 记录不存在或无法更新, status: \(legacyStatus), id: \(key)")
        return false
    }

    /// 删除。新旧两套钥匙串里的同 key 记录都会尝试删除。
    public func remove(forKey key: String) -> Bool {
        var removed = false

        if !dataProtectionUnavailable {
            let status = SecItemDelete(dataProtectionQuery(forKey: key) as CFDictionary)
            switch status {
            case errSecSuccess:
                removed = true
            case errSecItemNotFound:
                break
            case let status where handleUnavailable(status, key: key):
                break
            default:
                SU.log.error("keychain.remove: 删除数据保护钥匙串记录失败, status: \(status), id: \(key)")
                return false
            }
        }

        // 旧记录也必须删：否则退出登录只清掉新钥匙串，下次读取会把旧记录又迁回来
        let legacyStatus = SecItemDelete(legacyQuery(forKey: key) as CFDictionary)
        switch legacyStatus {
        case errSecSuccess:
            removed = true
        case errSecItemNotFound:
            break
        default:
            SU.log.error("keychain.remove: 删除旧钥匙串记录失败, status: \(legacyStatus), id: \(key)")
            return false
        }

        if removed {
            SU.log.info("keychain.remove: 删除成功, id: \(key)")
        } else {
            SU.log.error("keychain.remove: 记录不存在, id: \(key)")
        }
        return removed
    }

    /// 读取。先查数据保护钥匙串，未命中再尝试静默读取旧记录（能读到就迁移）。
    /// 返回 `nil` 可能是「没存过」也可能是「读失败」，两者都会留下日志，日志级别不同。
    public func getString(forKey key: String) -> String? {
        if !dataProtectionUnavailable {
            var result: CFTypeRef?
            let status = SecItemCopyMatching(dataProtectionReadQuery(forKey: key) as CFDictionary, &result)
            switch status {
            case errSecSuccess:
                return decode(result, source: "数据保护钥匙串", key: key)
            case errSecItemNotFound:
                break // 正常回落到旧记录
            case let status where handleUnavailable(status, key: key):
                break
            default:
                SU.log.error("keychain.get: 读取数据保护钥匙串失败, status: \(status), id: \(key)")
                return nil
            }
        }

        // 旧记录兜底：查询里禁止授权 UI，ACL 需要确认时立刻报错，不打扰用户
        var legacyResult: CFTypeRef?
        let legacyStatus = SecItemCopyMatching(legacyReadQuery(forKey: key) as CFDictionary, &legacyResult)
        switch legacyStatus {
        case errSecSuccess:
            guard let data = legacyResult as? Data,
                  let value = String(data: data, encoding: .utf8) else {
                SU.log.error("keychain.get: 旧钥匙串记录无法按 UTF-8 解码, id: \(key)")
                return nil
            }
            SU.log.info("keychain.get: 命中旧钥匙串记录，尝试迁移, id: \(key)")
            migrateLegacyItemToDataProtection(forKey: key, data: data)
            return value
        case errSecItemNotFound:
            SU.log.debug("keychain.get: 未找到记录, id: \(key)")
            return nil
        default:
            // 这一条以前和「没存过」一样直接 return nil，导致 ACL 授权失败被当成登录态丢失
            SU.log.error("keychain.get: 读取旧钥匙串失败（可能 ACL 需要用户授权）, status: \(legacyStatus), id: \(key)")
            return nil
        }
    }

    // MARK: - 查询构造（internal 供测试钉住四条查询的一致性）

    /// 数据保护钥匙串的基础查询：四个操作共用 kSecClass + service + account + DP flag
    func dataProtectionQuery(forKey key: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecUseDataProtectionKeychain as String: true,
        ]
    }

    /// 写入查询：在基础查询上补数据与可访问性
    func dataProtectionAddQuery(forKey key: String, data: Data) -> [String: Any] {
        var query = dataProtectionQuery(forKey: key)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return query
    }

    /// 读取查询：在基础查询上补返回值与匹配策略
    func dataProtectionReadQuery(forKey key: String) -> [String: Any] {
        var query = dataProtectionQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }

    /// 旧文件钥匙串的查询：**不能**带 service 和 DP flag（老记录没有这些属性），
    /// 并且必须禁止任何授权 UI，避免 ACL 需要确认时弹窗（用户拒绝会被上层误判成登录态丢失）。
    /// 用 `LAContext.interactionNotAllowed`，它是 `kSecUseAuthenticationUIFail`
    /// 在 macOS 11 起被废弃后的官方替代。
    func legacyQuery(forKey key: String) -> [String: Any] {
        let context = LAContext()
        context.interactionNotAllowed = true
        return [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecUseAuthenticationContext as String: context,
        ]
    }

    /// 旧记录读取查询
    func legacyReadQuery(forKey key: String) -> [String: Any] {
        var query = legacyQuery(forKey: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }

    // MARK: - 私有实现

    /// 旧钥匙串写入（仅在宿主缺少数据保护钥匙串 entitlement 时使用）
    private func legacySave(forKey key: String, data: Data) -> Bool {
        var query = legacyQuery(forKey: key)
        query[kSecValueData as String] = data
        var status = SecItemAdd(query as CFDictionary, nil)
        if status == errSecDuplicateItem {
            status = SecItemUpdate(legacyQuery(forKey: key) as CFDictionary,
                                   [kSecValueData as String: data] as CFDictionary)
        }
        guard status == errSecSuccess else {
            SU.log.error("keychain.save: 回退旧钥匙串后仍失败, status: \(status), id: \(key)")
            return false
        }
        SU.log.info("keychain.save: 已写入旧钥匙串（数据保护钥匙串不可用）, id: \(key)")
        return true
    }

    /// 把旧记录搬进数据保护钥匙串，成功后才删除旧记录
    @discardableResult
    private func migrateLegacyItemToDataProtection(forKey key: String, data: Data) -> Bool {
        guard !dataProtectionUnavailable else {
            SU.log.error("keychain.migrate: 数据保护钥匙串不可用，保留旧记录, id: \(key)")
            return false
        }
        var status = SecItemAdd(dataProtectionAddQuery(forKey: key, data: data) as CFDictionary, nil)
        if status == errSecDuplicateItem {
            status = SecItemUpdate(dataProtectionQuery(forKey: key) as CFDictionary,
                                   [kSecValueData as String: data] as CFDictionary)
        }
        guard status == errSecSuccess else {
            if !handleUnavailable(status, key: key) {
                SU.log.error("keychain.migrate: 写入数据保护钥匙串失败, status: \(status)，保留旧记录, id: \(key)")
            }
            return false
        }
        let legacyStatus = SecItemDelete(legacyQuery(forKey: key) as CFDictionary)
        if legacyStatus == errSecSuccess || legacyStatus == errSecItemNotFound {
            SU.log.info("keychain.migrate: 已迁移到数据保护钥匙串并清理旧记录, id: \(key)")
        } else {
            SU.log.error("keychain.migrate: 已写入新钥匙串但删除旧记录失败, status: \(legacyStatus), id: \(key)")
        }
        return true
    }

    private func decode(_ result: CFTypeRef?, source: String, key: String) -> String? {
        guard let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            SU.log.error("keychain.get: \(source)记录无法按 UTF-8 解码, id: \(key)")
            return nil
        }
        return value
    }

    /// 统一处理「宿主没有数据保护钥匙串 entitlement」：置位、打一次带处置建议的错误日志。
    /// - Returns: 是否为该错误（是则调用方应回退旧钥匙串）
    private func handleUnavailable(_ status: OSStatus, key: String) -> Bool {
        guard status == errSecMissingEntitlement else { return false }
        dataProtectionUnavailable = true
        SU.log.error("keychain: 宿主 App 缺少数据保护钥匙串所需的 entitlement（errSecMissingEntitlement -34018），已回退到旧文件钥匙串，仍可能出现 ACL 授权弹窗。请在 Xcode 的 Signing & Capabilities 中为 App 勾选 Keychain Sharing。id: \(key)")
        return true
    }
}
