//
//  CameraUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2024/11/25.
//

#if !os(watchOS)
import Foundation

/// 相机权限的兼容封装。
///
/// 新代码建议直接用 `PermissionUtil().request(.camera:)`：能拿到 `PermissionStatus`，
/// 区分得出「用户拒绝」「系统限制」「设备没有相机」，而不是只拿到一句字符串。
public class CameraUtil {
    public init() {}

    public func checkCameraPermissions(success: @escaping () -> Void, fail: @escaping (String) -> Void) {
        PermissionUtil().request(.camera) { status in
            switch status {
            case .authorized, .limited:
                // 相机没有「部分授权」，limited 只是兜底
                success()
            case .restricted:
                fail("系统限制")
            case .denied:
                fail("用户拒绝授权")
            case .unavailable:
                fail("当前设备不支持相机")
            case .notDetermined:
                fail("未能获取相机权限状态")
            case .unknown:
                fail("未知的相机权限状态")
            }
        }
    }
}
#endif
