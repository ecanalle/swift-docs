# Codable and JSON Encoding/Decoding

## Overview

Codable protocol enables automatic encoding and decoding of Swift types to/from JSON and other formats. It simplifies serialization with minimal boilerplate code.

## Main Topics

- [Codable Basics](#codable-basics)
- [Encoding](#encoding)
- [Decoding](#decoding)
- [Custom Coding](#custom-coding)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Codable Documentation](https://developer.apple.com/documentation/swift/codable)

---

## Codable Basics

### Simple Codable Model

```swift
import Foundation

// ✅ Codable includes both Encodable and Decodable
struct User: Codable {
    let id: Int
    let name: String
    let email: String
    let isActive: Bool
}

// Automatically supports:
// - Encoding to JSON
// - Decoding from JSON
// - Works with JSONEncoder/JSONDecoder

let user = User(id: 1, name: "John", email: "john@example.com", isActive: true)
```

### JSON Structure Mapping

```swift
import Foundation

// JSON:
// {
//   "id": 1,
//   "name": "John",
//   "email": "john@example.com",
//   "is_active": true
// }

// ✅ With CodingKeys for snake_case mapping
struct User: Codable {
    let id: Int
    let name: String
    let email: String
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case email
        case isActive = "is_active"  // Maps JSON "is_active" to Swift "isActive"
    }
}
```

---

## Encoding

### Encoding to JSON

```swift
import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

let user = User(id: 1, name: "John", email: "john@example.com")

// Encode to Data
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted  // Readable formatting

do {
    let jsonData = try encoder.encode(user)
    
    // Convert to String
    if let jsonString = String(data: jsonData, encoding: .utf8) {
        print(jsonString)
        // {
        //   "id" : 1,
        //   "name" : "John",
        //   "email" : "john@example.com"
        // }
    }
} catch {
    print("Encoding error: \(error)")
}
```

### Encoding Arrays

```swift
struct Post: Codable {
    let id: Int
    let title: String
    let content: String
}

let posts = [
    Post(id: 1, title: "First Post", content: "Hello"),
    Post(id: 2, title: "Second Post", content: "World")
]

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

do {
    let jsonData = try encoder.encode(posts)
    print(String(data: jsonData, encoding: .utf8) ?? "")
    // [
    //   {
    //     "id" : 1,
    //     "title" : "First Post",
    //     "content" : "Hello"
    //   },
    //   ...
    // ]
} catch {
    print("Error: \(error)")
}
```

### Writing to File

```swift
struct Configuration: Codable {
    let apiKey: String
    let endpoint: String
    let timeout: Int
}

let config = Configuration(
    apiKey: "secret-key",
    endpoint: "https://api.example.com",
    timeout: 30
)

let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

do {
    let jsonData = try encoder.encode(config)
    
    // Get Documents directory
    let documentsURL = FileManager.default.urls(
        for: .documentDirectory,
        in: .userDomainMask
    )[0]
    
    let fileURL = documentsURL.appendingPathComponent("config.json")
    
    // Write to file
    try jsonData.write(to: fileURL)
    print("Config saved to \(fileURL.path)")
} catch {
    print("Error: \(error)")
}
```

---

## Decoding

### Decoding from JSON

```swift
import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

let jsonString = """
{
    "id": 1,
    "name": "John",
    "email": "john@example.com"
}
"""

let jsonData = jsonString.data(using: .utf8)!

let decoder = JSONDecoder()

do {
    let user = try decoder.decode(User.self, from: jsonData)
    print("User: \(user.name), \(user.email)")
} catch {
    print("Decoding error: \(error)")
}
```

### Decoding Arrays

```swift
struct Post: Codable {
    let id: Int
    let title: String
}

let jsonString = """
[
    {"id": 1, "title": "First"},
    {"id": 2, "title": "Second"}
]
"""

let jsonData = jsonString.data(using: .utf8)!
let decoder = JSONDecoder()

do {
    let posts = try decoder.decode([Post].self, from: jsonData)
    for post in posts {
        print("Post \(post.id): \(post.title)")
    }
} catch {
    print("Error: \(error)")
}
```

### Reading from File

```swift
struct Configuration: Codable {
    let apiKey: String
    let endpoint: String
}

let documentsURL = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0]

let fileURL = documentsURL.appendingPathComponent("config.json")

do {
    let jsonData = try Data(contentsOf: fileURL)
    let decoder = JSONDecoder()
    let config = try decoder.decode(Configuration.self, from: jsonData)
    
    print("API Key: \(config.apiKey)")
    print("Endpoint: \(config.endpoint)")
} catch {
    print("Error: \(error)")
}
```

---

## Custom Coding

### Custom Encoding/Decoding

```swift
import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let email: String
    let joinDate: Date
    
    // Custom encode
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(email, forKey: .email)
        
        // Custom date formatting
        let dateFormatter = ISO8601DateFormatter()
        let dateString = dateFormatter.string(from: joinDate)
        try container.encode(dateString, forKey: .joinDate)
    }
    
    // Custom decode
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        email = try container.decode(String.self, forKey: .email)
        
        // Custom date parsing
        let dateString = try container.decode(String.self, forKey: .joinDate)
        let dateFormatter = ISO8601DateFormatter()
        joinDate = dateFormatter.date(from: dateString) ?? Date()
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case joinDate = "join_date"
    }
}
```

### Nested Codable Types

```swift
import Foundation

struct Company: Codable {
    let name: String
    let employees: [Employee]
}

struct Employee: Codable {
    let id: Int
    let name: String
    let department: Department
}

struct Department: Codable {
    let name: String
    let budget: Double
}

let jsonString = """
{
    "name": "Tech Corp",
    "employees": [
        {
            "id": 1,
            "name": "Alice",
            "department": {
                "name": "Engineering",
                "budget": 100000
            }
        }
    ]
}
"""

let jsonData = jsonString.data(using: .utf8)!
let decoder = JSONDecoder()

do {
    let company = try decoder.decode(Company.self, from: jsonData)
    print("Company: \(company.name)")
    print("First employee: \(company.employees[0].name)")
    print("Department: \(company.employees[0].department.name)")
} catch {
    print("Error: \(error)")
}
```

### Error Handling for Missing Fields

```swift
import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let nickname: String?  // Optional
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        
        // Optional field
        nickname = try container.decodeIfPresent(String.self, forKey: .nickname)
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, nickname
    }
}

let jsonString = """
{
    "id": 1,
    "name": "John"
}
"""

let decoder = JSONDecoder()
let user = try decoder.decode(User.self, from: jsonString.data(using: .utf8)!)
print(user.nickname ?? "No nickname")
```

---

## 🎯 Best Practices

### 1. Use CodingKeys for Mapping
```swift
// ✅ Map different JSON keys
struct User: Codable {
    let firstName: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
    }
}

// ❌ Tight coupling to JSON format
struct User: Codable {
    let first_name: String  // Bad Swift naming
}
```

### 2. Make Fields Optional When Needed
```swift
// ✅ Handle missing fields
struct User: Codable {
    let id: Int
    let name: String
    let bio: String?
}

// ❌ Fails if field missing
struct User: Codable {
    let id: Int
    let name: String
    let bio: String  // Required
}
```

### 3. Format Output for Debugging
```swift
// ✅ Pretty print for debugging
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

// ❌ Compact by default
let encoder = JSONEncoder()
```

---

## ❌ Common Mistakes

### Mistake 1: Ignoring CodingKeys

**WRONG:**
```swift
// ❌ Snake case from JSON doesn't match Swift property
struct User: Codable {
    let firstName: String  // JSON has "first_name"
}

// Decoding fails or gets wrong value
```

**CORRECT:**
```swift
// ✅ Map with CodingKeys
struct User: Codable {
    let firstName: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
    }
}
```

---

### Mistake 2: Not Handling Missing Fields

**WRONG:**
```swift
// ❌ Crashes if field missing
struct User: Codable {
    let id: Int
    let name: String
    let bio: String  // Required
}
```

**CORRECT:**
```swift
// ✅ Make optional or provide default
struct User: Codable {
    let id: Int
    let name: String
    let bio: String?
}
```

---

### Mistake 3: Custom Coding Complexity

**WRONG:**
```swift
// ❌ Over-engineered custom coding
func encode(to encoder: Encoder) throws {
    // 50 lines of complex logic
}
```

**CORRECT:**
```swift
// ✅ Use CodingKeys and simple transforms
enum CodingKeys: String, CodingKey {
    case userID = "id"
}
```

---

## Related Topics

- [File Management](../06-data/file-management.md)
- [REST APIs](rest-api.md)
- [SwiftData](../06-data/persistence-and-storage/swiftdata.md)

---

**Master Codable for seamless JSON serialization!**
