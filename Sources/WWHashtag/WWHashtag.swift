//
//  WWHashtag.swift
//  WWHashtag
//
//  Created by William.Weng on 2026/11/23.
//

import UIKit

/// 提供 Hashtag 文字解析功能
public enum WWHashtag {}

// MARK: - Public Methods
public extension WWHashtag {
    
    /// 擷取文字中的所有 Hashtag
    ///
    /// - Parameter text: 要解析的原始文字
    /// - Returns: 依出現順序排列的解析結果，保留重複標籤與原始大小寫
    ///
    /// ```swift
    /// let matches = WWHashtag.matches(in: "使用 #SwiftUI 和 #中文標籤")
    /// print(matches.map(\.name))  // ["SwiftUI", "中文標籤"]
    /// ```
    static func matches(in text: String) -> [Match] {
        
        let searchRange = NSRange(text.startIndex..<text.endIndex, in: text)

        return regex.matches(in: text,range: searchRange).compactMap { result -> Match? in
            
            guard let textRange = Range(result.range, in: text),
                  let nameRange = Range(result.range(at: 1), in: text)
            else {
                return nil
            }

            return .init(name: String(text[nameRange]), text: String(text[textRange]), range: result.range)
        }
    }
    
    /// 解析文字視圖中的 Hashtag，並將指定標籤轉換成可點擊的連結
    ///
    /// 沿用文字視圖的字型、文字顏色與對齊方式，但不保留原本逐字設定的富文字樣式
    ///
    ///
    /// - Parameters:
    ///   - textView: 要設定的文字視圖，直接使用其目前的文字內容
    ///   - linkFor: 根據解析結果提供連結；回傳 nil 時，該標籤維持一般文字
    @MainActor
    static func configureText(in textView: UITextView, linkFor: (Match) -> URL?) {
        
        guard let text = textView.text, !text.isEmpty else { return }
        
        let font = textView.font ?? UIFont.preferredFont(forTextStyle: .body)
        let textColor = textView.textColor ?? UIColor.label
        let paragraphStyle = NSMutableParagraphStyle()
        
        paragraphStyle.alignment = textView.textAlignment
        
        let attributes: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: textColor, .paragraphStyle: paragraphStyle]
        let attributedText = NSMutableAttributedString(string: text, attributes: attributes)
        
        for match in matches(in: text) {
            guard let url = linkFor(match) else { continue }
            attributedText.addAttribute(.link, value: url, range: match.range)
        }
        
        textView.attributedText = attributedText
    }
}

// MARK: - Private Properties
private extension WWHashtag {
    
    /// Hashtag 辨識規則：
    /// - 前方不可為 Unicode 字母、組合標記、數字、底線或「#」
    /// - 以半形「#」開頭
    /// - 第一個字元允許 Unicode 字母、數字或底線
    /// - 後續字元另外允許 Unicode 組合標記
    static let regex: NSRegularExpression = {
        
        let pattern = #"(?<![\p{L}\p{M}\p{N}_#])#([\p{L}\p{N}_][\p{L}\p{M}\p{N}_]*)"#

        do {
            return try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("Invalid internal hashtag pattern: \(error)")
        }
    }()
}
