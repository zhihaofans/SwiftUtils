//
//  AuthUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/2/8.
//

import Foundation
import LocalAuthentication

public class AuthUtil {
    private var authenticator = FaceIDTouchIDAuthenticator()
    public init() {}

    public func hasTouchID() -> Bool {
        return authenticator.checkTouchID()
    }

    public func hasFaceID() -> Bool {
        return authenticator.checkFaceID()
    }

    public func authenticate(title: String = "请使用 Face ID 或 Touch ID 验证您的身份", callback: @escaping (Bool) -> Void, fail: @escaping (String) -> Void) {
        authenticator.authenticate(title: title, callback: callback, fail: fail)
    }
}

class FaceIDTouchIDAuthenticator: ObservableObject {
    private var context = LAContext()
    func checkTouchID() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) && context.biometryType == .touchID
    }

    func checkFaceID() -> Bool {
        var error: NSError?
        return context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) && context.biometryType == .faceID
    }

    func authenticate(title: String = "请使用 Face ID 或 Touch ID 验证您的身份", callback: @escaping (Bool) -> Void, fail: @escaping (String) -> Void) {
        var error: NSError?
        // 检查设备是否支持 Touch ID 或 Face ID
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            if context.biometryType == .touchID {
                // 设备支持 Touch ID
                let reason = title

                context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                    DispatchQueue.main.async {
                        print(error?.localizedDescription ?? "验证失败")
                        callback(success)
                    }
                }
            } else if context.biometryType == .faceID {
                fail("当前设备不支持 Touch ID，支持的是 Face ID")
            } else {
                fail("设备不支持生物识别")
            }
        } else {
            fail("设备不支持生物识别或未启用 Touch ID")
        }
    }
}
