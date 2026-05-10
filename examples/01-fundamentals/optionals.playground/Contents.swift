import Foundation

// ============================================================================
// OPTIONALS IN SWIFT - Complete Playground Guide
// Corresponds to: 01-fundamentals/fundamentals/optionals.md
// ============================================================================

// SECTION 1: Optional Basics
// ============================================================================

print("=== OPTIONAL BASICS ===\n")

// Creating optionals - explicit way
let explicitOptional: Optional<Int> = nil
let explicitOptionalValue: Optional<String> = "Hello"

// Creating optionals - shorthand (most common)
let implicitOptional: Int? = nil
let implicitOptionalValue: String? = "World"

print("Explicit optional (nil): \(explicitOptional)")
print("Explicit optional (value): \(explicitOptionalValue)")
print("Implicit optional (nil): \(implicitOptional)")
print("Implicit optional (value): \(implicitOptionalValue)")


// SECTION 2: Unwrapping Optionals - WRONG vs CORRECT
// ============================================================================

print("\n=== UNWRAPPING: WRONG vs CORRECT ===\n")

let userAge: Int? = 25
let userName: String? = nil

// ❌ WRONG - Force unwrapping without checking (will crash if nil)
print("❌ WRONG: Force unwrapping")
// let age = userAge!  // ⚠️ Dangerous! Would crash if userAge was nil
// print("User age: \(age)")

// ✅ CORRECT 1: Optional Binding (if-let)
print("✅ CORRECT 1: Optional Binding (if-let)")
if let age = userAge {
    print("User age is \(age)")
} else {
    print("Age is not available")
}

// ✅ CORRECT 2: Optional Binding (guard-let)
print("✅ CORRECT 2: Optional Binding (guard-let)")
func displayUserAge(_ age: Int?) {
    guard let age = age else {
        print("Age information is unavailable")
        return
    }
    print("User is \(age) years old")
}
displayUserAge(userAge)
displayUserAge(nil)

// ✅ CORRECT 3: Nil-coalescing operator (??)
print("✅ CORRECT 3: Nil-coalescing operator")
let displayAge = userAge ?? 0
print("Age to display: \(displayAge)")

// ✅ CORRECT 4: Optional chaining
print("✅ CORRECT 4: Optional chaining")
class User {
    var profile: UserProfile?
}

class UserProfile {
    var bio: String = "No bio available"
}

let user: User? = User()
user?.profile?.bio = "I love Swift!"
print("Bio: \(user?.profile?.bio ?? "No bio")")


// SECTION 3: Multiple Optional Handling
// ============================================================================

print("\n=== MULTIPLE OPTIONALS ===\n")

let firstName: String? = "John"
let lastName: String? = "Doe"
let email: String? = nil

// ❌ WRONG: Multiple nested if-let (hard to read)
print("❌ WRONG: Nested if-let")
if let first = firstName {
    if let last = lastName {
        if let mail = email {
            print("Name: \(first) \(last), Email: \(mail)")
        }
    }
}

// ✅ CORRECT: Combined if-let (cleaner)
print("✅ CORRECT: Combined if-let")
if let first = firstName, let last = lastName, let mail = email {
    print("Name: \(first) \(last), Email: \(mail)")
} else {
    print("Some user information is missing")
}

// ✅ ALTERNATIVE: guard-let with early return
print("✅ ALTERNATIVE: guard-let")
func displayUserInfo(first: String?, last: String?, email: String?) {
    guard let first = first, let last = last, let email = email else {
        print("Incomplete user data")
        return
    }
    print("Full info: \(first) \(last) <\(email)>")
}
displayUserInfo(first: firstName, last: lastName, email: email)


// SECTION 4: Map and CompactMap on Optionals
// ============================================================================

print("\n=== MAP AND COMPACTMAP ===\n")

let optionalNumber: Int? = 42

// ✅ map - applies closure only if optional has value
let doubled = optionalNumber.map { $0 * 2 }
print("Map result (42 * 2): \(doubled)") // Optional(84)

let nilNumber: Int? = nil
let mappedNil = nilNumber.map { $0 * 2 }
print("Map on nil: \(mappedNil)") // nil

// Using map with strings
let optionalString: String? = "SWIFT"
let lowercased = optionalString.map { $0.lowercased() }
print("Lowercased optional string: \(lowercased)") // Optional("swift")


