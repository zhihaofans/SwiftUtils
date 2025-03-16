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
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
          result(granted)
      }
  }
}

