# SwiftData - Modern Persistence

## Overview

SwiftData (iOS 17+) is Apple's modern replacement for Core Data, providing a lighter, more intuitive API built on top of SwiftUI. It simplifies persistence with a declarative approach using macros and observable models.

## Main Topics

- [SwiftData Concepts](#swiftdata-concepts)
- [Model Definitions](#model-definitions)
- [CRUD Operations](#crud-operations)
- [Queries](#queries)
- [Relationships](#relationships)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)

---

## SwiftData Concepts

### SwiftData vs Core Data

```swift
// ❌ Core Data - Complex setup
let container = NSPersistentContainer(name: "Model")
container.loadPersistentStores { }
let context = container.viewContext

// ✅ SwiftData - Minimal setup
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: User.self)
    }
}
```

### SwiftData Stack

```swift
// 1. Define models with @Model
@Model
final class User {
    var name: String
    var email: String
}

// 2. Add to app with .modelContainer
// 3. Query with @Query
// 4. Save automatically
```

---

## Model Definitions

### Basic Model

```swift
import SwiftData

@Model
final class Todo {
    var title: String
    var description: String?
    var isCompleted: Bool = false
    var dueDate: Date?
    var priority: Int = 1
    
    init(title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }
}
```

### Model with ID

```swift
@Model
final class Product {
    @Attribute(.unique) var id: UUID
    var name: String
    var price: Double
    var inStock: Bool = true
    
    init(id: UUID = UUID(), name: String, price: Double) {
        self.id = id
        self.name = name
        self.price = price
    }
}
```

### Ignored Properties

```swift
@Model
final class User {
    var name: String
    var email: String
    
    // ✅ Won't be persisted
    @Transient var isLoggedIn: Bool = false
    @Transient var cachedData: [String] = []
}
```

### Computed Properties

```swift
@Model
final class Order {
    var items: [OrderItem] = []
    var taxRate: Double = 0.1
    
    // ✅ Computed - not stored
    var subtotal: Double {
        items.reduce(0) { $0 + $1.price * Double($1.quantity) }
    }
    
    var tax: Double {
        subtotal * taxRate
    }
    
    var total: Double {
        subtotal + tax
    }
}

@Model
final class OrderItem {
    var name: String
    var price: Double
    var quantity: Int
}
```

---

## CRUD Operations

### Create (Insert)

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: User.self)
    }
}

struct CreateUserView: View {
    @Environment(\.modelContext) var modelContext
    @State var name = ""
    
    var body: some View {
        VStack {
            TextField("Name", text: $name)
            
            Button("Save") {
                let user = User(name: name)
                modelContext.insert(user)
                
                try? modelContext.save()
            }
        }
    }
}
```

### Read (Query)

```swift
struct ContentView: View {
    @Query var users: [User]  // Auto-updates
    
    var body: some View {
        List {
            ForEach(users) { user in
                Text(user.name)
            }
        }
    }
}

// With sorting/filtering
struct SortedUsersView: View {
    @Query(sort: \.name, order: .forward)
    var users: [User]
    
    var body: some View {
        List(users) { user in
            Text(user.name)
        }
    }
}
```

### Update (Modify)

```swift
struct EditUserView: View {
    @Environment(\.modelContext) var modelContext
    @State var user: User
    @State var newName = ""
    
    var body: some View {
        VStack {
            TextField("Name", text: $newName)
            
            Button("Update") {
                user.name = newName
                try? modelContext.save()
            }
        }
        .onAppear {
            newName = user.name
        }
    }
}
```

### Delete (Remove)

```swift
struct UserListView: View {
    @Query var users: [User]
    @Environment(\.modelContext) var modelContext
    
    var body: some View {
        List {
            ForEach(users) { user in
                Text(user.name)
            }
            .onDelete { indexSet in
                for index in indexSet {
                    modelContext.delete(users[index])
                }
                try? modelContext.save()
            }
        }
    }
}
```

---

## Queries

### Basic Query

```swift
struct UserListView: View {
    // Get all users
    @Query var allUsers: [User]
    
    var body: some View {
        List(allUsers) { user in
            Text(user.name)
        }
    }
}
```

### Query with Predicate

```swift
struct ActiveUsersView: View {
    // Only users where isActive == true
    @Query(filter: #Predicate<User> { $0.isActive == true })
    var activeUsers: [User]
    
    var body: some View {
        List(activeUsers) { user in
            Text(user.name)
        }
    }
}

struct SearchUsersView: View {
    @State var searchText = ""
    
    @Query
    var users: [User]
    
    var filteredUsers: [User] {
        if searchText.isEmpty {
            return users
        }
        return users.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        List(filteredUsers) { user in
            Text(user.name)
        }
        .searchable(text: $searchText, prompt: "Search users")
    }
}
```

### Query with Sort

```swift
struct SortedTodosView: View {
    // Sort by dueDate ascending
    @Query(sort: \.dueDate, order: .forward)
    var todos: [Todo]
    
    var body: some View {
        List(todos) { todo in
            Text(todo.title)
            Text(todo.dueDate?.formatted() ?? "No date")
        }
    }
}

// Multiple sort descriptors
@Query(sort: [SortDescriptor(\.priority, order: .reverse), 
              SortDescriptor(\.dueDate, order: .forward)])
var prioritizedTodos: [Todo]
```

---

## Relationships

### One-to-Many

```swift
@Model
final class Author {
    var name: String
    @Relationship(deleteRule: .cascade, inverse: \.author)
    var books: [Book] = []
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class Book {
    var title: String
    var author: Author?
    
    init(title: String, author: Author? = nil) {
        self.title = title
        self.author = author
    }
}

// Usage
let author = Author(name: "J.K. Rowling")
let book = Book(title: "Harry Potter", author: author)
```

### Many-to-Many

```swift
@Model
final class Student {
    var name: String
    @Relationship(deleteRule: .cascade)
    var courses: [Course] = []
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class Course {
    var name: String
    var students: [Student] = []
    
    init(name: String) {
        self.name = name
    }
}
```

### Cascade Delete

```swift
@Model
final class Team {
    var name: String
    // Deleting Team automatically deletes all Members
    @Relationship(deleteRule: .cascade)
    var members: [TeamMember] = []
    
    init(name: String) {
        self.name = name
    }
}

@Model
final class TeamMember {
    var name: String
}
```

---

## 🎯 Best Practices

### 1. Use @Model Consistently
```swift
// ✅ Clear persistence model
@Model
final class User {
    var name: String
}

// ❌ Mix of persistent/transient unclear
class UserData {
    // What gets persisted?
}
```

### 2. Handle Relationships Carefully
```swift
// ✅ Explicit cascade rules
@Relationship(deleteRule: .cascade)
var children: [Child]

// ❌ Implicit deletion behavior
var children: [Child]
```

### 3. Use @Transient for Computed Values
```swift
// ✅ Clear intent
@Transient var displayName: String { }

// ❌ Uncertain if persisted
var displayName: String { }
```

### 4. Save After Changes
```swift
// ✅ Explicit save
try? modelContext.save()

// ❌ Assuming auto-save
modelContext.insert(item)
// Hope it's saved?
```

---

## ❌ Common Mistakes

### Mistake 1: Forgetting @Model

**WRONG:**
```swift
// ❌ Won't work with SwiftData
class User {
    var name: String
}
```

**CORRECT:**
```swift
// ✅ Mark as model
@Model
final class User {
    var name: String
}
```

---

### Mistake 2: Not Saving Changes

**WRONG:**
```swift
// ❌ Changes lost
user.name = "Updated"
// Forgot to save
```

**CORRECT:**
```swift
// ✅ Explicit save
user.name = "Updated"
try? modelContext.save()
```

---

## Related Topics

- [Core Data](core-data.md)
- [FileManager](filemanager.md)
- [SwiftUI Integration](../../05-features/siri-and-app-intents/swiftui-basics.md)

---

**Use SwiftData for modern, declarative persistence in iOS 17+!**
