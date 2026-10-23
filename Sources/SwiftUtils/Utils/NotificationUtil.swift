//
//  NotificationUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/3/16.
//

import UserNotifications

public class NotificationUtil {
    /// 权限查询/申请统一走 PermissionUtil：
    /// 以前 `private let center = UNUserNotificationCenter.current()` 会在 init 时就取值，
    /// 无 App bundle 的进程（单测、扩展）直接抛异常；而且两条权限回调的线程约定还不一致。
    private let permissions = PermissionUtil()

    public init() {}

    /// 是否已获得通知权限（`provisional` 临时授权也算已获得）
    public func checkNotificationPermission(_ result: @escaping (Bool) -> Void) {
        permissions.check(.notifications) { status in
            result(status.isGranted)
        }
    }

    /// 申请通知权限；只在还没问过时才会弹框，回调在主队列
    public func requestNotificationPermission(_ result: @escaping (Bool) -> Void) {
        permissions.request(.notifications) { status in
            result(status.isGranted)
        }
    }

    public func sendTextNotification(title: String, body: String, timeInterval: Double = 60, success: @escaping (String) -> Void, fail: @escaping (String) -> Void) {
        // timeInterval <= 0 会让 UNTimeIntervalNotificationTrigger 直接抛 ObjC 异常
        guard timeInterval > 0 else {
            SU.log.error("❌ 发送通知失败: timeInterval 必须大于 0（当前 \(timeInterval)）")
            fail("timeInterval 必须大于 0")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let identifier = UUID().uuidString
        // 设置触发时间（timeInterval是几秒后）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        // 创建通知请求
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // 添加通知到通知中心
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                SU.log.error("❌ 发送通知失败: \(error.localizedDescription)")
                fail(error.localizedDescription)
            } else {
                SU.log.info("✅ 通知已成功发送！")
                success(identifier)
            }
        }
    }

    public func sendImageNotification(title: String, body: String, imageURL: URL, timeInterval: Double = 60, success: @escaping (String) -> Void, fail: @escaping (String) -> Void) {
        // timeInterval <= 0 会让 UNTimeIntervalNotificationTrigger 直接抛 ObjC 异常
        guard timeInterval > 0 else {
            SU.log.error("❌ 发送通知失败: timeInterval 必须大于 0（当前 \(timeInterval)）")
            fail("timeInterval 必须大于 0")
            return
        }
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let identifier = UUID().uuidString

        // 添加图片附件
//        if let imageURL = Bundle.main.url(forResource: "example", withExtension: "jpg") {
//            let attachment = try? UNNotificationAttachment(identifier: "image", url: imageURL, options: nil)
//            if let attachment = attachment {
//                content.attachments = [attachment]
//            }
//        }
//
        let attachment = try? UNNotificationAttachment(identifier: "image", url: imageURL, options: nil)
        if let attachment = attachment {
            content.attachments = [attachment]
        }

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                SU.log.error("❌ 发送通知失败: \(error.localizedDescription)")
                fail(error.localizedDescription)
            } else {
                SU.log.info("✅ 通知已成功发送！")
                success(identifier)
            }
        }
    }

    public func removeSentNotification(identifier: String) {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [identifier])
    }

    public func removeAllSentNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    public func removeUnsentNotification(identifier: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    public func removeAllUnsentNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    public func removeAllNotifications() {
        removeAllSentNotifications()
        removeAllUnsentNotifications()
    }
}
