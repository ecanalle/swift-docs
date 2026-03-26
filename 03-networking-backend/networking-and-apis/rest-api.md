# REST APIs in Swift

## Overview

REST (Representational State Transfer) is the dominant paradigm for web APIs. Understanding how to design, consume, and interact with RESTful services is essential for modern iOS development.

## Main Topics

- [REST Principles](#rest-principles)
- [HTTP Methods](#http-methods)
- [Status Codes](#status-codes)
- [Consuming REST APIs](#consuming-rest-apis)
- [Request/Response Handling](#requestresponse-handling)
- [Error Handling](#error-handling)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [REST API Best Practices](https://restfulapi.net/)
- [HTTP Status Codes](https://httpwg.org/specs/rfc7231.html#status.codes)

---

## REST Principles

### Core Concepts

```swift
// REST is resource-based, operation-agnostic
// Base URL: https://api.example.com/v1

// Resources are nouns
GET    /users              // Get all users
GET    /users/123          // Get user with ID 123
GET    /users/123/posts    // Get post by user 123

// Operations are HTTP verbs (methods)
POST   /users              // Create user
PUT    /users/123          // Replace user
PATCH  /users/123          // Partial update
DELETE /users/123          // Delete user

// Stateless - each request contains all needed info
let request = URLRequest(url: url)
request.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
// No session state maintained by server
```

### Levels of REST Maturity (Richardson)

```swift
// Level 0: HTTP RPC
// Uses single endpoint, POST for all operations
// ❌ Not truly REST
POST /api?action=getUser&id=123
POST /api?action=updateUser&id=123

// Level 1: Resources
// Uses multiple endpoints for resources
// ✅ Better
GET  /users/123
POST /users
PUT  /users/123

// Level 2: HTTP Verbs
// Uses correct HTTP methods
// ✅ Good REST
GET    /users/123        // Get
POST   /users            // Create
PUT    /users/123        // Update
DELETE /users/123        // Delete

// Level 3: HATEOAS (Hypermedia As The Engine Of Application State)
// Responses include links to related resources
// ✅ Full REST
{
    "id": 123,
    "name": "John",
    "_links": {
        "self": { "href": "/users/123" },
        "posts": { "href": "/users/123/posts" },
        "friends": { "href": "/users/123/friends" }
    }
}
```

---

## HTTP Methods

### GET - Retrieve

```swift
// GET is safe and idempotent (no side effects)
let url = URL(string: "https://api.example.com/users/123")!
let request = URLRequest(url: url)

URLSession.shared.dataTask(with: request) { data, response, error in
    if let data = data {
        let user = try? JSONDecoder().decode(User.self, from: data)
    }
}.resume()

// Query parameters
var components = URLComponents(string: "https://api.example.com/users")!
components.queryItems = [
    URLQueryItem(name: "page", value: "1"),
    URLQueryItem(name: "limit", value: "10"),
    URLQueryItem(name: "sort", value: "name")
]

let url = components.url!  // https://api.example.com/users?page=1&limit=10&sort=name
```

### POST - Create

```swift
// POST creates a new resource
var request = URLRequest(url: URL(string: "https://api.example.com/users")!)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let newUser = User(name: "Jane", email: "jane@example.com")
request.httpBody = try? JSONEncoder().encode(newUser)

URLSession.shared.dataTask(with: request) { data, response, error in
    if let httpResponse = response as? HTTPURLResponse {
        if httpResponse.statusCode == 201 {
            // Resource created
            if let data = data {
                let createdUser = try? JSONDecoder().decode(User.self, from: data)
                print("User created: \(createdUser?.id ?? -1)")
            }
        }
    }
}.resume()
```

### PUT - Replace

```swift
// PUT replaces entire resource
var request = URLRequest(url: URL(string: "https://api.example.com/users/123")!)
request.httpMethod = "PUT"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let updatedUser = User(name: "Jane", email: "jane.doe@example.com")
request.httpBody = try? JSONEncoder().encode(updatedUser)

URLSession.shared.dataTask(with: request) { data, response, error in
    if let httpResponse = response as? HTTPURLResponse {
        if httpResponse.statusCode == 200 {
            print("User replaced")
        }
    }
}.resume()
```

### PATCH - Partial Update

```swift
// PATCH updates part of resource
var request = URLRequest(url: URL(string: "https://api.example.com/users/123")!)
request.httpMethod = "PATCH"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let partialUpdate = ["email": "jane.new@example.com"]
request.httpBody = try? JSONSerialization.data(withJSONObject: partialUpdate)

URLSession.shared.dataTask(with: request) { data, response, error in
    if let httpResponse = response as? HTTPURLResponse {
        if httpResponse.statusCode == 200 {
            print("User partially updated")
        }
    }
}.resume()
```

### DELETE - Remove

```swift
// DELETE removes resource
var request = URLRequest(url: URL(string: "https://api.example.com/users/123")!)
request.httpMethod = "DELETE"

URLSession.shared.dataTask(with: request) { _, response, error in
    if let httpResponse = response as? HTTPURLResponse {
        if httpResponse.statusCode == 204 {
            print("User deleted")
        }
    }
}.resume()
```

---

## Status Codes

### 2xx Success

```swift
// 200 OK - Request succeeded
// 201 Created - New resource created
// 204 No Content - Success, no body to return

let response = HTTPURLResponse(url: url, statusCode: 201, httpVersion: nil, headerFields: nil)
switch response?.statusCode {
case 200:
    print("Success")
case 201:
    print("Created")
case 204:
    print("No content")
default:
    break
}
```

### 4xx Client Error

```swift
// 400 Bad Request - Invalid request
// 401 Unauthorized - Authentication required
// 403 Forbidden - Authenticated but not allowed
// 404 Not Found - Resource doesn't exist
// 409 Conflict - Request conflicts with current state

switch response?.statusCode {
case 400:
    print("Invalid request - check parameters")
case 401:
    print("Authentication required - login")
case 403:
    print("Permission denied")
case 404:
    print("Not found")
case 409:
    print("Conflict")
default:
    break
}
```

### 5xx Server Error

```swift
// 500 Internal Server Error - Server error
// 503 Service Unavailable - Server down/maintenance

switch response?.statusCode {
case 500:
    print("Server error - try again later")
case 503:
    print("Service unavailable")
default:
    break
}
```

---

## Consuming REST APIs

### Simple GET Request

```swift
struct Post: Codable {
    let id: Int
    let title: String
    let body: String
}

func fetchPosts() async throws -> [Post] {
    let url = URL(string: "https://jsonplaceholder.typicode.com/posts")!
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode([Post].self, from: data)
}

// Usage
Task {
    let posts = try await fetchPosts()
    print("Fetched \(posts.count) posts")
}
```

### API Client Service

```swift
enum APIError: Error {
    case invalidURL
    case networkError
    case decodingError
    case serverError(Int)
    case unauthorized
}

class APIClient {
    static let shared = APIClient()
    private let baseURL = URL(string: "https://api.example.com")!
    
    func get<T: Decodable>(_ endpoint: String) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    func post<T: Decodable>(_ endpoint: String, body: Encodable) async throws -> T {
        let url = baseURL.appendingPathComponent(endpoint)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.networkError
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
}

// Usage
struct UserResponse: Codable {
    let id: Int
    let name: String
}

let user: UserResponse = try await APIClient.shared.get("users/1")
```

---

## Request/Response Handling

### Complete Example

```swift
struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

struct APIRequest {
    let endpoint: String
    let method: String = "GET"
    let headers: [String: String]?
    let body: Encodable?
}

class UserService {
    let baseURL = URL(string: "https://api.example.com")!
    
    func getUser(id: Int) async throws -> User {
        let url = baseURL.appendingPathComponent("users/\(id)")
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
    
    func createUser(name: String, email: String) async throws -> User {
        let url = baseURL.appendingPathComponent("users")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let userData = ["name": name, "email": email]
        request.httpBody = try JSONSerialization.data(withJSONObject: userData)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(User.self, from: data)
    }
}
```

---

## Error Handling

### Custom Error Types

```swift
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case requestFailed
    case invalidStatusCode(Int)
    case decodingFailed
    case noInternetConnection
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .requestFailed:
            return "Request failed"
        case .invalidStatusCode(let code):
            return "Server returned status code \(code)"
        case .decodingFailed:
            return "Failed to decode response"
        case .noInternetConnection:
            return "No internet connection"
        }
    }
}

// Usage
do {
    let user: User = try await fetchUser()
} catch let error as NetworkError {
    print("Network error: \(error.errorDescription ?? "Unknown")")
} catch {
    print("Error: \(error)")
}
```

---

## 🎯 Best Practices

### 1. Use Proper HTTP Methods
- GET for retrieval
- POST for creation
- PUT/PATCH for updates
- DELETE for removal

### 2. Version Your API
```swift
let baseURL = URL(string: "https://api.example.com/v1")!
```

### 3. Use Meaningful Status Codes
```swift
// Use correct status codes
201 // Created, not 200
204 // No content for successful delete
```

### 4. Consistent Error Responses
```swift
{
    "error": {
        "code": "INVALID_REQUEST",
        "message": "Missing required field: email"
    }
}
```

### 5. Pagination for Large Results
```swift
// GET /users?page=1&limit=20&offset=0
```

---

## ❌ Common Mistakes

### Mistake 1: Ignoring Status Codes

**WRONG:**
```swift
// ❌ Treats all responses the same
let user = try JSONDecoder().decode(User.self, from: data)
```

**CORRECT:**
```swift
// ✅ Check status codes
if (200...299).contains(httpResponse.statusCode) {
    let user = try JSONDecoder().decode(User.self, from: data)
}
```

---

### Mistake 2: Wrong HTTP Method

**WRONG:**
```swift
// ❌ POST to retrieve (should be GET)
POST /users/123
```

**CORRECT:**
```swift
// ✅ Correct methods
GET    /users/123      // Retrieve
POST   /users          // Create
PUT    /users/123      // Update
DELETE /users/123      // Delete
```

---

## Related Topics

- [URLSession](urlsession.md)
- [Error Handling](../../01-fundamentals/fundamentals/error-handling.md)
- [Networking Best Practices](networking-and-apis.md)

---

**Master REST APIs for seamless backend integration!**
