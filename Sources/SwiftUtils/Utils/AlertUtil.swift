//
//  AlertUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/1/28.
//

import Foundation
import SwiftUI

public class AlertUtil {
    public init() {}
    public struct InputAlertView: View {
        let title: String
        let placeholder: String
        @Binding var inputText: String
        @Binding var isPresented: Bool
        var callback: (String) -> Void

        public init(title: String,
                    placeholder: String,
                    inputText: Binding<String>,
                    isPresented: Binding<Bool>,
                    callback: @escaping (String) -> Void)
        {
            self.title = title
            self.placeholder = placeholder
            self._inputText = inputText
            self._isPresented = isPresented
            self.callback = callback
        }

        // 为 macOS / iOS 提供一致的系统样式输入
        public var body: some View {
            Color.clear
                .alert(title, isPresented: $isPresented) {
                    TextField(placeholder, text: $inputText)
                    Button("取消", role: .cancel) { /* 自动关闭由系统处理 */ }
                    Button("确定") {
                        callback(inputText) // 点击确定回调当前输入值
                    }
                } message: {
                    Text("请输入内容")
                }
        }
    }

    public struct PasswordInputAlertView: View {
        let title: String
        let placeholder: String
        @Binding var password: String
        @Binding var isPresented: Bool
        var callback: (String) -> Void

        public init(title: String,
                    placeholder: String,
                    password: Binding<String>,
                    isPresented: Binding<Bool>,
                    callback: @escaping (String) -> Void)
        {
            self.title = title
            self.placeholder = placeholder
            self._password = password
            self._isPresented = isPresented
            self.callback = callback
        }

        public var body: some View {
            Color.clear
                .alert(title, isPresented: $isPresented) {
                    SecureField(placeholder, text: $password)
                    Button("取消", role: .cancel) {}
                    Button("确定") {
                        callback(password)
                    }
                } message: {
                    Text("请输入密码")
                }
        }
    }
//     示例用法：
//    AlertUtil.SecureInputAlertView(
//        title: "验证",
//        placeholder: "请输入密码",
//        password: $password,
//        isPresented: $showPasswordAlert
//    ) { pwd in
//        print("输入的密码是：\(pwd)")
//    }
}
