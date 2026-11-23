//
//  Match.swift
//  WWHashtag
//
//  Created by William.Weng on 2026/11/23.
//

import Foundation

// MARK: - Public Types
public extension WWHashtag {
    
    /// 原始文字中的一筆 Hashtag
    struct Match: Equatable, Sendable {

        public let name: String
        public let text: String
        public let range: NSRange
        
        /// 初始化
        /// - Parameters:
        ///   - name: 不包含「#」的標籤名稱，例如：SwiftUI
        ///   - text: 包含「#」的原始標籤文字，例如：#SwiftUI
        ///   - range: 完整標籤在原始文字中的 UTF-16 範圍，僅適用於傳入 `matches(in:)` 時的原始文字
        init(name: String, text: String, range: NSRange) {
            self.name = name
            self.text = text
            self.range = range
        }
    }
}
