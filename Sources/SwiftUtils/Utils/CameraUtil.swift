//
//  CameraUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2024/11/25.
//

#if !os(watchOS)
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
                // 用户拒绝授权
                fail("用户拒绝授权")
            case .restricted:
                // 系统限制
                fail("系统限制")
            @unknown default:
                // 未知状态按失败处理，避免在库代码中 fatalError 崩溃
                fail("未知的相机权限状态")
        }
    }
}
#endif
