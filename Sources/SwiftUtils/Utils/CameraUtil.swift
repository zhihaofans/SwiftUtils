//
//  CameraUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2024/11/25.
//

import AVFoundation
import Foundation

public class CameraUtil {
    public init() {}

    public func checkCameraPermissions(success: @escaping ()->Void, fail: @escaping (String)->Void) {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized:
                success()
            // 已经授权
            case .notDetermined:
                AVCaptureDevice.requestAccess(for: .video) { granted in
                    if !granted {
                        // 用户拒绝授权
                        fail("用户拒绝授权")
                    } else {
                        success()
                    }
                }
            case .denied:
                return // 用户拒绝授权
                    fail("用户拒绝授权")
            case .restricted:
                fail("系统限制")
                return // 系统限制
            @unknown default:
                fatalError()
        }
    }
}
