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
}
