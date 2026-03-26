# Input Validation - Form and Data Validation

## Overview

Input validation ensures data integrity by checking user input against predefined rules. Common validations include emails, passwords, and phone numbers.

## Main Topics

- [String Validation](#string-validation)
- [Email and URL Validation](#email-and-url-validation)
- [Password Validation](#password-validation)
- [SwiftUI Form Validation](#swiftui-form-validation)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

---

## String Validation

### Basic String Validation

```swift
import Foundation

class StringValidator {
    static func isNotEmpty(_ string: String) -> Bool {
        return !string.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    static func hasMinimumLength(_ string: String, length: Int) -> Bool {
        return string.count >= length
    }
    
    static func hasMaximumLength(_ string: String, length: Int) -> Bool {
        return string.count <= length
    }
    
    static func containsNumbers(_ string: String) -> Bool {
        return string.range(of: "\\d", options: .regularExpression) != nil
    }
    
    static func containsSpecialCharacters(_ string: String) -> Bool {
        let regex = "[@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]"
        return string.range(of: regex, options: .regularExpression) != nil
    }
    
    static func isAlphanumeric(_ string: String) -> Bool {
        return string.range(of: "^[a-zA-Z0-9]*$", options: .regularExpression) != nil
    }
    
    static func isNumeric(_ string: String) -> Bool {
        return !string.isEmpty && string.allSatisfy({ $0.isNumber })
    }
}

// Usage
StringValidator.isNotEmpty("Hello")  // true
StringValidator.hasMinimumLength("password", length: 8)  // true
StringValidator.containsNumbers("pass123")  // true
```

---

## Email and URL Validation

### Email Validation

```swift
import Foundation

class EmailValidator {
    static func isValidEmail(_ email: String) -> Bool {
        let emailPattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
        let regex = try? NSRegularExpression(pattern: emailPattern)
        let range = NSRange(email.startIndex..<email.endIndex, in: email)
        return regex?.firstMatch(in: email, range: range) != nil
    }
    
    static func isValidEmail2(_ email: String) -> Bool {
        // Using URLComponents
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        
        return components.url != nil && isValidEmailFormat(email)
    }
    
    private static func isValidEmailFormat(_ email: String) -> Bool {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let range = NSRange(email.startIndex..<email.endIndex, in: email)
        
        let matches = detector?.numberOfMatches(in: email, range: range) ?? 0
        return matches > 0
    }
}

// Usage
EmailValidator.isValidEmail("user@example.com")  // true
EmailValidator.isValidEmail("invalid.email")      // false
```

### URL Validation

```swift
import Foundation

class URLValidator {
    static func isValidURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else {
            return false
        }
        
        return UIApplication.shared.canOpenURL(url)
    }
    
    static func isValidHttpURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else {
            return false
        }
        
        return (url.scheme == "http" || url.scheme == "https") && 
               url.host != nil
    }
    
    static func isValidFileURL(_ string: String) -> Bool {
        guard let url = URL(string: string) else {
            return false
        }
        
        return url.scheme == "file" && FileManager.default.fileExists(atPath: url.path)
    }
}
```

---

## Password Validation

### Secure Password Validation

```swift
import Foundation

class PasswordValidator {
    static func isStrongPassword(_ password: String) -> (isValid: Bool, reasons: [String]) {
        var reasons: [String] = []
        
        // Minimum length
        if password.count < 8 {
            reasons.append("Password must be at least 8 characters")
        }
        
        // Contains uppercase
        if !password.contains(where: { $0.isUppercase }) {
            reasons.append("Password must contain uppercase letters")
        }
        
        // Contains lowercase
        if !password.contains(where: { $0.isLowercase }) {
            reasons.append("Password must contain lowercase letters")
        }
        
        // Contains numbers
        if !password.contains(where: { $0.isNumber }) {
            reasons.append("Password must contain numbers")
        }
        
        // Contains special characters
        let specialPattern = "[!@#$%^&*()_+\\-=\\[\\]{};':\"\\\\|,.<>\\/?]"
        let regex = try? NSRegularExpression(pattern: specialPattern)
        let range = NSRange(password.startIndex..<password.endIndex, in: password)
        if regex?.firstMatch(in: password, range: range) == nil {
            reasons.append("Password must contain special characters")
        }
        
        return (reasons.isEmpty, reasons)
    }
    
    static func matchPasswords(_ password: String, _ confirm: String) -> Bool {
        return password == confirm
    }
}

// Usage
let (isValid, reasons) = PasswordValidator.isStrongPassword("Weak")
if !isValid {
    for reason in reasons {
        print(reason)
    }
}
```

---

## SwiftUI Form Validation

### Form Validation in SwiftUI

```swift
import SwiftUI

@MainActor
class FormViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var confirmPassword = ""
    @Published var errors: [String: String] = [:]
    
    var isFormValid: Bool {
        return errors.isEmpty && 
               !email.isEmpty && 
               !password.isEmpty && 
               !confirmPassword.isEmpty
    }
    
    func validate() {
        errors.removeAll()
        
        // Email validation
        if !EmailValidator.isValidEmail(email) {
            errors["email"] = "Invalid email format"
        }
        
        // Password validation
        let (isStrong, reasons) = PasswordValidator.isStrongPassword(password)
        if !isStrong {
            errors["password"] = reasons.first ?? "Weak password"
        }
        
        // Password match
        if password != confirmPassword {
            errors["confirmPassword"] = "Passwords do not match"
        }
    }
    
    func submit() {
        validate()
        if isFormValid {
            print("Form submitted")
        }
    }
}

struct FormView: View {
    @StateObject private var viewModel = FormViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // Email
            VStack(alignment: .leading) {
                TextField("Email", text: $viewModel.email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                
                if let error = viewModel.errors["email"] {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Password
            VStack(alignment: .leading) {
                SecureField("Password", text: $viewModel.password)
                
                if let error = viewModel.errors["password"] {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            // Confirm Password
            VStack(alignment: .leading) {
                SecureField("Confirm Password", text: $viewModel.confirmPassword)
                
                if let error = viewModel.errors["confirmPassword"] {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
            }
            
            Button("Submit") {
                viewModel.submit()
            }
            .disabled(!viewModel.isFormValid)
        }
        .padding()
    }
}
```

---

## 🎯 Best Practices

### 1. Validate on Input Change
```swift
// ✅ Real-time validation feedback
TextField("Email", text: $viewModel.email)
    .onChange(of: viewModel.email) { newValue in
        viewModel.validateEmail(newValue)
    }

// ❌ Only validate on submit
```

### 2. Use Clear Error Messages
```swift
// ✅ Specific feedback
"Password must contain at least one uppercase letter"

// ❌ Vague messages
"Invalid password"
```

### 3. Disable Submit Until Valid
```swift
// ✅ Prevent invalid submission
Button("Submit") { submit() }
    .disabled(!viewModel.isFormValid)

// ❌ Allow invalid state
Button("Submit") { submit() }
```

---

## ❌ Common Mistakes

### Mistake 1: Weak Validation

**WRONG:**
```swift
// ❌ Only checks for @
func isValidEmail(_ email: String) -> Bool {
    return email.contains("@")
}
```

**CORRECT:**
```swift
// ✅ Proper validation
func isValidEmail(_ email: String) -> Bool {
    let pattern = "^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$"
    let regex = try? NSRegularExpression(pattern: pattern)
    let range = NSRange(email.startIndex..<email.endIndex, in: email)
    return regex?.firstMatch(in: email, range: range) != nil
}
```

---

### Mistake 2: No Real-time Feedback

**WRONG:**
```swift
// ❌ Only validates on submit
TextField("Email", text: $email)
Button("Submit") {
    if !isValidEmail(email) {
        showError()
    }
}
```

**CORRECT:**
```swift
// ✅ Real-time validation
TextField("Email", text: $email)
    .onChange(of: email) { newValue in
        isEmailValid = isValidEmail(newValue)
    }
```

---

## Related Topics

- [SwiftUI Forms and Inputs](../05-features/swiftui-basics.md)
- [Error Handling](../01-fundamentals/error-handling.md)
- [String Operations](../01-fundamentals/strings.md)

---

**Validate user input thoroughly!**
