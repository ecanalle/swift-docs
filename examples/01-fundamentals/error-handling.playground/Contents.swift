import Foundation

// ============================================================================
// ERROR HANDLING IN SWIFT - Complete Playground Guide
// Corresponds to: 01-fundamentals/fundamentals/error-handling.md
// ============================================================================

// SECTION 1: Defining Custom Errors
// ============================================================================

print("=== CUSTOM ERRORS ===\n")

// Define an error type (enum conforming to Error)
enum APIError: Error {
    case invalidURL
    case networkTimeout
    case invalidResponse
    case decodingFailed
}

enum ValidationError: Error {
    case emptyString
    case invalidEmail
    case weakPassword
}

// Custom error with associated values
enum PaymentError: Error {
    case insufficientFunds(required: Double, available: Double)
    case invalidCard(reason: String)
    case transactionFailed(message: String)
}


// SECTION 2: Throwing Functions
// ============================================================================

print("=== THROWING FUNCTIONS ===\n")

// ✅ Function that throws an error
func validateEmail(_ email: String) throws -> String {
    if email.isEmpty {
        throw ValidationError.emptyString
    }
    if !email.contains("@") {
        throw ValidationError.invalidEmail
    }
    return email
}

// ✅ Function that throws with specific errors
func processPayment(amount: Double, cardNumber: String, userBalance: Double) throws -> String {
    if cardNumber.count != 16 {
        throw PaymentError.invalidCard(reason: "Card number must be 16 digits")
    }
    if amount > userBalance {
        throw PaymentError.insufficientFunds(required: amount, available: userBalance)
    }
    return "✓ Payment processed: $\(amount)"
}


// SECTION 3: Handling Errors - WRONG vs CORRECT
// ============================================================================

print("=== ERROR HANDLING: WRONG vs CORRECT ===\n")

// ❌ WRONG 1: Using try! (will crash if error is thrown)
print("❌ WRONG 1: Using try! (crashes on error)")
// let email = try! validateEmail("")  // ⚠️ CRASH if validation fails!
print("(Skipped try! to prevent crash)")

// ✅ CORRECT 1: Using do-catch
print("✅ CORRECT 1: Using do-catch")
do {
    let validEmail = try validateEmail("user@example.com")
    print("Valid email: \(validEmail)")
} catch ValidationError.emptyString {
    print("Error: Email cannot be empty")
} catch ValidationError.invalidEmail {
    print("Error: Invalid email format")
} catch {
    print("Unknown error: \(error)")
}

// ✅ CORRECT 2: Catching specific errors
print("\n✅ CORRECT 2: Catching specific errors")
do {
    let validEmail = try validateEmail("")
} catch let error as ValidationError {
    switch error {
    case .emptyString:
        print("Caught: Email is empty")
    case .invalidEmail:
        print("Caught: Invalid email")
    case .weakPassword:
        print("Caught: Weak password")
    }
} catch {
    print("Other error occurred")
}

// ✅ CORRECT 3: Using try? (returns optional)
print("\n✅ CORRECT 3: Using try? (returns optional)")
let maybeEmail = try? validateEmail("invalid-email")
if let email = maybeEmail {
    print("Email was validated: \(email)")
} else {
    print("Email validation failed")
}

// ✅ CORRECT 4: Complex error handling with associated values
print("\n✅ CORRECT 4: Handling errors with associated values")
do {
    let receipt = try processPayment(amount: 150, cardNumber: "1234567890123456", userBalance: 100)
    print(receipt)
} catch PaymentError.insufficientFunds(let required, let available) {
    print("Error: Need $\(required), but only have $\(available)")
} catch PaymentError.invalidCard(let reason) {
    print("Error: Invalid card - \(reason)")
} catch PaymentError.transactionFailed(let message) {
    print("Error: Transaction failed - \(message)")
} catch {
    print("Unexpected error: \(error)")
}


// SECTION 4: Propagating Errors
// ============================================================================

print("\n=== ERROR PROPAGATION ===\n")

// Function that propagates errors from other functions
func registerUser(email: String, password: String) throws {
    // Errors from validateEmail will propagate up
    let _ = try validateEmail(email)
    
    if password.count < 8 {
        throw ValidationError.weakPassword
    }
    
    print("✓ User registered: \(email)")
}

// ✅ Handling propagated errors
do {
    try registerUser(email: "user@example.com", password: "short")
} catch ValidationError.weakPassword {
    print("Error: Password must be at least 8 characters")
} catch ValidationError.invalidEmail {
    print("Error: Invalid email")
} catch {
    print("Registration failed: \(error)")
}


// SECTION 5: Common Mistakes (Anti-patterns)
// ============================================================================

print("\n=== COMMON MISTAKES ===\n")

// ❌ MISTAKE 1: Using try! in production code
print("❌ MISTAKE 1: Using try! in production")
func unsafeFunction() {
    // let result = try! validateEmail("")  // ⚠️ WILL CRASH if error occurs!
    print("(Skipped try! example)")
}

