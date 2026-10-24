//
//  AuthUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/2/8.
//

import Foundation
import LocalAuthentication

public class AuthUtil {
    public init() {}

    /// 生物识别结果。
    public enum AuthResult: Equatable {
        case success
        /// 用户（或系统）取消了弹窗
        case cancelled
        /// 设备不支持、未录入、没设密码——引导去设置也没用或入口不同
        case unavailable(String)
        /// 验证失败、被锁定等
        case failed(String)
    }

    public func hasTouchID() -> Bool {
        return Self.checkBiometry(.touchID)
    }

    public func hasFaceID() -> Bool {
        return Self.checkBiometry(.faceID)
    }

    /// 生物识别（新接口，能区分取消 / 失败 / 不可用）。
    ///
    /// 每次调用都新建 `LAContext`：复用一个已经评估过的 context，失败或取消之后状态可能是脏的。
    /// 回调在主队列执行。
    public func authenticate(title: String = "请使用 Face ID 或 Touch ID 验证您的身份",
                             completion: @escaping (AuthResult) -> Void)
    {
        let context = LAContext()
        var error: NSError?
        let policy = Self.policy
        guard context.canEvaluatePolicy(policy, error: &error) else {
            Self.deliver(.unavailable(Self.unavailableMessage(for: error)), to: completion)
            return
        }
        #if !os(watchOS)
        guard context.biometryType == .touchID || context.biometryType == .faceID else {
            Self.deliver(.unavailable("设备不支持生物识别"), to: completion)
            return
        }
        #endif

        context.evaluatePolicy(policy, localizedReason: title) { success, error in
            if success {
                SU.log.info("生物识别通过")
                Self.deliver(.success, to: completion)
                return
            }
            let result = Self.mapError(error)
            if case .cancelled = result {
                SU.log.info("生物识别被取消")
            } else {
                SU.log.error("生物识别失败: \(Self.message(of: result))")
            }
            Self.deliver(result, to: completion)
        }
    }

    /// 旧接口，保持原有行为：成功 → `callback(true)`，取消/失败 → `callback(false)`，
    /// 设备不支持 → `fail(原因)`。
    public func authenticate(title: String = "请使用 Face ID 或 Touch ID 验证您的身份",
                             callback: @escaping (Bool) -> Void,
                             fail: @escaping (String) -> Void)
    {
        authenticate(title: title) { result in
            switch result {
            case .success:
                callback(true)
            case .cancelled, .failed:
                callback(false)
            case let .unavailable(message):
                fail(message)
            }
        }
    }

    // MARK: - 私有

    /// watchOS 不支持生物识别策略，退化为设备所有者认证
    private static var policy: LAPolicy {
        #if os(watchOS)
        return .deviceOwnerAuthentication
        #else
        return .deviceOwnerAuthenticationWithBiometrics
        #endif
    }

    private static func checkBiometry(_ type: LABiometryType) -> Bool {
        #if os(watchOS)
        return false
        #else
        // 每次新建 context，避免上一次评估留下的状态影响结果
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(policy, error: &error) else { return false }
        return context.biometryType == type
        #endif
    }

    private static func mapError(_ error: Error?) -> AuthResult {
        guard let error else { return .failed("验证失败") }
        guard let laError = error as? LAError else { return .failed(error.localizedDescription) }
        switch laError.code {
        case .userCancel, .appCancel, .systemCancel:
            return .cancelled
        case .biometryNotAvailable:
            return .unavailable("设备不支持生物识别")
        case .biometryNotEnrolled:
            return .unavailable("尚未录入 Face ID / Touch ID")
        case .passcodeNotSet:
            return .unavailable("设备未设置密码")
        case .biometryLockout:
            return .failed("生物识别已被锁定，请先输入密码解锁")
        case .authenticationFailed:
            return .failed("验证失败")
        default:
            return .failed(laError.localizedDescription)
        }
    }

    private static func unavailableMessage(for error: NSError?) -> String {
        #if os(watchOS)
        return "设备不支持该认证方式"
        #else
        if let code = error.flatMap({ LAError.Code(rawValue: $0.code) }) {
            switch code {
            case .biometryNotAvailable: return "设备不支持生物识别"
            case .biometryNotEnrolled: return "尚未录入 Face ID / Touch ID"
            case .passcodeNotSet: return "设备未设置密码"
            case .biometryLockout: return "生物识别已被锁定，请先输入密码解锁"
            default: break
            }
        }
        return "设备不支持生物识别或未启用 Touch ID"
        #endif
    }

    private static func message(of result: AuthResult) -> String {
        switch result {
        case .success: return "成功"
        case .cancelled: return "已取消"
        case let .unavailable(message), let .failed(message): return message
        }
    }

    private static func deliver(_ result: AuthResult, to completion: @escaping (AuthResult) -> Void) {
        DispatchQueue.main.async { completion(result) }
    }
}
