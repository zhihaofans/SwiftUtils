//
//  ListUI.swift
//
//
//  Created by zzh on 2024/10/25.
//

import SwiftUI

public struct ListItemLoadingView: View {
    var title: String
    @Binding var isLoading: Bool
    var onClick: () -> Void
    var loadingColor: Color? = nil
    public var body: some View {
        Button(action: {
            if !isLoading {
                isLoading = true
                onClick()
            }
        }) {
            HStack {
                Text(title)
                // Spacer() // 占据剩余空间，将 ProgressView 推到右侧
                if isLoading {
                    ProgressView()
                        .tint(loadingColor)
                }
            }
        }
    }
}