// ✅ FIX: Use do-catch or try?
print("✅ FIX: Use do-catch or try?")
let result = try? validateEmail("test@example.com")
print("Result: \(result ?? "Error occurred")")

// ❌ MISTAKE 2: Not handling all error cases
print("\n❌ MISTAKE 2: Incomplete error handling")
func incompleteCatch() {
    do {
        try validateEmail("invalid")
    } catch ValidationError.emptyString {
        print("Empty string")
    }
    // ⚠️ Other errors (like invalidEmail) are silently ignored!
}

// ✅ FIX: Use a catch-all or handle all cases
print("✅ FIX: Complete error handling")
do {
    try validateEmail("invalid")
} catch let error as ValidationError {
    print("Validation error: \(error)")
} catch {
    print("Other error: \(error)")
}

// ❌ MISTAKE 3: Swallowing errors with try?
print("\n❌ MISTAKE 3: Over-using try? without handling failure")
let email1 = try? validateEmail("")
if email1 == nil {
    print("⚠️ Email validation failed, but we don't know why!")
}

// ✅ FIX: Use do-catch when you need to know the error
print("✅ FIX: Use do-catch for better diagnostics")
do {
    let email2 = try validateEmail("")
} catch ValidationError.emptyString {
    print("Specifically caught: Email is empty")
} catch {
    print("Other validation error")
}

// ❌ MISTAKE 4: Ignoring errors completely
print("\n❌ MISTAKE 4: Ignoring errors with _ = try?")
_ = try? validateEmail("")
print("⚠️ Error was silently ignored")

// ✅ FIX: Acknowledge errors explicitly
print("✅ FIX: Explicit error handling")
if (try? validateEmail("")) != nil {
    print("✓ Validation succeeded")
} else {
    print("✗ Validation failed - handling accordingly")
}


// SECTION 6: Best Practices
// ============================================================================

print("\n=== BEST PRACTICES ===\n")

// ✅ PRACTICE 1: Define specific error types
print("✅ PRACTICE 1: Specific error types")
enum DatabaseError: Error, LocalizedError {
    case connectionFailed
    case querySyntaxError(query: String)
    case recordNotFound(id: Int)
    
    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Cannot connect to database"
        case .querySyntaxError(let query):
            return "Invalid query: \(query)"
        case .recordNotFound(let id):
            return "Record with ID \(id) not found"
        }
    }
}

// ✅ PRACTICE 2: Use LocalizedError for user-facing errors
print("✅ PRACTICE 2: LocalizedError for users")
do {
    throw DatabaseError.recordNotFound(id: 42)
} catch let error as DatabaseError {
    print("User message: \(error.errorDescription ?? "Unknown error")")
}

// ✅ PRACTICE 3: Document what errors can be thrown
print("\n✅ PRACTICE 3: Document throwing behavior")
/// Validates a password against strength requirements
/// - Parameter password: The password to validate
/// - Throws: ValidationError.weakPassword if less than 8 characters
/// - Returns: The validated password
func validatePassword(_ password: String) throws -> String {
    if password.count < 8 {
        throw ValidationError.weakPassword
    }
    return password
}

// ✅ PRACTICE 4: Clean up resources with defer
print("\n✅ PRACTICE 4: Using defer for cleanup")
func processFileWithCleanup(filename: String) throws {
    print("Opening file: \(filename)")
    defer {
        print("Closing file: \(filename)")
    }
    
    if filename.isEmpty {
        throw ValidationError.emptyString
    }
    
    print("Processing file...")
}

do {
    try processFileWithCleanup(filename: "data.txt")
} catch {
    print("Error: \(error)")
}

// ✅ PRACTICE 5: Chain multiple error-throwing operations
print("\n✅ PRACTICE 5: Chaining error-throwing operations")
func completeUserSetup(email: String, password: String) throws {
    try validateEmail(email)
    try validatePassword(password)
    try registerUser(email: email, password: password)
    print("✓ Complete setup finished")
}

do {
    try completeUserSetup(email: "new@example.com", password: "SecurePass123")
} catch {
    print("Setup failed: \(error)")
}


// SECTION 7: Error Handling with Optionals
// ============================================================================

print("\n=== ERRORS vs OPTIONALS ===\n")

// ❌ WRONG: Using optional instead of error
func findUserWrong(id: Int) -> String? {
    if id <= 0 {
        return nil  // ⚠️ Caller doesn't know WHY it failed
    }
    return "User-\(id)"
}

// ✅ CORRECT: Using error for more information
func findUserCorrect(id: Int) throws -> String {
    if id <= 0 {
        throw DatabaseError.recordNotFound(id: id)
    }
    return "User-\(id)"
}

print("❌ WRONG: findUserWrong(id: -1) returns \(findUserWrong(id: -1))")
print("✅ CORRECT: findUserCorrect provides detailed error information")
do {
    let user = try findUserCorrect(id: 1)
    print("Found: \(user)")
} catch DatabaseError.recordNotFound(let id) {
    print("Specific error: Record \(id) not found")
}


print("\n=== END OF ERROR HANDLING PLAYGROUND ===")
