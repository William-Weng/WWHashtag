[English](./README.en.md) | [正體中文](./README.md)

# [WWHashtag](https://swiftpackageindex.com/William-Weng)

[![Swift-5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://developer.apple.com/swift/)
[![iOS-17.0](https://img.shields.io/badge/iOS-17.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWHashtag)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

輕量的 Swift Hashtag 解析工具，支援中文、英文、數字與底線，並提供 UIKit 整合方法，快速將文字中的標籤轉換成可點擊的連結。

核心解析不依賴 UI 框架；標籤樣式、點擊行為與業務邏輯則由使用端決定。

https://github.com/user-attachments/assets/278d91a0-0b0f-4628-83f0-29a30f2d87cc

## 功能特色

- 支援中文、英文與中英文混合標籤。
- 支援數字、底線及 Unicode 組合標記。
- 取得標籤名稱、完整文字與原文範圍。
- 保留標籤出現順序、重複內容與原始大小寫。
- 提供 UIKit 整合方法，快速設定 `UITextView` 的標籤連結。
- 使用閉包決定哪些標籤可點擊，以及對應的 URL。
- 核心解析不綁定顏色、搜尋或頁面導覽等特定用途。

## 安裝方式

使用 Swift Package Manager：

1. 在 Xcode 選擇 **File → Add Package Dependencies…**。
2. 輸入本專案的 Git Repository URL。
3. 選擇所需版本，並將 `WWHashtag` 加入 App Target。

在需要使用的檔案中匯入：

```swift
import WWHashtag
```

## API

### WWHashtag.matches(in:)

解析文字中的所有標籤。

```swift
public static func matches(in text: String) -> [WWHashtag.Match]
```

| 參數 | 說明 |
|---|---|
| `text` | 要解析的原始文字 |

回傳結果依照原文出現順序排列，保留重複標籤與大小寫。

### WWHashtag.Match

表示原文中的一筆標籤。

| 屬性 | 型別 | 說明 |
|---|---|---|
| `name` | `String` | 不包含 `#` 的標籤名稱 |
| `text` | `String` | 包含 `#` 的完整標籤文字 |
| `range` | `NSRange` | 完整標籤在原文中的 UTF-16 範圍 |

### WWHashtag.configureText(in:linkFor:)

為 `UITextView` 中的指定標籤加入連結，僅在可匯入 UIKit 的環境提供。

```swift
@MainActor
public static func configureText(
    in textView: UITextView,
    linkFor: (WWHashtag.Match) -> URL?
)
```

| 參數 | 說明 |
|---|---|
| `textView` | 要處理的文字視圖 |
| `linkFor` | 提供各標籤的連結；回傳 `nil` 表示不設定連結 |

## 基本使用

### 解析 Hashtag

```swift
let text = "使用 #SwiftUI 製作 #中文標籤，也支援 #swift_ui"

let matches = WWHashtag.matches(in: text)

for match in matches {
    print("標籤名稱：\(match.name)")
    print("完整文字：\(match.text)")
    print("原文範圍：\(match.range)")
}
```

解析結果：

| name | text |
|---|---|
| SwiftUI | #SwiftUI |
| 中文標籤 | #中文標籤 |
| swift_ui | #swift_ui |

### 只取得標籤名稱

```swift
let text = "#SwiftUI #中文標籤 #SwiftUI"

let names = WWHashtag.matches(in: text).map(\.name)

print(names)
// ["SwiftUI", "中文標籤", "SwiftUI"]
```

套件不會自動去重，也不會變更大小寫，保留原始文字資訊。

### 使用原文範圍

`Match.range` 是完整標籤在原文中的 `NSRange`，包含前方的 `#`。

```swift
let text = "今天學習 #SwiftUI"

for match in WWHashtag.matches(in: text) {
    guard let range = Range(match.range, in: text) else { continue }
    print(text[range])
    // #SwiftUI
}
```

> `range` 以 UTF-16 code unit 為單位，不是 Swift 的 `Character` 數量。請使用 `Range(_:in:)` 轉換後再存取 Swift 字串。原文變更後，應重新解析。

## UIKit 快速整合

使用 `WWHashtag.configureText(in:linkFor:)`，可以直接將 `UITextView` 中的指定標籤轉換成可點擊的連結。

```swift
WWHashtag.configureText(in: textView) { match in

    var components = URLComponents()
    components.scheme = "hashtag"
    components.host = "search"
    components.queryItems = [URLQueryItem(name: "name", value: match.name)]

    return components.url
}
```

閉包的回傳值決定標籤是否可以點擊：

| 回傳值 | 結果 |
|---|---|
| `URL` | 將該標籤設為連結 |
| `nil` | 該標籤維持一般文字 |

這個方法會：

- 讀取 `UITextView` 目前的文字。
- 沿用文字視圖的字型、文字顏色與對齊方式。
- 解析標籤，並依閉包結果加入連結。
- 更新 `attributedText`。

這個方法不會：

- 設定 `UITextViewDelegate`。
- 設定連結顏色、底線或文字內距。
- 自動處理連結點擊。
- 保留原本逐字設定的混合富文字樣式。

> UIKit 整合方法涉及 UI 更新，請在 Main Actor 上呼叫。

## UIKit 範例：點擊標籤切換背景色

以下範例使用 Storyboard 建立介面，點擊 `#黃色`、`#green` 等標籤後切換畫面背景。

此範例使用 iOS 17 以上的文字互動 API。

### Storyboard 設定

1. 加入 `UITextView` 和 `UILabel`。
2. 設定 Auto Layout。
3. 將元件連接到 `textView` 與 `statusLabel`。
4. 在 Text View 中填入以下文字：

```text
點擊標籤切換背景：

#黃色  #green  #紅色
#blue  #白色  #黑色

中英文都可以：
#yellow  #綠色  #red

一般標籤不會改變背景：
#中文標籤  #SwiftUI
```

### ViewController.swift

```swift
import UIKit
import WWHashtag

final class ViewController: UIViewController {
    
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var statusLabel: UILabel! 
    
    private let hashTagScheme = "hashtag-color"
    private let hashHost = "select"
    private let queryKey = "name"
        
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        configureText()
    }
}

extension ViewController: UITextViewDelegate {
    
    func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
        return changeColorAction(with: textView, primaryActionFor: textItem, defaultAction: defaultAction)
    }
}

private extension ViewController {
    
    func configureUI() {
        
        textView.delegate = self
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        textView.linkTextAttributes = [.foregroundColor: UIColor.systemBlue, .underlineStyle: NSUnderlineStyle.single.rawValue]
        
        statusLabel.clipsToBounds = true
    }
    
    func configureText() {
        
        WWHashtag.configureText(in: textView) { match in
            guard color(for: match.name) != nil else { return nil }
            return makeColorURL(name: match.name)
        }
    }
}

private extension ViewController {
    
    func makeColorURL(name: String) -> URL? {
        
        var components = URLComponents()
        
        components.scheme = hashTagScheme
        components.host = hashHost
        components.queryItems = [URLQueryItem(name: queryKey, value: name)]
        
        return components.url
    }
    
    func colorName(from url: URL) -> String? {
        
        guard url.scheme == hashTagScheme,
              url.host == hashHost,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        else {
            return nil
        }
        
        return components.queryItems?.first(where: { $0.name == queryKey })?.value
    }
    
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

private extension ViewController {
    
   func applyBackgroundColor(named name: String) {
        
        guard let color = color(for: name) else { return }
        
        UIView.animate(withDuration: 0.25) {
            self.view.backgroundColor = color
        }
        
        statusLabel.text = "目前背景：#\(name)"
    }
    
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
```
