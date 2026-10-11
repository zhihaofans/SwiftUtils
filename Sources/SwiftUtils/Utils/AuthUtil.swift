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

    /// watchOS 不支持生物识别策略，退化为设备所有者认证
    private var policy: LAPolicy {
        #if os(watchOS)
        return .deviceOwnerAuthentication
        #else
        return .deviceOwnerAuthenticationWithBiometrics
        #endif
    }

    func checkTouchID() -> Bool {
        #if os(watchOS)
        return false
        #else
        var error: NSError?
        return context.canEvaluatePolicy(policy, error: &error) && context.biometryType == .touchID
        #endif
    }

    func checkFaceID() -> Bool {
        #if os(watchOS)
        return false
        #else
        var error: NSError?
        return context.canEvaluatePolicy(policy, error: &error) && context.biometryType == .faceID
        #endif
    }

    func authenticate(title: String = "请使用 Face ID 或 Touch ID 验证您的身份", callback: @escaping (Bool) -> Void, fail: @escaping (String) -> Void) {
        var error: NSError?
        // 检查设备是否支持生物识别 / 设备所有者认证
        guard context.canEvaluatePolicy(policy, error: &error) else {
            #if os(watchOS)
            fail("设备不支持该认证方式")
            #else
            fail("设备不支持生物识别或未启用 Touch ID")
            #endif
            return
        }
        #if !os(watchOS)
        guard context.biometryType == .touchID || context.biometryType == .faceID else {
            fail("设备不支持生物识别")
            return
        }
        #endif
        context.evaluatePolicy(policy, localizedReason: title) { success, error in
            DispatchQueue.main.async {
                SU.log.error(error?.localizedDescription ?? "验证失败")
                callback(success)
            }
        }
    }
}
