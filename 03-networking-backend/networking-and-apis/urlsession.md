# URLSession and HTTP Networking

## Overview

URLSession is the fundamental networking framework in iOS. Mastering URLSession—from basic requests to complex scenarios with authentication and custom configuration—is essential for modern app development.

## Main Topics

- [URLSession Basics](#urlsession-basics)
- [HTTP Methods](#http-methods)
- [Request Configuration](#request-configuration)
- [Response Handling](#response-handling)
- [Error Handling](#error-handling)
- [Authentication](#authentication)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [URLSession Documentation](https://developer.apple.com/documentation/foundation/urlsession)
- [URL and HTTP networking in Swift](https://developer.apple.com/videos/play/wwdc2023/10017/)

---

## URLSession Basics

### Simple GET Request

```swift
import Foundation

// Basic GET request
let url = URL(string: "https://api.example.com/users/1")!
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    if let error = error {
        print("Error: \(error)")
        return
    }
    
    if let data = data {
        print("Received \(data.count) bytes")
    }
}
task.resume()

// With HTTP response checking
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    if let httpResponse = response as? HTTPURLResponse {
        print("Status code: \(httpResponse.statusCode)")
        
        if httpResponse.statusCode == 200 {
            if let data = data {
                // Process successful response
            }
        } else {
            print("HTTP Error: \(httpResponse.statusCode)")
        }
    }
}
task.resume()
```

### Decoding JSON

```swift
// Define models
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

// Fetch and decode
let url = URL(string: "https://api.example.com/users/1")!
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    if let data = data {
        do {
            let decoder = JSONDecoder()
            let user = try decoder.decode(User.self, from: data)
            print("User: \(user.name)")
        } catch {
            print("Decoding error: \(error)")
        }
    }
}
task.resume()
```

---

## HTTP Methods

### GET Request

```swift
var request = URLRequest(url: url)
request.httpMethod = "GET"  // Default

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

### POST Request

```swift
struct CreateUserRequest: Encodable {
    let name: String
    let email: String
}

let url = URL(string: "https://api.example.com/users")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let userData = CreateUserRequest(name: "John", email: "john@example.com")
request.httpBody = try? JSONEncoder().encode(userData)

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

### PUT Request

```swift
var request = URLRequest(url: url)
request.httpMethod = "PUT"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")
request.httpBody = try? JSONEncoder().encode(updatedUser)

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

### DELETE Request

```swift
var request = URLRequest(url: url)
request.httpMethod = "DELETE"

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

---

## Request Configuration

### Custom Headers

```swift
var request = URLRequest(url: url)

// Add custom headers
request.addValue("Bearer token123", forHTTPHeaderField: "Authorization")
request.addValue("en-US", forHTTPHeaderField: "Accept-Language")
request.addValue("gzip, deflate", forHTTPHeaderField: "Accept-Encoding")

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

### Query Parameters

```swift
// Build URL with queries
var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
components.queryItems = [
    URLQueryItem(name: "page", value: "1"),
    URLQueryItem(name: "limit", value: "20"),
    URLQueryItem(name: "sort", value: "name")
]

let request = URLRequest(url: components.url!)
let task = URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

### Timeouts and Caching

```swift
var request = URLRequest(url: url)
request.timeoutInterval = 30  // 30 second timeout

// Session configuration
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
config.timeoutIntervalForResource = 60
config.waitsForConnectivity = true  // Wait if network unavailable
config.requestCachePolicy = .returnCacheDataElseLoad

let session = URLSession(configuration: config)
let task = session.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

---

## Response Handling

### Checking Response Status

```swift
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    guard let httpResponse = response as? HTTPURLResponse else {
        print("Invalid response")
        return
    }
    
    switch httpResponse.statusCode {
    case 200...299:
        print("Success: \(httpResponse.statusCode)")
    case 400...499:
        print("Client error: \(httpResponse.statusCode)")
    case 500...599:
        print("Server error: \(httpResponse.statusCode)")
    default:
        print("Unknown status: \(httpResponse.statusCode)")
    }
}
task.resume()
```

### Response Headers

```swift
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    if let httpResponse = response as? HTTPURLResponse {
        // Read response headers
        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")
        let cacheControl = httpResponse.value(forHTTPHeaderField: "Cache-Control")
        let etag = httpResponse.value(forHTTPHeaderField: "ETag")
        
        print("Content-Type: \(contentType ?? "N/A")")
    }
}
task.resume()
```

---

## Error Handling

### Common Errors

```swift
let task = URLSession.shared.dataTask(with: url) { data, response, error in
    if let error = error as? URLError {
        switch error.code {
        case .timedOut:
            print("Request timed out")
        case .notConnectedToInternet:
            print("No internet connection")
        case .dnsLookupFailed:
            print("DNS lookup failed")
        case .cannotFindHost:
            print("Cannot find host")
        case .connectionLost:
            print("Connection lost")
        default:
            print("Networking error: \(error.code)")
        }
    }
}
task.resume()
```

### Retry Logic

```swift
func fetchWithRetry(url: URL, maxRetries: Int = 3) {
    var retries = 0
    
    func makeRequest() {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                if retries < maxRetries {
                    retries += 1
                    print("Retry attempt \(retries)")
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(retries)) {
                        makeRequest()
                    }
                } else {
                    print("Max retries reached")
                }
            } else {
                print("Success")
            }
        }
        task.resume()
    }
    
    makeRequest()
}
```

---

## Authentication

### Basic Authentication

```swift
let username = "user"
let password = "pass"
let credentials = "\(username):\(password)"
let base64 = credentials.data(using: .utf8)?.base64EncodedString() ?? ""

var request = URLRequest(url: url)
request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

### Bearer Token Authentication

```swift
var request = URLRequest(url: url)
request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

let task = URLSession.shared.dataTask(with: request) { data, response, error in
    // Handle response
}
task.resume()
```

---

## 🎯 Best Practices

### 1. Use URLSessionConfiguration
- Create dedicated session configurations
- Reuse sessions instead of `URLSession.shared` for all requests

### 2. Proper Error Handling
- Check both the error object and HTTP status codes
- Implement retry logic for transient failures

### 3. Async/Await Pattern
- Use modern async/await instead of closures when possible
- Cleaner, more readable code

### 4. Decode Data Safely
- Use `Codable` for automatic JSON handling
- Handle decoding errors explicitly

### 5. Timeouts and Cancellation
- Set appropriate timeouts
- Cancel requests when appropriate

---

## ❌ Common Mistakes

### Mistake 1: No Error Checking

**WRONG:**
```swift
URLSession.shared.dataTask(with: url) { data, _, _ in
    if let data = data,
       let json = try? JSONDecoder().decode(User.self, from: data) {
        updateUI(json)
    }
}.resume()
```

**CORRECT:**
```swift
URLSession.shared.dataTask(with: url) { data, response, error in
    if let error = error {
        handleNetworkError(error)
        return
    }
    
    guard let httpResponse = response as? HTTPURLResponse,
          (200...299).contains(httpResponse.statusCode) else {
        handleHTTPError(response)
        return
    }
    
    if let data = data,
       let json = try? JSONDecoder().decode(User.self, from: data) {
        updateUI(json)
    }
}.resume()
```

---

### Mistake 2: Always Using URLSession.shared

**WRONG:**
```swift
// Shared session doesn't allow custom configuration
URLSession.shared.dataTask(with: request) { ... }.resume()
```

**CORRECT:**
```swift
let config = URLSessionConfiguration.default
config.timeoutIntervalForRequest = 30
config.waitsForConnectivity = true

let session = URLSession(configuration: config)
session.dataTask(with: request) { ... }.resume()
```

---

### Mistake 3: Not Handling UI Updates on Main Thread

**WRONG:**
```swift
URLSession.shared.dataTask(with: url) { data, _, _ in
    if let data = data {
        self.label.text = "Loaded"  // ❌ Wrong thread
    }
}.resume()
```

**CORRECT:**
```swift
URLSession.shared.dataTask(with: url) { data, _, _ in
    if let data = data {
        DispatchQueue.main.async {
            self.label.text = "Loaded"  // ✅ Main thread
        }
    }
}.resume()
```

---

## Related Topics

- [Async/Await](../async-await.md)
- [API Design](api-design.md)
- [Authentication](authentication.md)

---

**Master networking to build responsive, connected apps!**
