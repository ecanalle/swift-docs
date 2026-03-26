# Localization and Internationalization

## Overview

Localization adapts your app for different languages and regions. It includes string translations, date/number formatting, and region-specific resources.

## Main Topics

- [String Localization](#string-localization)
- [Plural and Gender Forms](#plural-and-gender-forms)
- [Date and Number Formatting](#date-and-number-formatting)
- [Asset Localization](#asset-localization)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Internationalization](https://developer.apple.com/documentation/xcode/localization)

---

## String Localization

### Basic String Localization

```swift
import Foundation

class LocalizationManager {
    static let shared = LocalizationManager()
    
    // SwiftUI
    func localized(_ key: String) -> String {
        return NSLocalizedString(
            key,
            tableName: nil,
            bundle: Bundle.main,
            value: key,
            comment: ""
        )
    }
    
    // Get current language
    var currentLanguage: String {
        return Locale.current.languageCode ?? "en"
    }
    
    // Get current region
    var currentRegion: String? {
        return Locale.current.regionCode
    }
}

// In code
Text(LocalizationManager.shared.localized("greeting"))
// Localizable.strings: "greeting" = "Hello";

// In Localizable.strings (English)
"greeting" = "Hello";
"goodbye" = "Goodbye";
"welcome" = "Welcome to my app";

// In Localizable.strings (Portuguese - pt)
"greeting" = "Olá";
"goodbye" = "Adeus";
"welcome" = "Bem-vindo ao meu app";
```

### Using LocalizedStringResource (iOS 16+)

```swift
import SwiftUI

struct LocalizedContent: View {
    var greeting = LocalizedStringResource("greeting")
    
    var body: some View {
        Text(greeting)
    }
}

// Automatically uses system language
```

---

## Plural and Gender Forms

### Plural Localization

```swift
import Foundation

class PluralLocalizer {
    static func localizedCount(_ count: Int, singular: String, plural: String) -> String {
        let format = NSLocalizedString(
            "%d \(singular)",
            tableName: nil,
            bundle: Bundle.main,
            value: "%d \(singular)",
            comment: ""
        )
        
        return String.localizedStringWithFormat(format, count)
    }
    
    // Example
    func itemCount(_ count: Int) -> String {
        if count == 1 {
            return NSLocalizedString(
                "1 item",
                comment: "Single item"
            )
        } else {
            return String.localizedStringWithFormat(
                NSLocalizedString(
                    "%d items",
                    comment: "Multiple items"
                ),
                count
            )
        }
    }
}

// Usage
print(PluralLocalizer.itemCount(1))  // "1 item"
print(PluralLocalizer.itemCount(5))  // "5 items"
```

### Complex Plural Rules

```swift
import Foundation

class ComplexLocalization {
    static func localizeWithPlural(_ count: Int, key: String) -> String {
        let format = NSLocalizedString(
            key,
            tableName: "Plurals",
            bundle: Bundle.main,
            value: key,
            comment: ""
        )
        
        return String.localizedStringWithFormat(format, count)
    }
}

// In Localizable.stringsdict
/*
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>itemCount</key>
    <dict>
        <key>NSStringLocalizedFormatKey</key>
        <string>%#@count@</string>
        <key>count</key>
        <dict>
            <key>NSStringFormatSpecTypeKey</key>
            <string>NSStringPluralRuleType</string>
            <key>NSStringFormatValueTypeKey</key>
            <string>d</string>
            <key>one</key>
            <string>One item</string>
            <key>other</key>
            <string>%d items</string>
        </dict>
    </dict>
</dict>
</plist>
*/
```

---

## Date and Number Formatting

### Locale-Aware Formatting

```swift
import Foundation

class LocaleFormattingManager {
    static let shared = LocaleFormattingManager()
    
    // Number formatting
    func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        
        return formatter.string(from: NSNumber(value: number)) ?? ""
    }
    
    // Currency
    func formatCurrency(_ amount: Double, currencyCode: String = "USD") -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.locale = Locale.current
        
        return formatter.string(from: NSNumber(value: amount)) ?? ""
    }
    
    // Date formatting
    func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale.current
        
        return formatter.string(from: date)
    }
    
    // Time formatting
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        
        return formatter.string(from: date)
    }
    
    // RelativeDateTimeFormatter
    func formatRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale.current
        
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// Usage
let manager = LocaleFormattingManager.shared
print(manager.formatNumber(1234.56))  // 1,234.56 or 1.234,56 depending on locale
print(manager.formatCurrency(99.99))  // $99.99 or €99,99
print(manager.formatDate(Date()))     // Jan 15, 2024 or 15/01/2024
```

---

## Asset Localization

### Localizing Images and Assets

```swift
import UIKit

// In Assets.xcassets:
// Create Image Set
// Add three variants: Universal, Portuguese (pt), Spanish (es)

class LocalizedAssets {
    static let shared = LocalizedAssets()
    
    func getLocalizedImage(named name: String) -> UIImage? {
        // Automatically uses localized variant
        return UIImage(named: name)
    }
    
    // Manual localization if needed
    func getImageForCurrentLocale(_ baseImage: String) -> UIImage? {
        let locale = Locale.current
        let language = locale.languageCode ?? "en"
        
        let localizedName = "\(baseImage)_\(language)"
        
        if let image = UIImage(named: localizedName) {
            return image
        }
        
        return UIImage(named: baseImage)
    }
}

// Usage
let localizedImage = LocalizedAssets.shared.getLocalizedImage(named: "greeting")
```

---

## 🎯 Best Practices

### 1. Always Use NSLocalizedString
```swift
// ✅ Enables extraction for translation
Text(NSLocalizedString("greeting", comment: "User greeting"))

// ❌ Hard-coded text
Text("Hello")
```

### 2. Use Locale-Aware Formatters
```swift
// ✅ Adapts to user's locale
let formatter = DateFormatter()
formatter.locale = Locale.current

// ❌ Fixed format
let dateString = "2024-01-15"
```

### 3. Plan for String Length
```swift
// ✅ German and Hebrew need more space
VStack {
    Text("This is a string")
}
.frame(maxWidth: .infinity)

// ❌ Fixed width breaks translations
VStack {
    Text("This is a string")
}
.frame(width: 200)
```

---

## ❌ Common Mistakes

### Mistake 1: No i18n Planning

**WRONG:**
```swift
// ❌ Hard-coded after development
Text("Hello World")
```

**CORRECT:**
```swift
// ✅ Plan localization from start
Text(NSLocalizedString("hello_world", comment: "Main greeting"))
```

---

### Mistake 2: Ignoring Text Length

**WRONG:**
```swift
// ❌ German words are longer
Text("Settings")
    .frame(width: 80)  // Too narrow for German
```

**CORRECT:**
```swift
// ✅ Flexible layout
Text("Settings")
    .frame(maxWidth: .infinity)
```

---

## Related Topics

- [UserDefaults - Preferences](userdefaults.md)
- [Accessibility](../10-accessibility/accessibility.md)
- [Date and Time Handling](.)

---

**Reach global audiences with localization!**
