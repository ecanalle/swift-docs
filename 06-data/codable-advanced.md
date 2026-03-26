# Codable Advanced - Complex Encoding and Decoding

## Overview

Advanced Codable techniques handle complex JSON structures, custom keys, nested types, and conditional encoding without manual implementation.

## Main Topics

- [Custom Coding Keys](#custom-coding-keys)
- [Nested Types](#nested-types)
- [Conditional Encoding](#conditional-encoding)
- [Date and Data Formats](#date-and-data-formats)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

---

## Custom Coding Keys

### CodingKeys Mapping

```swift
import Foundation

struct User: Codable {
    let id: Int
    let fullName: String
    let emailAddress: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case fullName = "full_name"  // Maps to JSON field
        case emailAddress = "email"
    }
}

// JSON: { "id": 1, "full_name": "John Doe", "email": "john@example.com" }
let json = """
{
    "id": 1,
    "full_name": "John Doe",
    "email": "john@example.com"
}
""".data(using: .utf8)!

let user = try JSONDecoder().decode(User.self, from: json)
print(user.fullName)  // "John Doe"
```

### Partial Coding Keys

```swift
import Foundation

struct Product: Codable {
    let id: Int
    let name: String
    let price: Double
    let inStock: Bool
    let created: Date
    let modified: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, name, price
        case inStock = "in_stock"
        case created = "created_at"
        case modified = "updated_at"
    }
}
```

---

## Nested Types

### Handling Nested Objects

```swift
import Foundation

struct Company: Codable {
    let id: Int
    let name: String
    let department: Department
    let employees: [Employee]
    
    struct Department: Codable {
        let id: Int
        let name: String
    }
    
    struct Employee: Codable {
        let id: Int
        let name: String
        let position: String
    }
}

// JSON structure
let json = """
{
    "id": 1,
    "name": "Tech Corp",
    "department": {
        "id": 10,
        "name": "Engineering"
    },
    "employees": [
        {
            "id": 100,
            "name": "Alice",
            "position": "Senior Engineer"
        }
    ]
}
""".data(using: .utf8)!

let company = try JSONDecoder().decode(Company.self, from: json)
```

### Array of Nested Objects

```swift
import Foundation

struct Response: Codable {
    let status: String
    let data: [Item]
    
    struct Item: Codable {
        let id: Int
        let name: String
        let metadata: [String: String]
    }
}

let json = """
{
    "status": "success",
    "data": [
        {
            "id": 1,
            "name": "Item 1",
            "metadata": {
                "color": "blue",
                "size": "large"
            }
        }
    ]
}
""".data(using: .utf8)!

let response = try JSONDecoder().decode(Response.self, from: json)
```

---

## Conditional Encoding

### Custom Encode/Decode

```swift
import Foundation

struct Task: Codable {
    let id: Int
    let title: String
    let completed: Bool
    let completedDate: Date?
    
    enum CodingKeys: String, CodingKey {
        case id, title, completed
        case completedDate = "completed_date"
    }
    
    // Custom decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        completed = try container.decode(Bool.self, forKey: .completed)
        
        // Only decode completedDate if task is completed
        if completed {
            completedDate = try container.decodeIfPresent(Date.self, forKey: .completedDate)
        } else {
            completedDate = nil
        }
    }
    
    // Custom encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encode(completed, forKey: .completed)
        
        // Only encode completedDate if present
        if completed, let date = completedDate {
            try container.encode(date, forKey: .completedDate)
        }
    }
}
```

---

## Date and Data Formats

### Custom Date Formatting

```swift
import Foundation

struct Event: Codable {
    let id: Int
    let name: String
    let eventDate: Date
    let image: Data
    
    enum CodingKeys: String, CodingKey {
        case id, name
        case eventDate = "event_date"
        case image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Decode date from string
        let dateString = try container.decode(String.self, forKey: .eventDate)
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: dateString) else {
            throw DecodingError.dataCorruptedError(forKey: .eventDate, in: container, debugDescription: "Invalid date format")
        }
        eventDate = date
        
        // Decode image from base64
        let base64String = try container.decode(String.self, forKey: .image)
        guard let imageData = Data(base64Encoded: base64String) else {
            throw DecodingError.dataCorruptedError(forKey: .image, in: container, debugDescription: "Invalid base64 data")
        }
        image = imageData
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        
        // Encode date to ISO8601 string
        let formatter = ISO8601DateFormatter()
        let dateString = formatter.string(from: eventDate)
        try container.encode(dateString, forKey: .eventDate)
        
        // Encode image to base64
        let base64String = image.base64EncodedString()
        try container.encode(base64String, forKey: .image)
    }
}
```

### Using DateDecodingStrategy

```swift
import Foundation

let json = """
{
    "id": 1,
    "date": "2024-01-15T10:30:00Z"
}
""".data(using: .utf8)!

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601
decoder.dataDecodingStrategy = .base64

struct Event: Codable {
    let id: Int
    let date: Date
}
```

---

## 🎯 Best Practices

### 1. Validate Decoded Data
```swift
// ✅ Check constraints
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let age = try container.decode(Int.self, forKey: .age)
    
    guard age >= 0 && age <= 150 else {
        throw DecodingError.dataCorruptedError(forKey: .age, in: container, debugDescription: "Invalid age")
    }
    
    self.age = age
}

// ❌ Accept any value
self.age = try container.decode(Int.self, forKey: .age)
```

### 2. Provide Clear Error Messages
```swift
// ✅ Descriptive errors
throw DecodingError.dataCorruptedError(forddenKey: .date, in: container, debugDescription: "Expected ISO8601 date format")

// ❌ Generic errors
throw DecodingError.dataCorrupted(...)
```

### 3. Handle Optional Fields
```swift
// ✅ Use decodeIfPresent
let nickname = try container.decodeIfPresent(String.self, forKey: .nickname)

// ❌ Assume field exists
let nickname = try container.decode(String.self, forKey: .nickname)
```

---

## ❌ Common Mistakes

### Mistake 1: Ignoring Date Formats

**WRONG:**
```swift
// ❌ Fails if JSON has different format
struct Event: Codable {
    let date: Date  // Assumes ISO8601
}
```

**CORRECT:**
```swift
// ✅ Specify format or handle custom
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

// Or custom decode
init(from decoder: Decoder) throws {
    let dateString = try container.decode(String.self, forKey: .date)
    self.date = parseCustomDate(dateString)
}
```

---

### Mistake 2: Not Handling Missing Fields

**WRONG:**
```swift
// ❌ Crashes if field missing
let value = try container.decode(String.self, forKey: .optional)
```

**CORRECT:**
```swift
// ✅ Check if field exists
let value = try container.decodeIfPresent(String.self, forKey: .optional)
```

---

## Related Topics

- [Error Handling](../01-fundamentals/error-handling.md)
- [Networking - REST API](../03-networking/rest-api.md)
- [Type System](../01-fundamentals/types.md)

---

**Master complex JSON encoding and decoding!**
