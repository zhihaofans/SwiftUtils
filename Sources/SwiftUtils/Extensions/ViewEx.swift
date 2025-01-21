//
//  ViewEx.swift
//  SwiftUtils
//
//  Created by zzh on 2024/11/10.
//

import Foundation
import SafariServices
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

    func showShareTextView(_ text: String, isPresented: Binding<Bool>) -> some View {
        return sheet(isPresented: isPresented) {
            ShareActivityView(activityItems: [text])
        }
    }

    func showSafariWebPreviewView(_ safariUrlString: String, isPresented: Binding<Bool>) -> some View {
        return sheet(isPresented: isPresented) {
            if let url = URL(string: safariUrlString) {
                SafariWebPreviewView(url: url)
            } else {
                Text("Invalid URL")
            }
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

struct SafariWebPreviewView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
