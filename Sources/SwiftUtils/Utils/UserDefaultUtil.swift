//
//  UserDefaultUtil.swift
//
//
//  Created by zzh on 2024/8/31.
//

import Foundation

public class UserDefaultUtil {
    private let userDefault = UserDefaults()
    public init() {
//        self.userDefault.object(forKey: <#T##String#>)
    }

    public func remove(key: String) {
        self.userDefault.removeObject(forKey: key)
    }

    public func setString(key: String, value: String) {
        self.userDefault.setValue(value, forKey: key)
    }

    public func getString(key: String, defaultValue: String?) -> String? {
        let result = self.userDefault.value(forKey: key) as? String
        return result ?? defaultValue
    }

    public func setInt(key: String, value: Int) {
        self.userDefault.setValue(value, forKey: key)
    }

    public func getInt(key: String, defaultValue: Int?) -> Int? {
        return self.userDefault.value(forKey: key) as? Int ?? defaultValue
    }

    public func setArrayString(key: String, value: [String]) {
        self.userDefault.setValue(value, forKey: key)
    }

    public func getArrayString(key: String) -> [String]? {
        return self.userDefault.array(forKey: key) as? [String]
    }

    public func getArrayLength(key: String) -> Int {
        return self.userDefault.array(forKey: key)?.count ?? 0
    }

    public func setBool(key: String, value: Bool) {
        self.userDefault.setValue(value, forKey: key)
    }

    public func getBool(key: String, defaultValue: Bool?) -> Bool? {
        return self.userDefault.value(forKey: key) as? Bool ?? defaultValue
    }

    public func hasValue(key: String) -> Bool {
        return self.userDefault.object(forKey: key) != nil
    }
}
