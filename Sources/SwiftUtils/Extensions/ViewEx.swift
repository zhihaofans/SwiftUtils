//
//  ViewEx.swift
//  SwiftUtils
//
//  Created by zzh on 2024/11/10.
//

import Foundation
import SwiftUI

public extension View {
    func onClick(callback: @escaping () -> Void) -> some View {
        return contentShape(Rectangle()) // 加这行才实现可点击
            .onTapGesture {
                callback()
            }
    }

    func setNavigationTitle(_ title: String) -> some View {
        return self
        #if os(iOS)
            .navigationBarTitle(title, displayMode: .inline)
        #else
            .navigationTitle(title)
        #endif
    }
    func showShareTextView(_ text: String) -> some View {
        return self.sheet(isPresented: $isShareSheetPresented) {
            ShareActivityView(activityItems: [item.text])
        }
    }
}
struct ShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: Context) -> UIActivityViewController {
        return UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // No need to update the controller
    }
}