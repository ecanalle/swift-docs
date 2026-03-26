# CloudKit - iCloud Synchronization

## Overview

CloudKit enables synchronization of app data across user devices via iCloud. It handles cloud storage, sharing, and sync automatically.

## Main Topics

- [Container Setup](#container-setup)
- [CRUD Operations](#crud-operations)
- [Querying Data](#querying-data)
- [Sync and Subscriptions](#sync-and-subscriptions)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [CloudKit](https://developer.apple.com/documentation/cloudkit)

---

## Container Setup

### Configuring CloudKit

```swift
import CloudKit

class CloudKitManager {
    static let shared = CloudKitManager()
    
    let container = CKContainer.default()
    var database: CKDatabase {
        return container.privateCloudDatabase
    }
    
    func checkiCloudStatus() async throws -> Bool {
        do {
            let status = try await container.accountStatus()
            switch status {
            case .available:
                print("iCloud available")
                return true
            case .couldNotDetermine:
                print("Could not determine iCloud status")
                return false
            case .noAccount:
                print("No iCloud account")
                return false
            case .restricted:
                print("iCloud access restricted")
                return false
            @unknown default:
                return false
            }
        } catch {
            print("iCloud status error: \(error)")
            throw error
        }
    }
    
    func getUserIdentity() async throws -> CKUserIdentity {
        let userRecord = try await container.userRecordID()
        return try await container.userIdentity(forUserRecordID: userRecord)
    }
}
```

---

## CRUD Operations

### Creating Records

```swift
import CloudKit

class CloudKitRecordManager {
    let database = CKContainer.default().privateCloudDatabase
    
    struct Note {
        let id: String
        let title: String
        let content: String
        let createdAt: Date
    }
    
    func createNote(_ note: Note) async throws {
        let record = CKRecord(recordType: "Note")
        record["title"] = note.title as CKRecordValue
        record["content"] = note.content as CKRecordValue
        record["createdAt"] = note.createdAt as CKRecordValue
        
        let savedRecord = try await database.save(record)
        print("Note saved with ID: \(savedRecord.recordID)")
    }
    
    func createNoteWithReference(title: String, content: String, userID: CKRecord.ID) async throws {
        let record = CKRecord(recordType: "Note")
        record["title"] = title as CKRecordValue
        record["content"] = content as CKRecordValue
        record["createdAt"] = Date() as CKRecordValue
        
        let userReference = CKRecord.Reference(recordID: userID, action: .deleteSelf)
        record["user"] = userReference
        
        try await database.save(record)
    }
}

// Usage
async {
    let manager = CloudKitRecordManager()
    let note = CloudKitRecordManager.Note(
        id: UUID().uuidString,
        title: "My Note",
        content: "Content here",
        createdAt: Date()
    )
    try await manager.createNote(note)
}
```

### Reading Records

```swift
import CloudKit

class CloudKitReader {
    let database = CKContainer.default().privateCloudDatabase
    
    func fetchRecord(withID recordID: CKRecord.ID) async throws -> CKRecord {
        return try await database.record(for: recordID)
    }
    
    func fetchAllNotes() async throws -> [CKRecord] {
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        
        return result.matchResults.compactMap { _, result in
            switch result {
            case .success(let record):
                return record
            case .failure:
                return nil
            }
        }
    }
    
    func fetchNotesByTitle(_ title: String) async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "title CONTAINS %@", title)
        let query = CKQuery(recordType: "Note", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let result = try await database.records(matching: query)
        
        return result.matchResults.compactMap { _, result in
            switch result {
            case .success(let record):
                return record
            case .failure:
                return nil
            }
        }
    }
}
```

### Updating Records

```swift
import CloudKit

class CloudKitUpdater {
    let database = CKContainer.default().privateCloudDatabase
    
    func updateNote(recordID: CKRecord.ID, title: String, content: String) async throws {
        let record = try await database.record(for: recordID)
        record["title"] = title as CKRecordValue
        record["content"] = content as CKRecordValue
        
        try await database.save(record)
    }
}
```

### Deleting Records

```swift
import CloudKit

class CloudKitDeleter {
    let database = CKContainer.default().privateCloudDatabase
    
    func deleteNote(recordID: CKRecord.ID) async throws {
        try await database.deleteRecord(withID: recordID)
    }
    
    func deleteAllNotes() async throws {
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query)
        
        for result in result.matchResults {
            if case .success(let record) = result.result {
                try await database.deleteRecord(withID: record.recordID)
            }
        }
    }
}
```

---

## Querying Data

### Advanced Queries

```swift
import CloudKit

class AdvancedQueries {
    let database = CKContainer.default().privateCloudDatabase
    
    func queryWithFilters() async throws -> [CKRecord] {
        let predicate = NSPredicate(format: "createdAt > %@ AND title CONTAINS %@", 
                                   Date().addingTimeInterval(-7*24*3600) as NSDate, 
                                   "Important")
        
        let query = CKQuery(recordType: "Note", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let result = try await database.records(matching: query, inZoneWith: nil, desiredKeys: ["title", "content"])
        
        return result.matchResults.compactMap { _, result in
            switch result {
            case .success(let record):
                return record
            case .failure:
                return nil
            }
        }
    }
    
    func queryWithLimit() async throws -> [CKRecord] {
        let query = CKQuery(recordType: "Note", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let configuration = CKQuery.RequestConfiguration()
        configuration.resultsLimit = 25
        
        let result = try await database.records(matching: query, inZoneWith: nil, desiredKeys: nil, matchesIn: configuration)
        
        return result.matchResults.compactMap { _, result in
            switch result {
            case .success(let record):
                return record
            case .failure:
                return nil
            }
        }
    }
}
```

---

## Sync and Subscriptions

### Observing Changes

```swift
import CloudKit

class CloudKitSubscriber {
    let database = CKContainer.default().privateCloudDatabase
    let container = CKContainer.default()
    
    func subscribeToRecordChanges() async throws {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(recordType: "Note", predicate: predicate, subscriptionID: "noteChanges", options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion])
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        try await database.save(subscription)
        print("Subscribed to Note changes")
    }
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) async throws {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        if let queryNotification = notification as? CKQueryNotification {
            print("Record changed: \(queryNotification.recordID?.recordName ?? "unknown")")
            
            // Fetch updated record
            if let recordID = queryNotification.recordID {
                let record = try await database.record(for: recordID)
                print("Updated: \(record)")
            }
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Check iCloud Status First
```swift
// ✅ Verify iCloud is available
let available = try await CloudKitManager.shared.checkiCloudStatus()
if available {
    // Safe to use CloudKit
}

// ❌ Assume iCloud is available
try await database.save(record)  // May fail
```

### 2. Handle Errors Gracefully
```swift
// ✅ Catch and handle CloudKit errors
do {
    try await database.save(record)
} catch {
    print("CloudKit error: \(error)")
    // Handle error
}

// ❌ Ignore errors
try? database.save(record)
```

### 3. Use Batch Operations
```swift
// ✅ Batch operations for efficiency
let records = [record1, record2, record3]
let operation = CKModifyRecordsOperation(recordsToSave: records)

// ❌ Save records one by one
for record in records {
    try await database.save(record)
}
```

---

## ❌ Common Mistakes

### Mistake 1: Not Checking iCloud Account

**WRONG:**
```swift
// ❌ No account check
try await database.save(record)
// Fails if user not signed into iCloud
```

**CORRECT:**
```swift
// ✅ Check first
let available = try await CloudKitManager.shared.checkiCloudStatus()
if available {
    try await database.save(record)
}
```

---

### Mistake 2: Ignoring Network Errors

**WRONG:**
```swift
// ❌ No error handling
try? database.save(record)
```

**CORRECT:**
```swift
// ✅ Handle network failures
do {
    try await database.save(record)
} catch let error as CKError {
    switch error.code {
    case .networkFailure:
        print("Network error - retry later")
    case .serviceUnavailable:
        print("Service unavailable")
    default:
        print("CloudKit error: \(error)")
    }
}
```

---

## Related Topics

- [Core Data](../06-data/core-data.md)
- [SwiftData](../06-data/swiftdata.md)
- [UserDefaults - Preferences](userdefaults.md)

---

**Sync data across devices with CloudKit!**
