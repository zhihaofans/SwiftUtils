//
//  AlertUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2025/1/28.
//

import Foundation

public class AlertUtil {
    public init() {}
    /// 系统样式的输入弹窗
    public struct InputAlertView: View {
        let title: String
        let placeholder: String
        @Binding var inputText: String
        @Binding var isPresented: Bool
        var callback: (String) -> Void
    
        // 为 macOS / iOS 提供一致的系统样式输入
        var body: some View {
            EmptyView()
                .alert(title, isPresented: $isPresented) {
                    TextField(placeholder, text: $inputText)
                    Button("取消", role: .cancel) { }
                    Button("确定") {
                        callback(inputText)
                    }
                } message: {
                    Text("请输入内容")
                }
        }
    }
}
