//
//  NotificationUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/3/16.
//

import UserNotifications

public class NotificationUtil {
    private let center = UNUserNotificationCenter.current()
    public init() {}

    public func checkNotificationPermission(_ result: @escaping (Bool) -> Void) {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                result(settings.authorizationStatus == .authorized)
            }
        }
    }

    public func requestNotificationPermission(_ result: @escaping (Bool) -> Void) {
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            result(granted)
        }
    }

    public func sendTextNotification(title: String, body: String, timeInterval: Double = 60, success: @escaping () -> Void, fail: @escaping (String) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        // 设置触发时间（timeInterval是几秒后）
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)

        // 创建通知请求
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        // 添加通知到通知中心
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送通知失败: \(error.localizedDescription)")
                fail(error.localizedDescription)
            } else {
                print("✅ 通知已成功发送！")
                success()
            }
        }
    }

    public func sendImageNotification(title: String, body: String, imageURL: URL, timeInterval: Double = 60, success: @escaping () -> Void, fail: @escaping (String) -> Void) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

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
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ 发送通知失败: \(error.localizedDescription)")
                fail(error.localizedDescription)
            } else {
                print("✅ 通知已成功发送！")
                success()
            }
        }
    }
}
