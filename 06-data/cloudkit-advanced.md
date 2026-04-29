# CloudKit Advanced 🌐

## Overview

CloudKit is Apple's cloud database service that enables seamless synchronization of app data across all user devices. This guide covers advanced patterns for production-grade CloudKit implementations including conflict resolution, custom zones, subscriptions, and performance optimization.

## Main Topics
- [CloudKit Architecture](#cloudkit-architecture) - Core concepts and data model
- [Advanced Queries](#advanced-queries) - Complex filtering and optimization
- [Custom Zones](#custom-zones) - Multi-user and collaborative data
- [Subscriptions & Push](#subscriptions--push) - Real-time data synchronization
- [Conflict Resolution](#conflict-resolution) - Handling data conflicts
- [✅ Best Practices](#-best-practices) - Production patterns
- [❌ Common Mistakes](#-common-mistakes-anti-patterns) - Anti-patterns to avoid

## Official Documentation
- [Apple: CloudKit Framework](https://developer.apple.com/documentation/cloudkit)
- [Apple: CloudKit Best Practices](https://developer.apple.com/documentation/cloudkit/cloudkit_best_practices)
- [WWDC 2023: Build better apps with CloudKit](https://developer.apple.com/videos/play/wwdc2023/10084/)

---

## CloudKit Architecture

### Understanding Records and Containers

CloudKit organizes data hierarchically: containers hold databases which contain records in zones.

```swift
// ✅ Correct: Proper container and database access
import CloudKit

class CloudKitManager {
    let container = CKContainer.default()
    
    func getDatabases() {
        let publicDB = container.publicCloudDatabase
        let privateDB = container.privateCloudDatabase
        
        // Public: shared across all users
        // Private: user-specific, encrypted
    }
}

// ❌ Wrong: Using main thread for database operations
class BadCloudKitManager {
    func fetchRecords() {
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        
        database.fetch(withRecordID: CKRecord.ID(recordName: "test")) { record, error in
            // DON'T update UI on main thread without dispatch
            DispatchQueue.main.async {
                // UI updates here
            }
        }
    }
}
```

**Key Points:**
- Always use `CKContainer.default()` for standard container
- Public database: read-accessible, requires explicit sharing
- Private database: encrypted, only user can access
- Shared database: for collaborative multi-user records

### Record Types and Schema

Define clear record types with consistent fields. CloudKit doesn't enforce schema at the database level, so application consistency is critical.

```swift
// ✅ Correct: Define record types with documentation
struct UserProfile {
    static let recordType = "UserProfile"
    
    enum Fields {
        static let name = "name"
        static let email = "email"
        static let avatar = "avatar"  // CKAsset
        static let bio = "bio"
        static let createdAt = "createdAt"
    }
}

// ✅ Correct: Record factory with validation
class CloudKitRecordFactory {
    static func createUserProfile(
        name: String,
        email: String,
        avatarData: Data?
    ) -> CKRecord {
        let record = CKRecord(
            recordType: UserProfile.recordType,
            zoneID: CKRecordZone.default().zoneID
        )
        
        record[UserProfile.Fields.name] = name
        record[UserProfile.Fields.email] = email
        record[UserProfile.Fields.createdAt] = Date()
        
        if let avatarData = avatarData {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("avatar.jpg")
            try? avatarData.write(to: tempURL)
            record[UserProfile.Fields.avatar] = CKAsset(fileURL: tempURL)
        }
        
        return record
    }
}

// ❌ Wrong: Inconsistent field naming and no type safety
class BadRecordFactory {
    static func createRecord(data: [String: Any]) -> CKRecord {
        let record = CKRecord(recordType: "user")
        
        for (key, value) in data {
            record[key] = value  // No validation!
        }
        
        return record
    }
}
```

---

## Advanced Queries

### Complex Query Predicates

Leverage NSPredicate for sophisticated filtering while managing query costs.

```swift
// ✅ Correct: Complex predicate with index optimization
class AdvancedQueryManager {
    func findActiveUsersInRegion(
        region: String,
        minFollowers: Int = 100
    ) -> CKQuery {
        let predicate = NSPredicate(format: 
            "region == %@ AND followers >= %d AND isActive == %@",
            region, minFollowers, NSNumber(value: true)
        )
        
        let query = CKQuery(recordType: "User", predicate: predicate)
        query.sortDescriptors = [
            NSSortDescriptor(key: "followers", ascending: false),
            NSSortDescriptor(key: "createdAt", ascending: false)
        ]
        
        return query
    }
    
    func executeQuery(_ query: CKQuery) async throws -> [CKRecord] {
        let database = CKContainer.default().publicCloudDatabase
        
        var allRecords: [CKRecord] = []
        var cursor: CKQueryOperation.Cursor? = nil
        
        repeat {
            let (records, newCursor) = try await database.records(
                matching: query,
                inZoneWith: nil,
                continuingMatchingFrom: cursor,
                resultsLimit: 100
            )
            
            allRecords.append(contentsOf: records)
            cursor = newCursor
        } while cursor != nil
        
        return allRecords
    }
}

// ❌ Wrong: Inefficient query without pagination
class BadQueryManager {
    func findAllUsers() throws -> [CKRecord] {
        let query = CKQuery(recordType: "User", predicate: NSPredicate(value: true))
        
        let database = CKContainer.default().publicCloudDatabase
        
        var records: [CKRecord] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        database.perform(query, inZoneWith: nil) { records, error in
            // No pagination! Will fail with large datasets
            records = records ?? []
            semaphore.signal()
        }
        
        semaphore.wait()
        return records
    }
}
```

**Query Optimization Tips:**
- Use equality predicates over range when possible
- Limit result sets with `resultsLimit`
- Implement pagination for large datasets
- Use indexes on frequently queried fields
- Test queries in CloudKit Dashboard first

---

## Custom Zones

### Setting Up Shared Zones for Collaboration

Custom zones enable multi-user collaboration and atomic batch operations.

```swift
// ✅ Correct: Create and manage custom zones
class CollaborativeZoneManager {
    let container = CKContainer.default()
    
    func createCollaborativeZone(_ zoneName: String) async throws {
        let zone = CKRecordZone(zoneName: zoneName)
        let privateDB = container.privateCloudDatabase
        
        _ = try await privateDB.save(zone)
        print("Zone created: \(zoneName)")
    }
    
    func shareZoneWithUsers(
        zoneID: CKRecordZone.ID,
        userEmails: [String]
    ) async throws {
        // Fetch records to share
        let privateDB = container.privateCloudDatabase
        let predicate = NSPredicate(format: "zoneID == %@", zoneID)
        
        let query = CKQuery(recordType: "CollaborativeDocument", predicate: predicate)
        let records = try await privateDB.records(matching: query, inZoneWith: zoneID)
        
        // Create share records for each user
        for email in userEmails {
            let shareRecord = CKShare(rootRecord: records.0.first!)
            shareRecord[CKShare.SystemFieldKey.title] = "Collaborative Project"
            shareRecord[CKShare.SystemFieldKey.purpose] = "Team collaboration"
            
            if let participant = CKShare.Participant(
                userIdentity: CKUserIdentity(userRecordID: CKRecord.ID(recordName: email)),
                role: .standard,
                permission: .readWrite
            ) {
                shareRecord.addParticipant(participant)
            }
            
            _ = try await privateDB.save(shareRecord)
        }
    }
}

// ❌ Wrong: No zone management, all operations in default zone
class BadCollaborationManager {
    func saveDocumentWithoutZone(document: String) async throws {
        let record = CKRecord(recordType: "Document")
        record["content"] = document
        
        let database = CKContainer.default().privateCloudDatabase
        _ = try await database.save(record)
        // Can't track collaboration or organize projects!
    }
}
```

---

## Subscriptions & Push

### Real-Time Data Synchronization

Subscriptions notify your app when records change, enabling real-time updates.

```swift
// ✅ Correct: Setup subscriptions with proper error handling
class SubscriptionManager {
    func subscribeToUserChanges() async throws {
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        
        let predicate = NSPredicate(format: "recordType == %@", "User")
        let subscription = CKQuerySubscription(
            recordType: "User",
            predicate: predicate,
            subscriptionID: "user-changes"
        )
        
        let notification = CKQuerySubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        notification.soundName = "default"
        notification.titleLocalizationKey = "USER_UPDATED"
        
        subscription.notificationInfo = notification
        
        do {
            _ = try await database.save(subscription)
            print("Subscription created successfully")
        } catch {
            print("Subscription error: \(error)")
        }
    }
    
    func handlePushNotification(_ userInfo: [AnyHashable: Any]) {
        // Fetch changed records
        let queryNotification = CKQuerySubscription.NotificationInfo()
        
        if let changedKeys = userInfo["ck"] as? [String: Any] {
            print("Changed keys: \(changedKeys)")
            
            Task {
                await fetchUpdatedRecords()
            }
        }
    }
    
    func fetchUpdatedRecords() async {
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        
        let query = CKQuery(
            recordType: "User",
            predicate: NSPredicate(value: true)
        )
        
        let records = try? await database.records(matching: query, inZoneWith: nil)
        print("Updated records: \(records?.0.count ?? 0)")
    }
}

// ❌ Wrong: Subscriptions without cleanup
class BadSubscriptionManager {
    func subscribeToEverything() async throws {
        let container = CKContainer.default()
        let database = container.publicCloudDatabase
        
        let subscription = CKQuerySubscription(
            recordType: "User",
            predicate: NSPredicate(value: true),  // Subscribes to ALL records!
            subscriptionID: "all-changes"
        )
        
        _ = try await database.save(subscription)
        // Never unsubscribe = memory leak + battery drain!
    }
}
```

---

## Conflict Resolution

### Handling Simultaneous Updates

When multiple devices modify the same record, implement robust conflict resolution.

```swift
// ✅ Correct: Server-wins conflict resolution with versioning
class ConflictResolutionManager {
    func saveRecordWithConflictHandling(
        record: CKRecord
    ) async throws {
        let database = CKContainer.default().privateCloudDatabase
        
        do {
            _ = try await database.save(record)
        } catch {
            if let ckError = error as? CKError {
                switch ckError.code {
                case .serverRecordChanged:
                    // Server version differs - implement resolution strategy
                    if let serverRecord = ckError.serverRecord,
                       let clientRecord = ckError.clientRecord {
                        
                        let resolved = resolveConflict(
                            client: clientRecord,
                            server: serverRecord
                        )
                        
                        _ = try await database.save(resolved)
                    }
                    
                case .limitExceeded:
                    print("Rate limited - implement exponential backoff")
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    _ = try await database.save(record)
                    
                default:
                    throw error
                }
            }
        }
    }
    
    // Client-wins strategy: keep local changes
    func clientWinsStrategy(
        client: CKRecord,
        server: CKRecord
    ) -> CKRecord {
        // Preserve client version
        client.modificationDate = Date()
        return client
    }
    
    // Server-wins strategy: accept server changes
    func serverWinsStrategy(
        client: CKRecord,
        server: CKRecord
    ) -> CKRecord {
        // Accept server version entirely
        return server
    }
    
    // Merge strategy: combine specific fields
    func mergeStrategy(
        client: CKRecord,
        server: CKRecord
    ) -> CKRecord {
        let merged = server
        
        // Merge specific fields based on timestamps
        if let clientTimestamp = client["lastModifiedBy"] as? Date,
           let serverTimestamp = server["lastModifiedBy"] as? Date {
            
            if clientTimestamp > serverTimestamp {
                merged["content"] = client["content"]
            }
        }
        
        merged["lastSyncTimestamp"] = Date()
        return merged
    }
    
    func resolveConflict(
        client: CKRecord,
        server: CKRecord
    ) -> CKRecord {
        // Use merge strategy by default
        return mergeStrategy(client: client, server: server)
    }
}

// ❌ Wrong: Ignoring conflicts entirely
class BadConflictManager {
    func saveRecord(_ record: CKRecord) async throws {
        let database = CKContainer.default().privateCloudDatabase
        
        try await database.save(record)
        // If conflict occurs, exception propagates unhandled!
    }
}
```

---

## ✅ Best Practices

### Caching Strategy

Implement local caching to reduce CloudKit queries and improve offline support.

**DO:**
```swift
class CachedCloudKitManager {
    let container = CKContainer.default()
    private var cache: [String: CKRecord] = [:]
    private let cacheQueue = DispatchQueue(label: "com.cloudkit.cache")
    
    func fetchWithCache(recordID: CKRecord.ID) async throws -> CKRecord {
        // Check cache first
        let cached = cacheQueue.sync {
            cache[recordID.recordName]
        }
        
        if let cached = cached {
            return cached
        }
        
        // Fetch from CloudKit
        let database = container.publicCloudDatabase
        let record = try await database.fetch(withRecordID: recordID)
        
        // Store in cache
        cacheQueue.async(flags: .barrier) {
            self.cache[recordID.recordName] = record
        }
        
        return record
    }
    
    func invalidateCache() {
        cacheQueue.async(flags: .barrier) {
            self.cache.removeAll()
        }
    }
}
```

### Rate Limiting

Respect CloudKit's rate limits with exponential backoff.

**DO:**
```swift
class RateLimitedManager {
    private var backoffDelay: TimeInterval = 1.0
    
    func saveWithBackoff(_ record: CKRecord) async throws {
        let database = CKContainer.default().privateCloudDatabase
        
        repeat {
            do {
                _ = try await database.save(record)
                backoffDelay = 1.0  // Reset on success
                break
            } catch let error as CKError where error.code == .limitExceeded {
                try await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                backoffDelay = min(backoffDelay * 2, 300)  // Max 5 minutes
            }
        } while true
    }
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake: Storing Large Assets Directly in Records

**WRONG:**
```swift
// DON'T: Storing large image data directly
class BadAssetHandling {
    func saveImageData(_ imageData: Data) async throws {
        let record = CKRecord(recordType: "Photo")
        record["imageData"] = imageData  // Terrible! Can exceed limits
        
        let database = CKContainer.default().privateCloudDatabase
        try await database.save(record)
    }
}
```

**CORRECT:**
```swift
// DO: Use CKAsset for large files
class GoodAssetHandling {
    func saveImage(_ imageData: Data) async throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("image.jpg")
        try imageData.write(to: tempURL)
        
        let record = CKRecord(recordType: "Photo")
        record["imageAsset"] = CKAsset(fileURL: tempURL)
        
        let database = CKContainer.default().privateCloudDatabase
        try await database.save(record)
    }
}
```

### Mistake: No Account Status Checking

**WRONG:**
```swift
// DON'T: Assume CloudKit is available
class BadAccountStatus {
    func syncData() async {
        let database = CKContainer.default().privateCloudDatabase
        _ = try? await database.save(CKRecord(recordType: "Data"))
    }
}
```

**CORRECT:**
```swift
// DO: Check account status first
class GoodAccountStatus {
    func syncData() async {
        let container = CKContainer.default()
        
        do {
            let accountStatus = try await container.accountStatus()
            
            guard accountStatus == .available else {
                print("CloudKit unavailable: \(accountStatus)")
                return
            }
            
            let database = container.privateCloudDatabase
            _ = try await database.save(CKRecord(recordType: "Data"))
        } catch {
            print("Account check error: \(error)")
        }
    }
}
```

### Mistake: Synchronous Blocking Operations

**WRONG:**
```swift
// DON'T: Block main thread with semaphore
class BadSyncPattern {
    func fetchData() -> [CKRecord] {
        var results: [CKRecord] = []
        let semaphore = DispatchSemaphore(value: 0)
        
        let database = CKContainer.default().publicCloudDatabase
        database.perform(CKQuery(recordType: "Data", predicate: NSPredicate(value: true)), inZoneWith: nil) { records, error in
            results = records ?? []
            semaphore.signal()
        }
        
        semaphore.wait()  // BLOCKS MAIN THREAD!
        return results
    }
}
```

**CORRECT:**
```swift
// DO: Use async/await
class GoodAsyncPattern {
    func fetchData() async throws -> [CKRecord] {
        let database = CKContainer.default().publicCloudDatabase
        let query = CKQuery(recordType: "Data", predicate: NSPredicate(value: true))
        
        let (records, _) = try await database.records(matching: query, inZoneWith: nil)
        return records
    }
}
```

---

## 🔗 Related Topics

- [**06-data/core-data.md**](core-data.md) - Local data persistence with Core Data
- [**06-data/userdefaults-and-preferences.md**](userdefaults-and-preferences.md) - Simple key-value storage
- [**03-networking-backend/backend.md**](../03-networking-backend/backend.md) - Server synchronization patterns
- [**04-app-lifecycle/ci-cd-and-deployment.md**](../04-app-lifecycle/ci-cd-and-deployment.md) - Deployment strategies with data
- [**07-advanced/permissions-and-security.md**](../07-advanced/permissions-and-security.md) - CloudKit privacy and encryption
