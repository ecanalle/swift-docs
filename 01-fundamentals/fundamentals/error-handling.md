# Error Handling in Swift

## Overview

Proper error handling is critical for building reliable applications. Swift provides multiple patterns—from simple optionals to Result types to try/catch/throws—each suited for different scenarios. Understanding when and how to use each pattern is essential for robust code.

## Main Topics

- [Error Basics](#error-basics)
- [Throwing Functions](#throwing-functions)
- [Try/Catch Pattern](#trycatch-pattern)
- [Result Type](#result-type)
- [Custom Errors](#custom-errors)
- [Error Propagation](#error-propagation)
- [Async Error Handling](#async-error-handling)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [The Swift Programming Language - Error Handling](https://docs.swift.org/swift-book/documentation/the-swift-programming-language/errorhandling)
- [Apple: Error Handling Patterns](https://developer.apple.com/videos/play/wwdc2015/215/)

---

## Error Basics

### Errors vs Optionals

```swift
// ❌ Optional - loses error information
func parseJSON(_ data: Data) -> [String: Any]? {
    return nil  // Why did it fail?
}

// ✅ Throws - provides error information
enum ParseError: Error {
    case invalidFormat
    case missingKey(String)
    case decodingFailed(String)
}

func parseJSON(_ data: Data) throws -> [String: Any] {
    throw ParseError.invalidFormat
    // Caller knows exactly why it failed
}

// ✅ Result - more explicit error handling
func parseJSONWithResult(_ data: Data) -> Result<[String: Any], ParseError> {
    return .failure(.invalidFormat)
}
```

### When to Use Each

```swift
// Use Optional: When absence is normal
func findUser(in array: [User], by id: Int) -> User? {
    return array.first { $0.id == id }
}

// Use Throws: When error is exceptional
func authenticateUser(_ credentials: Credentials) throws -> User {
    guard isValidCredentials(credentials) else {
        throw AuthError.invalidCredentials
    }
    // ...
}

// Use Result: For completion handlers
func fetchDataFromNetwork(completion: @escaping (Result<Data, NetworkError>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, _, error in
        if let error = error {
            completion(.failure(.networkError(error)))
        } else if let data = data {
            completion(.success(data))
        }
    }.resume()
}
```

---

## Throwing Functions

### Basic Throwing

```swift
enum FileError: Error {
    case fileNotFound
    case permissionDenied
    case invalidFormat
}

// Throwing function
func readFile(_ filename: String) throws -> String {
    guard fileExists(filename) else {
        throw FileError.fileNotFound
    }
    
    guard hasReadPermission(filename) else {
        throw FileError.permissionDenied
    }
    
    return contents
}

// Calling throwing function
do {
    let content = try readFile("data.txt")
    print(content)
} catch FileError.fileNotFound {
    print("File not found")
} catch FileError.permissionDenied {
    print("Permission denied")
} catch {
    print("Unknown error: \(error)")
}
```

### Rethrowing Functions

```swift
// Function that can rethrow errors from passed closure
func retry<T>(_ times: Int, operation: () throws -> T) rethrows -> T {
    var lastError: Error?
    
    for _ in 1...times {
        do {
            return try operation()
        } catch {
            lastError = error
        }
    }
    
    throw lastError ?? NSError(domain: "retry", code: -1)
}

// Usage
let result = try retry(3) {
    try complexOperation()
}
```

---

## Try/Catch Pattern

### Basic Try/Catch

```swift
do {
    let user = try parseUser(from: data)
    print("User: \(user.name)")
} catch {
    print("Error: \(error)")
}
```

### Multiple Catch Blocks (Pattern Matching)

```swift
enum NetworkError: Error {
    case timeout
    case serverError(Int)
    case connectionLost
    case invalidResponse
}

do {
    let data = try fetchData()
} catch NetworkError.timeout {
    print("Request timed out, retry later")
} catch NetworkError.serverError(let code) {
    print("Server error: \(code)")
} catch NetworkError.connectionLost {
    print("Connection lost, check internet")
} catch NetworkError.invalidResponse {
    print("Server returned invalid data")
} catch {
    print("Unknown error: \(error)")
}
```

### Try? and Try! (Not Recommended)

```swift
// try? - returns optional, discards error
let user = try? parseUser(from: data)  // User?

// try! - force unwrap, crashes if error
let user = try! parseUser(from: data)  // Crashes if error!

// Better approach: use do/catch
do {
    let user = try parseUser(from: data)
} catch {
    // Handle error properly
}
```

---

## Result Type

### Result Basics

```swift
// Result<Success, Failure> where Failure: Error
typealias ParseResult = Result<[String: String], ParseError>

// Success case
let success: ParseResult = .success(["key": "value"])

// Failure case
let failure: ParseResult = .failure(.invalidFormat)

// Using Result
let result: ParseResult = performParsing()

switch result {
case .success(let data):
    print("Parsed: \(data)")
case .failure(let error):
    print("Error: \(error)")
}
```

### Result in Completion Handlers

```swift
// Better than callback hell
func fetchUser(id: Int, completion: @escaping (Result<User, NetworkError>) -> Void) {
    URLSession.shared.dataTask(with: url) { data, response, error in
        if let error = error {
            completion(.failure(.networkError(error)))
            return
        }
        
        guard let data = data else {
            completion(.failure(.noData))
            return
        }
        
        do {
            let user = try JSONDecoder().decode(User.self, from: data)
            completion(.success(user))
        } catch {
            completion(.failure(.decodingError(error)))
        }
    }.resume()
}

// Calling
fetchUser(id: 1) { result in
    switch result {
    case .success(let user):
        print("Got user: \(user.name)")
    case .failure(let error):
        print("Error: \(error)")
    }
}
```

### Result Methods

```swift
let result: Result<Int, Error> = .success(42)

// Get value
if let value = try? result.get() {
    print("Value: \(value)")
}

// Map success value
let stringResult = result.map { String($0) }

// Map error
let mappedError = result.mapError { NSError(domain: "custom", code: -1, userInfo: nil) }

// FlatMap (chaining)
let chained = result.flatMap { value in
    calculateNext(from: value)
}

// Handler
result.onSuccess { value in
    print("Success: \(value)")
}

result.onFailure { error in
    print("Failure: \(error)")
}
```

---

## Custom Errors

### Defining Custom Errors

```swift
enum UserError: Error {
    case invalidEmail
    case weakPassword
    case userAlreadyExists
    case networkFailed
}

enum ParseError: Error, LocalizedError {
    case invalidFormat
    case missingField(String)
    case decodingFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "The data format is invalid"
        case .missingField(let field):
            return "Missing required field: \(field)"
        case .decodingFailed:
            return "Failed to decode data"
        }
    }
    
    var failureReason: String? {
        return "Check the data and try again"
    }
}
```

### Error Conforming to Protocols

```swift
enum APIError: Error, CustomStringConvertible {
    case invalidURL
    case httpError(statusCode: Int)
    case decodingError
    
    var description: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .httpError(let code):
            return "HTTP Error \(code)"
        case .decodingError:
            return "Failed to decode response"
        }
    }
}

enum DatabaseError: Error, CustomDebugStringConvertible {
    case connectionFailed
    case queryFailed(String)
    
    var debugDescription: String {
        switch self {
        case .connectionFailed:
            return "DEBUG: Could not connect to database"
        case .queryFailed(let query):
            return "DEBUG: Query failed: \(query)"
        }
    }
}
```

---

## Error Propagation

### Propagating with Throws

```swift
// Error propagates up automatically
func loadUserProfile(id: Int) throws -> UserProfile {
    // fetchUser throws
    let user = try fetchUser(id: id)
    
    // fetchProfile throws
    let profile = try fetchProfile(for: user.email)
    
    return profile
}

// Caller must handle
do {
    let profile = try loadUserProfile(id: 1)
} catch {
    print("Error: \(error)")
}
```

### Converting Between Error Types

```swift
enum AppError: Error {
    case apiError(APIError)
    case databaseError(DatabaseError)
    case validationError(String)
}

func complexOperation() throws {
    do {
        try apiCall()
    } catch let error as APIError {
        throw AppError.apiError(error)
    }
    
    do {
        try databaseCall()
    } catch let error as DatabaseError {
        throw AppError.databaseError(error)
    }
}
```

---

## Async Error Handling

### Async Throws

```swift
// Async function that throws
async func fetchUserAsync(id: Int) throws -> User {
    let (data, _) = try await URLSession.shared.data(from: url)
    return try JSONDecoder().decode(User.self, from: data)
}

// Using async throws
Task {
    do {
        let user = try await fetchUserAsync(id: 1)
        print("User: \(user.name)")
    } catch {
        print("Error: \(error)")
    }
}
```

---

## 🎯 Best Practices

### 1. Use Specific Error Types
- Define enums for your domains
- Provide context about what failed
- Include associated values with details

### 2. Handle Errors Where They Occur
- Not everything needs try/catch
- Some errors can be recovered locally
- Only propagate unrecoverable errors

### 3. Distinguish Between Errors and Optionals
- Error: Something went wrong
- Optional: Absence is expected

### 4. Provide Clear Error Messages
- Users need to understand what happened
- Include recovery suggestions
- Implement LocalizedError

### 5. Test Error Cases
- Test both success and failure paths
- Verify correct error is thrown
- Check error information is useful

---

## ❌ Common Mistakes

### Mistake 1: Using try! in Production

**WRONG:**
```swift
let user = try! parseUser(data)  // Crashes if error!
```

**CORRECT:**
```swift
do {
    let user = try parseUser(data)
} catch {
    handleError(error)
}
```

---

### Mistake 2: Swallowing Errors with try?

**WRONG:**
```swift
let user = try? parseUser(data)  // Silently fails, user is nil
// No idea why it failed
```

**CORRECT:**
```swift
do {
    let user = try parseUser(data)
} catch ParseError.invalidFormat {
    print("Invalid format: ", error)
} catch {
    print("Unexpected error: ", error)
}
```

---

### Mistake 3: Too Generic Errors

**WRONG:**
```swift
enum AppError: Error {
    case failed  // What failed?
    case error   // What error?
}
```

**CORRECT:**
```swift
enum NetworkError: Error {
    case timeout
    case invalidURL
    case serverError(Int)
}

enum ParseError: Error {
    case invalidJSON
    case missingField(String)
}
```

---

## Related Topics

- [Optionals](optionals.md)
- [Async/Await](../../07-advanced/advanced-performance/async-await.md)
- [Result Type](result-type.md)

---

**Handle errors gracefully for robust, professional applications!**
