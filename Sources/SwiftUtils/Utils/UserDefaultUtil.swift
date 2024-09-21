//
//  UserDefaultUtil.swift
//
//
//  Created by zzh on 2024/8/31.
//

import Foundation

public class UserDefaultUtil {
    private let userDefault = UserDefaults()
    public init() {}

    public func hasValue(_ key: String) -> Bool {
        return self.userDefault.object(forKey: key) != nil
    }

    public func remove(_ key: String) {
        self.userDefault.removeObject(forKey: key)
    }

    public func setString(key: String, value: String) {
        self.userDefault.setValue(value, forKey: key)
    }

    public func getString(_ key: String) -> String? {
        return self.userDefault.string(forKey: key)
    }

    public func getString(key: String, defaultValue: String) -> String {
        return self.userDefault.string(forKey: key) ?? defaultValue
    }

    public func setInt(key: String, value: Int) {
        self.userDefault.setValue(value, forKey: key)
    }

    public func getInt(_ key: String) -> Int? {
        return self.userDefault.integer(forKey: key)
    }

    public func setFloat(key: String, value: Float) {
        self.userDefault.setValue(value, forKey: key)
    }

    public func getFloat(_ key: String) -> Float? {
        return self.userDefault.float(forKey: key)
    }

    public func setArrayString(key: String, value: [String]) {
        self.userDefault.setValue(value, forKey: key)
    }

    public func getArrayString(_ key: String) -> [String] {
        return self.userDefault.array(forKey: key) as? [String] ?? []
    }

    public func getArrayLength(_ key: String) -> Int {
        return self.userDefault.array(forKey: key)?.count ?? 0
    }

    public func setBool(key: String, value: Bool) {
        self.userDefault.setValue(value, forKey: key)
    }

    public func getBool(_ key: String) -> Bool? {
        return self.userDefault.bool(forKey: key)
    }
}
