//
//  ViewController.swift
//  Example
//
//  Created by William.Weng on 2026/11/23.
//

import UIKit
import WWHashtag

/// 示範使用 WWHashtag 解析文字，並透過可點擊的顏色標籤切換背景色
final class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!    // 顯示原始文字與可點擊的顏色標籤，內容與版面由 IB 設定
    @IBOutlet weak var statusLabel: UILabel!    // 顯示目前選取的顏色標籤
    
    private let hashTagScheme = "hashtag-color" // 識別顏色標籤連結的自訂 URL Scheme
    private let hashHost = "select"             // 識別顏色選取操作的 URL Host
    private let queryKey = "name"               // URL 查詢參數中，用來傳遞顏色名稱的鍵
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureText()
    }
}

// MARK: - UITextViewDelegate
extension ViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        return changeColorAction(with: textView, primaryActionFor: textItem, defaultAction: defaultAction)
    }
}

// MARK: - Hashtag Rendering
private extension ViewController {
    
    /// 設定文字視圖的互動代理、文字內距與連結樣式
    func configureUI() {
        
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.linkTextAttributes = [.foregroundColor: UIColor.systemBlue, .underlineStyle: NSUnderlineStyle.single.rawValue]
        
        statusLabel.clipsToBounds = true
    }
    
    /// 解析 IB 中設定的文字，並將支援的顏色標籤轉換成可點擊的連結
    func configureText() {
        
        WWHashtag.configureText(in: textView) { match in
            guard color(for: match.name) != nil else { return nil }
            return makeColorURL(name: match.name)
        }
    }
}

// MARK: - Link Handling
private extension ViewController {
    
    /// 將顏色名稱包裝成自訂連結，供文字的 link 屬性使用
    ///
    /// 例如：`hashtag-color://select?name=green`
    ///
    /// - Parameter name: 不包含「#」的顏色名稱
    /// - Returns: 組合完成的 URL；無法建立時回傳 nil
    func makeColorURL(name: String) -> URL? {
        
        var components = URLComponents()
        
        components.scheme = hashTagScheme
        components.host = hashHost
        components.queryItems = [URLQueryItem(name: queryKey, value: name)]
        
        return components.url
    }
    
    /// 從符合自訂格式的連結中，取出顏色名稱
    ///
    /// 此方法只負責驗證連結格式與讀取參數，不判斷名稱是否為支援的顏色
    ///
    /// - Parameter url: 要解析的連結
    /// - Returns: 顏色名稱；格式不符或缺少參數時回傳 nil
    func colorName(from url: URL) -> String? {
        
        guard url.scheme == hashTagScheme,
              url.host == hashHost,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return nil
        }
        
        return components.queryItems?.first(where: { $0.name == queryKey })?.value
    }
    
    /// 自訂文字項目的主要互動行為，將顏色標籤連結轉換成切換背景色的動作
    ///
    /// - Parameters:
    ///   - textView: 觸發互動的文字視圖
    ///   - textItem: 使用者操作的文字項目
    ///   - defaultAction: 系統原本提供的動作
    /// - Returns: 顏色標籤使用自訂動作；其他項目維持系統預設動作
    func changeColorAction(with textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction {
        
        guard case let .link(url) = textItem.content,
              let name = colorName(from: url),
              color(for: name) != nil
        else {
            return defaultAction
        }
        
        return UIAction { [weak self] _ in self?.applyBackgroundColor(named: name) }
    }
}

// MARK: - Color Mapping
private extension ViewController {
    
    /// 以動畫切換畫面背景色，並更新目前選取的標籤名稱
    ///
    /// - Parameter name: 不包含「#」的顏色名稱
    func applyBackgroundColor(named name: String) {
        
        guard let color = color(for: name) else { return }
        
        UIView.animate(withDuration: 0.25) {
            self.view.backgroundColor = color
        }
        
        statusLabel.text = "目前背景：#\(name)"
    }
    
    /// 將中英文顏色名稱轉換成 UIColor
    ///
    /// - Parameter name: 不包含「#」的顏色名稱，英文不區分大小寫
    /// - Returns: 對應的顏色；不支援的名稱回傳 nil
    func color(for name: String) -> UIColor? {
        
        switch name.lowercased() {
        case "黃色", "yellow": return .systemYellow
        case "綠色", "green": return .systemGreen
        case "紅色", "red": return .systemRed
        case "藍色", "blue": return .systemBlue
        case "白色", "white": return .white
        case "黑色", "black": return .black
        default: return nil
        }
    }
}
