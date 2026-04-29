# Core Data Fundamentals

## Overview

Core Data is Apple's framework for object graph management and persistence. It provides an abstraction layer over SQLite, making it easier to work with complex data while providing powerful querying and relationship management capabilities.

## Main Topics

- [Core Data Basics](#core-data-basics)
- [Creating Models](#creating-models)
- [CRUD Operations](#crud-operations)
- [Querying and Fetching](#querying-and-fetching)
- [Relationships](#relationships)
- [Performance Optimization](#performance-optimization)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [Core Data Documentation](https://developer.apple.com/documentation/coredata)
- [WWDC: Using Core Data](https://developer.apple.com/videos/play/wwdc2023/10015/)

---

## Core Data Basics

### Setting Up Core Data Stack

```swift
import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "MyApp")
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("Core Data loading error: \(error)")
            }
        }
        
        return container
    }()
    
    var mainContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext {
        return persistentContainer.newBackgroundContext()
    }
    
    func save() {
        let context = mainContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Core Data save error: \(error)")
            }
        }
    }
}
```

### Core Data Models

Define entities in `.xcdatamodeld` file or programmatically:

```swift
// User Entity
let userEntity = NSEntityDescription()
userEntity.name = "User"

let idAttribute = NSAttributeDescription()
idAttribute.name = "id"
idAttribute.attributeType = .integer32AttributeType
idAttribute.isOptional = false

let nameAttribute = NSAttributeDescription()
nameAttribute.name = "name"
nameAttribute.attributeType = .stringAttributeType
nameAttribute.isOptional = false

let emailAttribute = NSAttributeDescription()
emailAttribute.name = "email"
emailAttribute.attributeType = .stringAttributeType
emailAttribute.isOptional = true

let createdAtAttribute = NSAttributeDescription()
createdAtAttribute.name = "createdAt"
createdAtAttribute.attributeType = .dateAttributeType
createdAtAttribute.isOptional = true

userEntity.properties = [idAttribute, nameAttribute, emailAttribute, createdAtAttribute]
```

---

## Creating Models

### NSManagedObject Subclass

```swift
import CoreData

class User: NSManagedObject {
    @NSManaged var id: Int32
    @NSManaged var name: String
    @NSManaged var email: String?
    @NSManaged var createdAt: Date?
    
    static func newUser(in context: NSManagedObjectContext) -> User {
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as! User
        return user
    }
}

class Post: NSManagedObject {
    @NSManaged var id: Int32
    @NSManaged var title: String
    @NSManaged var body: String
    @NSManaged var author: User?  // Relationship
    @NSManaged var createdAt: Date?
}
```

---

## CRUD Operations

### Create

```swift
let context = CoreDataStack.shared.mainContext

// Create new user
let newUser = NSEntityDescription.insertNewObject(forEntityName: "User", into: context) as! User
newUser.id = 1
newUser.name = "John Doe"
newUser.email = "john@example.com"
newUser.createdAt = Date()

// Save to persistent store
CoreDataStack.shared.save()
```

### Read

```swift
let context = CoreDataStack.shared.mainContext

// Fetch request
let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "id == %d", 1)

do {
    let results = try context.fetch(fetchRequest)
    if let user = results.first {
        print("Found: \(user.name)")
    }
} catch {
    print("Fetch error: \(error)")
}
```

### Update

```swift
let context = CoreDataStack.shared.mainContext

let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "id == %d", 1)

do {
    let results = try context.fetch(fetchRequest)
    if let user = results.first {
        user.name = "Jane Doe"
        user.email = "jane@example.com"
        CoreDataStack.shared.save()
    }
} catch {
    print("Fetch error: \(error)")
}
```

### Delete

```swift
let context = CoreDataStack.shared.mainContext

let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "id == %d", 1)

do {
    let results = try context.fetch(fetchRequest)
    if let user = results.first {
        context.delete(user)
        CoreDataStack.shared.save()
    }
} catch {
    print("Fetch error: \(error)")
}
```

---

## Querying and Fetching

### Basic Fetch

```swift
let context = CoreDataStack.shared.mainContext
let fetchRequest: NSFetchRequest<User> = User.fetchRequest()

// Sort
let sortDescriptor = NSSortDescriptor(key: "name", ascending: true)
fetchRequest.sortDescriptors = [sortDescriptor]

// Fetch limit
fetchRequest.fetchLimit = 10

do {
    let users = try context.fetch(fetchRequest)
    print("Fetched \(users.count) users")
} catch {
    print("Fetch error: \(error)")
}
```

### Complex Predicates

```swift
let context = CoreDataStack.shared.mainContext
let fetchRequest: NSFetchRequest<User> = User.fetchRequest()

// AND condition
let predicate = NSPredicate(format: "name CONTAINS %@ AND email != nil", "John")

// OR condition
let orPredicate = NSPredicate(format: "name == %@ OR name == %@", "John", "Jane")

// IN condition
let inPredicate = NSPredicate(format: "id IN %@", [1, 2, 3])

fetchRequest.predicate = predicate

do {
    let results = try context.fetch(fetchRequest)
    print("Results: \(results.count)")
} catch {
    print("Fetch error: \(error)")
}
```

### Aggregation

```swift
let context = CoreDataStack.shared.mainContext
let fetchRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()

// Count
fetchRequest.returnsObjectsAsFaults = false
do {
    let count = try context.count(for: fetchRequest)
    print("Total users: \(count)")
} catch {
    print("Count error: \(error)")
}

// Distinct values
let distinctRequest: NSFetchRequest<NSFetchRequestResult> = User.fetchRequest()
distinctRequest.returnsDistinctResults = true
distinctRequest.resultType = .dictionaryResultType
distinctRequest.returnsObjectsAsFaults = false
```

---

## Relationships

### One-to-Many

```swift
let user = User(context: context)
user.name = "John"

// Create multiple posts
let post1 = Post(context: context)
post1.title = "First Post"
post1.author = user

let post2 = Post(context: context)
post2.title = "Second Post"
post2.author = user

CoreDataStack.shared.save()

// Fetch user's posts
let fetchRequest: NSFetchRequest<Post> = Post.fetchRequest()
fetchRequest.predicate = NSPredicate(format: "author.name == %@", "John")

do {
    let posts = try context.fetch(fetchRequest)
    print("User has \(posts.count) posts")
} catch {
    print("Error: \(error)")
}
```

### Cascading Deletes

In model editor, set Delete Rule to "Cascade" for relationships:

```swift
// When user is deleted, all related posts are also deleted
context.delete(user)
CoreDataStack.shared.save()
```

---

## Performance Optimization

### Batch Fetching

```swift
let fetchRequest: NSFetchRequest<User> = User.fetchRequest()

// Batch fetching
fetchRequest.fetchBatchSize = 100  // Fetch 100 at a time

// Returns fault objects (not fully loaded)
fetchRequest.returnsObjectsAsFaults = true

do {
    let users = try context.fetch(fetchRequest)
} catch {
    print("Error: \(error)")
}
```

### Faulting

```swift
let context = CoreDataStack.shared.mainContext

// Objects returned as faults unless accessed
let fetchRequest: NSFetchRequest<User> = User.fetchRequest()
let users = try context.fetch(fetchRequest)

// Accessing properties loads the fault
for user in users {
    print(user.name)  // Fault is loaded here
}

// Refresh without keeping relationships
context.refresh(user, mergeData: false)
```

---

## 🎯 Best Practices

### 1. Use Background Contexts for Heavy Operations
- Don't block main thread
- Use `backgroundContext` for imports

### 2. Always Catch Errors
- Save operations can fail
- Network errors affect synchronization
- Disk space issues affect persistence

### 3. Use NSFetchedResultsController for UI
- Automatically tracks changes
- Provides animatable updates
- Better performance than manual fetching

### 4. Proper Context Management
- Use main context on main thread
- Use background context on background thread
- Merge changes correctly

### 5. Profile and Optimize
- Profile fetch requests
- Check for N+1 query problems
- Use faulting appropriately

---

## ❌ Common Mistakes

### Mistake 1: Blocking Main Thread

**WRONG:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    let users = try context.fetch(fetchRequest)  // Blocks UI!
    updateUI(users)
}
```

**CORRECT:**
```swift
override func viewDidLoad() {
    super.viewDidLoad()
    DispatchQueue.global(qos: .userInitiated).async {
        if let users = try context.fetch(fetchRequest) {
            DispatchQueue.main.async {
                self.updateUI(users)
            }
        }
    }
}
```

---

### Mistake 2: Ignoring Save Errors

**WRONG:**
```swift
try? context.save()  // Silently fails
```

**CORRECT:**
```swift
do {
    try context.save()
} catch {
    print("Save error: \(error)")
    // Show error to user
}
```

---

### Mistake 3: Using Main Context Everywhere

**WRONG:**
```swift
func importLargeDataset(_ data: [User]) {
    for userData in data {
        let user = User(context: mainContext)
        // Create millions of objects on main thread!
    }
}
```

**CORRECT:**
```swift
func importLargeDataset(_ data: [User]) {
    let backgroundContext = coreDataStack.backgroundContext
    backgroundContext.perform {
        for userData in data {
            let user = User(context: backgroundContext)
            user.id = userData.id
            // Doesn't block UI
        }
        try? backgroundContext.save()
    }
}
```

---

## Related Topics

- [CloudKit](../../06-data/cloudkit-advanced.md)
- [Database Design](../../02-architecture/database-design.md)
- [Data Synchronization](../../05-features/data-sync.md)

---

**Master Core Data to build robust data-driven apps!**
