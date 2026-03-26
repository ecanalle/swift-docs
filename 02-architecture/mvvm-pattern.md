# MVVM Pattern - Modern Architecture

## Overview

MVVM (Model-View-ViewModel) separates business logic from UI. The ViewModel handles state and user interactions while the View displays data.

## Main Topics

- [MVVM Architecture](#mvvm-architecture)
- [Data Binding](#data-binding)
- [State Management](#state-management)
- [Testing MVVM](#testing-mvvm)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

---

## MVVM Architecture

### Basic MVVM Structure

```swift
import Foundation

// MARK: - Model
struct User {
    let id: Int
    let name: String
    let email: String
}

// MARK: - ViewModel
@MainActor
class UserViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userService: UserService
    
    init(userService: UserService = .shared) {
        self.userService = userService
    }
    
    func loadUser(id: Int) async {
        isLoading = true
        errorMessage = nil
        
        do {
            user = try await userService.fetchUser(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func updateUser(_ user: User) async {
        do {
            let updated = try await userService.updateUser(user)
            self.user = updated
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Service (Repository)
class UserService {
    static let shared = UserService()
    
    func fetchUser(id: Int) async throws -> User {
        // Simulated network call
        return User(id: id, name: "Alice", email: "alice@example.com")
    }
    
    func updateUser(_ user: User) async throws -> User {
        // Save to server
        return user
    }
}

// MARK: - View
import SwiftUI

struct UserView: View {
    @StateObject private var viewModel = UserViewModel()
    
    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else if let user = viewModel.user {
            VStack {
                Text(user.name)
                    .font(.title)
                Text(user.email)
                    .font(.body)
            }
        } else if let error = viewModel.errorMessage {
            Text("Error: \(error)")
                .foregroundColor(.red)
        }
    }
}
```

---

## Data Binding

### Two-Way Binding

```swift
import SwiftUI

@MainActor
class EditViewModel: ObservableObject {
    @Published var formText = ""
    @Published var isSaved = false
    
    func saveForm() {
        // Process form
        isSaved = true
    }
}

struct EditView: View {
    @StateObject private var viewModel = EditViewModel()
    
    var body: some View {
        VStack {
            TextField("Enter text", text: $viewModel.formText)
            
            Button("Save") {
                viewModel.saveForm()
            }
            
            if viewModel.isSaved {
                Text("Saved successfully")
                    .foregroundColor(.green)
            }
        }
    }
}
```

### Complex Binding

```swift
import SwiftUI

@MainActor
class FormViewModel: ObservableObject {
    @Published var firstName = ""
    @Published var lastName = ""
    @Published var isFormValid = false
    
    init() {
        // Validate on change
        $firstName
            .combineLatest($lastName)
            .map { !$0.isEmpty && !$1.isEmpty }
            .assign(to: &$isFormValid)
    }
}
```

---

## State Management

### Managing Complex State

```swift
import Foundation

@MainActor
class TodoListViewModel: ObservableObject {
    @Published var todos: [Todo] = []
    @Published var isLoading = false
    @Published var selectedFilter: TodoFilter = .all
    
    enum TodoFilter {
        case all
        case active
        case completed
    }
    
    var filteredTodos: [Todo] {
        switch selectedFilter {
        case .all:
            return todos
        case .active:
            return todos.filter { !$0.isCompleted }
        case .completed:
            return todos.filter { $0.isCompleted }
        }
    }
    
    func loadTodos() async {
        isLoading = true
        // Fetch todos
        isLoading = false
    }
    
    func addTodo(_ todo: Todo) {
        todos.append(todo)
    }
    
    func toggleTodo(_ todo: Todo) {
        if let index = todos.firstIndex(where: { $0.id == todo.id }) {
            todos[index].isCompleted.toggle()
        }
    }
    
    func deleteTodo(_ todo: Todo) {
        todos.removeAll { $0.id == todo.id }
    }
}

struct Todo: Identifiable {
    let id: Int
    var title: String
    var isCompleted: Bool
}
```

---

## Testing MVVM

### ViewModel Testing

```swift
import XCTest

@testable import MyApp

class UserViewModelTests: XCTestCase {
    var viewModel: UserViewModel!
    var mockService: MockUserService!
    
    override func setUp() {
        super.setUp()
        mockService = MockUserService()
        viewModel = UserViewModel(userService: mockService)
    }
    
    func testLoadUserSuccess() async {
        let user = User(id: 1, name: "Alice", email: "alice@example.com")
        mockService.mockUser = user
        
        await viewModel.loadUser(id: 1)
        
        XCTAssertEqual(viewModel.user, user)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
    
    func testLoadUserError() async {
        mockService.shouldFail = true
        
        await viewModel.loadUser(id: 1)
        
        XCTAssertNil(viewModel.user)
        XCTAssertNotNil(viewModel.errorMessage)
    }
}

class MockUserService: UserService {
    var mockUser: User?
    var shouldFail = false
    
    override func fetchUser(id: Int) async throws -> User {
        if shouldFail {
            throw NSError(domain: "Mock", code: -1)
        }
        return mockUser ?? User(id: id, name: "Mock", email: "mock@example.com")
    }
}
```

---

## 🎯 Best Practices

### 1. Keep ViewModel Testable
```swift
// ✅ Inject dependencies
class UserViewModel {
    let service: UserService
    init(service: UserService = .shared) {
        self.service = service
    }
}

// ❌ Hard-coded dependencies
class UserViewModel {
    let service = UserService.shared
}
```

### 2. Use @Published for State
```swift
// ✅ Observable properties
@Published var user: User?

// ❌ Non-observable variables
var user: User?  // Won't update UI
```

### 3. Separate Logic from UI
```swift
// ✅ Business logic in ViewModel
class UserViewModel {
    func validateEmail(_ email: String) -> Bool {
        email.contains("@")
    }
}

// ❌ Logic in View
struct UserView: View {
    func validateEmail() { }
}
```

---

## ❌ Common Mistakes

### Mistake 1: Tight Coupling

**WRONG:**
```swift
// ❌ Hard-coded service
class UserViewModel {
    let service = UserService.shared
    
    func loadUser() {
        service.fetchUser()  // Can't mock for testing
    }
}
```

**CORRECT:**
```swift
// ✅ Injected dependency
class UserViewModel {
    let service: UserService
    
    init(service: UserService = .shared) {
        self.service = service
    }
}
```

---

### Mistake 2: Too Much Logic in View

**WRONG:**
```swift
// ❌ Complex logic in View
struct UserView: View {
    @State var isLoading = false
    
    var body: some View {
        if isLoading {
            // Fetch data
            // Process data
            // Validate data
        }
    }
}
```

**CORRECT:**
```swift
// ✅ Logic in ViewModel
class UserViewModel: ObservableObject {
    @Published var isLoading = false
    func loadData() { }
}

struct UserView: View {
    @StateObject var viewModel = UserViewModel()
}
```

---

## Related Topics

- [SwiftUI Basics](../05-features/swiftui-basics.md)
- [Dependency Injection](../02-architecture/dependency-injection.md)
- [Unit Testing](../03-testing/unit-testing.md)

---

**Build scalable apps with MVVM!**
