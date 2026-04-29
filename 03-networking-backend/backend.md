# Backend Architecture & API Design - Building Scalable Systems 🎯

## Overview
Understanding backend architecture and REST API design is crucial for building scalable, maintainable systems. Learn to design APIs that integrate seamlessly with iOS apps, implement proper error handling, versioning, and create backend systems that scale effectively.

## Main Topics
- [API Design Fundamentals](#api-design-fundamentals) - RESTful principles
- [Authentication & Authorization](#authentication--authorization) - Securing APIs
- [API Versioning](#api-versioning) - Managing changes
- [Pagination & Filtering](#pagination--filtering) - Efficient data access
- [Error Handling](#error-handling) - Consistent error responses
- [Rate Limiting](#rate-limiting) - Protecting resources
- [Best Practices](#-best-practices) - Backend strategies
- [Common Mistakes](#-common-mistakes-anti-patterns) - API pitfalls

## Official Documentation
- [REST API Best Practices](https://www.rfc-editor.org/rfc/rfc7231)
- [JSON API Specification](https://jsonapi.org/)
- [GraphQL vs REST](https://graphql.org/learn/)

---

## API Design Fundamentals

### RESTful API Principles

```swift
// ✅ Correct: REST API design principles

// Resources as nouns, not verbs
GET    /api/v1/users              // Get all users
GET    /api/v1/users/{id}         // Get user by ID
POST   /api/v1/users              // Create new user
PUT    /api/v1/users/{id}         // Replace user entirely
PATCH  /api/v1/users/{id}         // Partial update
DELETE /api/v1/users/{id}         // Delete user

// Consistent status codes
200 OK                             // Successful GET, PUT, PATCH
201 Created                        // Successful POST (resource created)
204 No Content                     // Successful DELETE
400 Bad Request                    // Invalid request format
401 Unauthorized                   // Missing authentication
403 Forbidden                      // Authenticated but no permission
404 Not Found                      // Resource doesn't exist
409 Conflict                       // Resource conflict (duplicate)
422 Unprocessable Entity           // Validation failed
429 Too Many Requests              // Rate limited
500 Internal Server Error          // Server error

// Response format
{
  "success": true,
  "data": {
    "id": 1,
    "name": "Alice",
    "email": "alice@example.com"
  },
  "timestamp": "2024-04-29T12:00:00Z"
}

// Error response
{
  "success": false,
  "error": {
    "code": "INVALID_EMAIL",
    "message": "Email format is invalid",
    "field": "email"
  },
  "timestamp": "2024-04-29T12:00:00Z"
}
```

**Key Points:**
- Use HTTP methods correctly (GET, POST, PUT, PATCH, DELETE)
- Resources are nouns, actions are verbs in URL path only when necessary
- Status codes convey success/failure clearly
- Consistent response format across all endpoints

### iOS Client Implementation

```swift
// ✅ Correct: iOS client for RESTful API
import Foundation

struct User: Codable {
    let id: Int
    let name: String
    let email: String
}

class UserAPI {
    let baseURL = URL(string: "https://api.example.com/v1")!
    
    // GET /users
    func fetchAllUsers() async throws -> [User] {
        let endpoint = baseURL.appendingPathComponent("users")
        let (data, response) = try await URLSession.shared.data(from: endpoint)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(APIResponse<[User]>.self, from: data)
        return envelope.data
    }
    
    // GET /users/{id}
    func fetchUser(id: Int) async throws -> User {
        let endpoint = baseURL.appendingPathComponent("users/\(id)")
        let (data, response) = try await URLSession.shared.data(from: endpoint)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(APIResponse<User>.self, from: data)
        return envelope.data
    }
    
    // POST /users
    func createUser(_ user: User) async throws -> User {
        var request = URLRequest(url: baseURL.appendingPathComponent("users"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let encoder = JSONEncoder()
        request.httpBody = try encoder.encode(user)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 201 else {
            throw APIError.invalidResponse
        }
        
        let decoder = JSONDecoder()
        let envelope = try decoder.decode(APIResponse<User>.self, from: data)
        return envelope.data
    }
    
    // DELETE /users/{id}
    func deleteUser(id: Int) async throws {
        var request = URLRequest(url: baseURL.appendingPathComponent("users/\(id)"))
        request.httpMethod = "DELETE"
        
        let (_, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 204 else {
            throw APIError.invalidResponse
        }
    }
}

// Response envelope
struct APIResponse<T: Codable>: Codable {
    let success: Bool
    let data: T
    let timestamp: String
}

enum APIError: Error {
    case invalidResponse
    case decodingError
    case networkError
}
```

---

## Authentication & Authorization

### JWT Token-Based Authentication

```swift
// ✅ Correct: JWT authentication flow
class AuthenticationManager {
    var accessToken: String?
    var refreshToken: String?
    
    // Login
    func login(email: String, password: String) async throws {
        var request = URLRequest(url: URL(string: "https://api.example.com/v1/auth/login")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let credentials = ["email": email, "password": password]
        request.httpBody = try JSONEncoder().encode(credentials)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.loginFailed
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(LoginResponse.self, from: data)
        
        // Store tokens
        self.accessToken = response.accessToken
        self.refreshToken = response.refreshToken
        
        // Save to Keychain
        try KeychainManager.save(response.accessToken, for: "access_token")
        try KeychainManager.save(response.refreshToken, for: "refresh_token")
    }
    
    // Refresh token
    func refreshAccessToken() async throws {
        guard let refreshToken = self.refreshToken else {
            throw AuthError.noRefreshToken
        }
        
        var request = URLRequest(url: URL(string: "https://api.example.com/v1/auth/refresh")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(refreshToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AuthError.refreshFailed
        }
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(TokenResponse.self, from: data)
        
        self.accessToken = response.accessToken
        try KeychainManager.save(response.accessToken, for: "access_token")
    }
    
    // Logout
    func logout() async throws {
        guard let token = accessToken else { return }
        
        var request = URLRequest(url: URL(string: "https://api.example.com/v1/auth/logout")!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        _ = try await URLSession.shared.data(for: request)
        
        // Clear stored tokens
        self.accessToken = nil
        self.refreshToken = nil
        try KeychainManager.delete(for: "access_token")
        try KeychainManager.delete(for: "refresh_token")
    }
}

struct LoginResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
}

struct TokenResponse: Codable {
    let accessToken: String
}

enum AuthError: Error {
    case loginFailed
    case refreshFailed
    case noRefreshToken
}
```

---

## API Versioning

### Managing API Versions

```swift
// ✅ Correct: API versioning strategies

// Strategy 1: URL Path Versioning (Most Common)
GET /api/v1/users
GET /api/v2/users     // Different structure if needed

// Strategy 2: URL Query Parameter
GET /api/users?version=1
GET /api/users?version=2

// Strategy 3: Header-Based
GET /api/users
Header: Accept: application/json; version=1

// iOS implementation with version strategy
class APIClient {
    enum APIVersion {
        case v1
        case v2
        
        var path: String {
            switch self {
            case .v1: return "/v1"
            case .v2: return "/v2"
            }
        }
    }
    
    let baseURL = URL(string: "https://api.example.com/api")!
    let version: APIVersion = .v2
    
    func buildEndpoint(_ path: String) -> URL {
        return baseURL.appendingPathComponent(version.path).appendingPathComponent(path)
    }
    
    // Usage
    func fetchUsers() async throws -> [User] {
        let endpoint = buildEndpoint("users")
        // Make request to /api/v2/users
    }
}

// Handling deprecated endpoints
class APIClientV2: APIClient {
    // New field added in v2
    struct UserV2: Codable {
        let id: Int
        let name: String
        let email: String
        let avatarURL: String?  // New in v2
    }
    
    func fetchUsers() async throws -> [UserV2] {
        let endpoint = buildEndpoint("users")
        // Decode as UserV2 with new field
    }
}
```

---

## Pagination & Filtering

### Implementing Pagination

```swift
// ✅ Correct: Cursor-based pagination
struct PaginatedResponse<T: Codable>: Codable {
    let data: [T]
    let pagination: Pagination
}

struct Pagination: Codable {
    let total: Int
    let page: Int
    let limit: Int
    let hasMore: Bool
    let nextCursor: String?
}

class PaginationManager {
    var currentPage = 1
    var hasMore = true
    var allItems: [User] = []
    
    func loadNextPage() async throws -> [User] {
        guard hasMore else { return [] }
        
        var components = URLComponents(string: "https://api.example.com/v1/users")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(currentPage)),
            URLQueryItem(name: "limit", value: "20")
        ]
        
        guard let url = components.url else { throw APIError.invalidURL }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let response = try decoder.decode(PaginatedResponse<User>.self, from: data)
        
        allItems.append(contentsOf: response.data)
        hasMore = response.pagination.hasMore
        currentPage += 1
        
        return response.data
    }
}

// Filtering
class FilteredAPI {
    func fetchUsers(filter: UserFilter) async throws -> [User] {
        var components = URLComponents(string: "https://api.example.com/v1/users")!
        components.queryItems = [
            URLQueryItem(name: "role", value: filter.role),
            URLQueryItem(name: "status", value: filter.status),
            URLQueryItem(name: "sortBy", value: filter.sortBy),
            URLQueryItem(name: "order", value: filter.order)
        ]
        
        guard let url = components.url else { throw APIError.invalidURL }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoder = JSONDecoder()
        let response = try decoder.decode(APIResponse<[User]>.self, from: data)
        return response.data
    }
}

struct UserFilter {
    let role: String?
    let status: String?
    let sortBy: String = "createdAt"
    let order: String = "desc"
}
```

---

## Error Handling

### Consistent Error Responses

```swift
// ✅ Correct: Comprehensive error handling
struct APIErrorResponse: Codable {
    let code: String
    let message: String
    let details: [ErrorDetail]?
    let timestamp: String
}

struct ErrorDetail: Codable {
    let field: String
    let issue: String
}

// iOS Error Handling
enum APIError: LocalizedError {
    case invalidResponse
    case decodingError
    case networkError(Error)
    case serverError(status: Int, message: String)
    case validationError([ErrorDetail])
    case unauthorized
    case rateLimited(retryAfter: Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid server response"
        case .decodingError:
            return "Failed to parse response"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .serverError(_, let message):
            return message
        case .validationError(let details):
            return details.map { "\($0.field): \($0.issue)" }.joined(separator: ", ")
        case .unauthorized:
            return "Authentication failed"
        case .rateLimited:
            return "Too many requests"
        }
    }
}

class ErrorHandler {
    static func handle(_ response: HTTPURLResponse, _ data: Data) throws {
        let decoder = JSONDecoder()
        
        switch response.statusCode {
        case 200...299:
            break  // Success
            
        case 400:
            let error = try decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.serverError(status: 400, message: error.message)
            
        case 401:
            throw APIError.unauthorized
            
        case 422:
            let error = try decoder.decode(APIErrorResponse.self, from: data)
            throw APIError.validationError(error.details ?? [])
            
        case 429:
            // Extract Retry-After header
            let retryAfter = Int(response.value(forHTTPHeaderField: "Retry-After") ?? "60") ?? 60
            throw APIError.rateLimited(retryAfter: retryAfter)
            
        default:
            throw APIError.serverError(status: response.statusCode, message: "Unknown error")
        }
    }
}
```

---

## Rate Limiting

### Handling Rate Limits

```swift
// ✅ Correct: Rate limit awareness
class RateLimitedClient {
    var requestsRemaining = 1000
    var resetTime: Date?
    
    func makeRequest(_ endpoint: URL) async throws {
        if requestsRemaining <= 0,
           let resetTime = resetTime,
           Date() < resetTime {
            let waitTime = resetTime.timeIntervalSinceNow
            throw APIError.rateLimited(retryAfter: Int(waitTime))
        }
        
        var request = URLRequest(url: endpoint)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        // Extract rate limit headers
        if let remaining = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
           let remainingInt = Int(remaining) {
            requestsRemaining = remainingInt
        }
        
        if let reset = httpResponse.value(forHTTPHeaderField: "X-RateLimit-Reset"),
           let resetInt = Int(reset) {
            resetTime = Date(timeIntervalSince1970: TimeInterval(resetInt))
        }
        
        try ErrorHandler.handle(httpResponse, data)
    }
}
```

---

## ✅ Best Practices

### Practice 1: Use Consistent Response Format
**DO:**
```swift
// ✅ All responses follow same structure
{
  "success": true,
  "data": { ... },
  "timestamp": "ISO8601"
}
```

### Practice 2: Implement Proper Error Responses
**DO:**
```swift
// ✅ Consistent error format
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [...]
  }
}
```

### Practice 3: Version Your API From Day One
**DO:**
```swift
// ✅ Start with /v1 even for initial release
GET /api/v1/users

// ✅ Easier to roll out v2 later if needed
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Not Following HTTP Semantics
**WRONG:**
```
POST /api/deleteUser/{id}   // ❌ Wrong method
GET /api/updateUser/{id}    // ❌ Wrong method
```

**CORRECT:**
```
DELETE /api/users/{id}      // ✅ Correct
PATCH /api/users/{id}       // ✅ Correct
```

### Mistake 2: Inconsistent Error Responses
**WRONG:**
```
// Sometimes:
{ "error": "Not found" }

// Sometimes:
{ "message": "User not found" }

// Sometimes:
{ "errors": { "id": "invalid" } }
```

**CORRECT:**
```
// Always:
{
  "success": false,
  "error": {
    "code": "NOT_FOUND",
    "message": "User not found"
  }
}
```

### Mistake 3: Not Handling Stale Data
**WRONG:**
```swift
// ❌ No cache invalidation
// Client keeps stale data after update
```

**CORRECT:**
```swift
// ✅ Return updated object
POST /api/users/{id}
Response:
{
  "success": true,
  "data": { /* Updated user */ }
}
```

---

## 🔗 Related Topics
- [Networking Fundamentals](../03-networking/networking-basics.md) - Network layer
- [Authentication](../07-advanced/permissions-and-security.md) - Auth patterns
- [Data Persistence](../06-data/persistence-and-storage.md) - Caching strategies
- [Error Handling](../02-architecture/error-handling.md) - Error management