// SECTION 5: Common Mistakes (Anti-patterns)
// ============================================================================

print("\n=== COMMON MISTAKES ===\n")

// ❌ MISTAKE 1: Force unwrapping in production code
print("❌ MISTAKE 1: Force unwrapping")
let riskValue: String? = "Risk"
// let forced = riskValue! // ⚠️ Would crash if nil - DON'T DO THIS IN PRODUCTION
// print("Forced: \(forced)")
print("(Skipped force unwrap to prevent crash)")

// ✅ FIX: Use optional binding instead
if let safe = riskValue {
    print("Safe unwrap: \(safe)")
}

// ❌ MISTAKE 2: Comparing optional with non-optional
print("\n❌ MISTAKE 2: Wrong optional comparison")
let name: String? = "Alice"
// if name == "Alice" { } // ⚠️ This compares Optional<String> with String
print("Wrong: Optional<String> == String compiles but may have unintended behavior")

// ✅ FIX: Unwrap first
if let unwrappedName = name, unwrappedName == "Alice" {
    print("Correct: Name is Alice after unwrapping")
}

// ❌ MISTAKE 3: Accessing optional in array without checking
print("\n❌ MISTAKE 3: Array of optionals")
let items: [String?] = ["Apple", nil, "Banana"]
// for item in items {
//     print(item.uppercased()) // ⚠️ Would crash on nil
// }

// ✅ FIX: Use compactMap to filter out nils
print("✅ FIX: Using compactMap")
let validItems = items.compactMap { $0 }
for item in validItems {
    print(item.uppercased())
}

// ❌ MISTAKE 4: Multiple force unwraps
print("\n❌ MISTAKE 4: Multiple force unwraps")
let a: Int? = 5
let b: Int? = nil
let c: Int? = 10
// let sum = a! + b! + c! // ⚠️ Will crash on b!
print("(Skipped multiple force unwraps)")

// ✅ FIX: Use optional binding
let sum: Int?
if let unwrappedA = a, let unwrappedB = b, let unwrappedC = c {
    sum = unwrappedA + unwrappedB + unwrappedC
} else {
    sum = nil
    print("Cannot calculate sum - some values are nil")
}


// SECTION 6: Best Practices
// ============================================================================

print("\n=== BEST PRACTICES ===\n")

// ✅ PRACTICE 1: Use explicit return types with optionals
print("✅ PRACTICE 1: Explicit optional return types")
func findUserID(username: String) -> Int? {
    // Simulated database lookup
    let users = ["alice": 1, "bob": 2, "charlie": 3]
    return users[username]
}

if let userID = findUserID(username: "alice") {
    print("Found user with ID: \(userID)")
}

// ✅ PRACTICE 2: Use guard for early returns (defensive programming)
print("\n✅ PRACTICE 2: Guard for early returns")
func processUserData(email: String?, age: Int?) {
    guard let email = email, !email.isEmpty else {
        print("Invalid email")
        return
    }
    guard let age = age, age >= 18 else {
        print("User must be 18+")
        return
    }
    print("Processing: \(email), Age: \(age)")
}

processUserData(email: "user@example.com", age: 25)
processUserData(email: nil, age: 30)
processUserData(email: "user@example.com", age: 16)

// ✅ PRACTICE 3: Document when functions can return nil
print("\n✅ PRACTICE 3: Documenting optionals in code")
/// Returns the doubled value of the input, or nil if input is nil
/// - Parameter value: An optional integer
/// - Returns: Optional integer representing value * 2, or nil if input was nil
func doubleIfPresent(_ value: Int?) -> Int? {
    return value.map { $0 * 2 }
}

// ✅ PRACTICE 4: Use nil-coalescing for defaults
print("\n✅ PRACTICE 4: Nil-coalescing for defaults")
let theme: String? = nil
let displayTheme = theme ?? "Light"
print("Current theme: \(displayTheme)")

// ✅ PRACTICE 5: Chaining optionals safely
print("\n✅ PRACTICE 5: Optional chaining")
class Company {
    var ceo: Employee?
}

class Employee {
    var name: String
    init(name: String) {
        self.name = name
    }
}

let company = Company()
company.ceo = Employee(name: "Jane")
print("CEO name: \(company.ceo?.name ?? "No CEO assigned")")


print("\n=== END OF OPTIONALS PLAYGROUND ===")
