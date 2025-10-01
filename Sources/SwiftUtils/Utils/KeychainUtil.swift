//
//  KeychainUtil.swift
//
//
//  Created by zzh on 2024/6/24.
//

import Foundation
import Security

public class KeychainUtil {
    public init() {}

    public func update(forKey key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        // 指定新的数据
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        // 检查操作是否成功
        if status == errSecSuccess {
            print("Item updated successfully.")
            return true
        } else {
            print("Failed to update item with error code: \(status).")
            return false
        }
    }

    public func saveString(forKey key: String, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        // 检查操作是否成功
        if status == errSecSuccess {
            print("Item save successfully.")
            return true
        } else {
            print("Failed to save item with error code: \(status).")
            return false
        }
    }

    public func remove(forKey key: String) -> Bool {
        // 定义一个查询，用于指定要删除的 Keychain 条目
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        // 执行删除操作
        let status = SecItemDelete(query as CFDictionary)
        // 检查操作是否成功
        if status == errSecSuccess {
            print("Item deleted successfully.")
            return true
        } else {
            print("Failed to delete item with error code: \(status).")
            return false
        }
    }

    public func getString(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue as Any,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var dataTypeRef: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else { return nil }

        return value
    }
}
