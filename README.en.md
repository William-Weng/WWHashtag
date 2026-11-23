[English](./README.en.md) | [正體中文](./README.md)

# [WWHashtag](https://swiftpackageindex.com/William-Weng)

[![Swift-5.10](https://img.shields.io/badge/Swift-5.10-orange.svg)](https://developer.apple.com/swift/)
[![iOS-17.0](https://img.shields.io/badge/iOS-17.0-pink.svg?style=flat)](https://developer.apple.com/swift/)
![TAG](https://img.shields.io/github/v/tag/William-Weng/WWHashtag)
![SPM](https://img.shields.io/badge/SPM-supported-brightgreen.svg)
[![LICENSE](https://img.shields.io/badge/LICENSE-MIT-yellow.svg?style=flat)](https://developer.apple.com/swift/)

A lightweight Swift hashtag parser that supports Chinese characters, English letters, numbers, and underscores. Includes UIKit integration for quickly turning hashtags into tappable links.

The core parser does not depend on any UI framework. Hashtag styling, tap handling, and application-specific behavior are left to the caller.

https://github.com/user-attachments/assets/85adf07c-f5a3-4e73-91e3-c0551f921a5f
## Features

- Supports Chinese, English, and mixed-language hashtags.
- Supports numbers, underscores, and Unicode combining marks.
- Provides the name, full text, and original range of each hashtag.
- Preserves occurrence order, duplicate hashtags, and original casing.
- Includes UIKit integration for easily adding hashtag links to a `UITextView`.
- Uses a closure to determine which hashtags become links and their destination URLs.
- Keeps the core parser independent of specific use cases such as styling, searching, or navigation.

## Installation

Use Swift Package Manager:

1. In Xcode, choose **File → Add Package Dependencies…**.
2. Enter this project's Git repository URL.
3. Select the desired version and add `WWHashtag` to your app target.

Import the package where needed:

```swift
import WWHashtag
```

## API

### WWHashtag.matches(in:)

Parses all hashtags in the given text.

```swift
public static func matches(in text: String) -> [WWHashtag.Match]
```

| Parameter | Description |
|---|---|
| `text` | The original text to parse. |

Results are returned in their original order, preserving duplicate hashtags and casing.

### WWHashtag.Match

Represents a single hashtag in the original text.

| Property | Type | Description |
|---|---|---|
| `name` | `String` | The hashtag name without the leading `#`. |
| `text` | `String` | The full hashtag text, including the leading `#`. |
| `range` | `NSRange` | The UTF-16 range of the full hashtag in the original text. |

### WWHashtag.configureText(in:linkFor:)

Adds links to selected hashtags in a `UITextView`. Available only in environments where UIKit can be imported.

```swift
@MainActor
public static func configureText(
    in textView: UITextView,
    linkFor: (WWHashtag.Match) -> URL?
)
```

| Parameter | Description |
|---|---|
| `textView` | The text view to configure. |
| `linkFor` | Provides a URL for each hashtag. Return `nil` to leave the hashtag unlinked. |

## Basic Usage

### Parse Hashtags

```swift
let text = "Use #SwiftUI to create #中文標籤, with support for #swift_ui"

let matches = WWHashtag.matches(in: text)

for match in matches {
    print("Hashtag name: \(match.name)")
    print("Full text: \(match.text)")
    print("Original range: \(match.range)")
}
```

Parsed results:

| name | text |
|---|---|
| SwiftUI | #SwiftUI |
| 中文標籤 | #中文標籤 |
| swift_ui | #swift_ui |

### Extract Hashtag Names Only

```swift
let text = "#SwiftUI #中文標籤 #SwiftUI"

let names = WWHashtag.matches(in: text).map(\.name)

print(names)
// ["SwiftUI", "中文標籤", "SwiftUI"]
```

The package does not automatically remove duplicates or change casing. It preserves the original text information.

### Use the Original Range

`Match.range` is the `NSRange` of the full hashtag in the original text, including the leading `#`.

```swift
let text = "Learning #SwiftUI today"

for match in WWHashtag.matches(in: text) {
    guard let range = Range(match.range, in: text) else { continue }
    print(text[range])
    // #SwiftUI
}
```

> The range is measured in UTF-16 code units, not Swift `Character` values. Convert it using `Range(_:in:)` before accessing the Swift string. Parse the text again whenever the original text changes.

## Quick UIKit Integration

Use `WWHashtag.configureText(in:linkFor:)` to turn selected hashtags in a `UITextView` into tappable links.

```swift
WWHashtag.configureText(in: textView) { match in

    var components = URLComponents()
    components.scheme = "hashtag"
    components.host = "search"
    components.queryItems = [URLQueryItem(name: "name", value: match.name)]

    return components.url
}
```

The closure's return value determines whether a hashtag becomes tappable:

| Return Value | Result |
|---|---|
| `URL` | Turns the hashtag into a link. |
| `nil` | Leaves the hashtag as plain text. |

This method:

- Reads the current text from the `UITextView`.
- Uses the text view's font, text color, and text alignment.
- Parses hashtags and adds links based on the closure's return values.
- Updates `attributedText`.

This method does not:

- Assign a `UITextViewDelegate`.
- Configure link colors, underlines, or text container insets.
- Automatically handle link taps.
- Preserve existing mixed rich-text formatting applied to individual text ranges.

> The UIKit integration method updates the UI and must be called on the Main Actor.

## UIKit Example: Change the Background Color by Tapping Hashtags

The following example uses a Storyboard-based interface. Tapping hashtags such as `#黃色` or `#green` changes the screen's background color.

This example uses text interaction APIs available in iOS 17 and later.

### Storyboard Setup

1. Add a `UITextView` and a `UILabel`.
2. Configure Auto Layout constraints.
3. Connect the components to the `textView` and `statusLabel` outlets.
4. Enter the following text in the text view:

```text
Tap a hashtag to change the background:

#黃色  #green  #紅色
#blue  #白色  #黑色

Both Chinese and English are supported:
#yellow  #綠色  #red

Other hashtags do not change the background:
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

        statusLabel.text = "Current background: #\(name)"
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
