# Working with Files - FileManager, URLs, and File Operations

## Overview

FileManager provides APIs for working with the file system. It enables reading, writing, creating, and deleting files and directories. Understanding file paths and sandboxing is crucial for iOS development.

## Main Topics

- [File System Basics](#file-system-basics)
- [Common Directories](#common-directories)
- [File Operations](#file-operations)
- [Directory Management](#directory-management)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [FileManager Documentation](https://developer.apple.com/documentation/foundation/filemanager)

---

## File System Basics

### URLs vs String Paths

```swift
import Foundation

// ❌ String paths - fragile, platform-dependent
let path = "/Users/name/Documents/file.txt"  // Not portable

// ✅ URLs - preferred, cross-platform
let url = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("file.txt")

print(url)  // file:///Users/name/Documents/file.txt
```

### Accessing FileManager

```swift
let fileManager = FileManager.default

// Check if file exists
let fileExists = fileManager.fileExists(atPath: url.path)

// Get file attributes
if let attributes = try? fileManager.attributesOfItem(atPath: url.path) {
    let fileSize = attributes[.size] as? Int ?? 0
    let modificationDate = attributes[.modificationDate] as? Date
}
```

---

## Common Directories

### App-Specific Directories

```swift
import Foundation

let fileManager = FileManager.default

// 📁 Documents - User's data
let documentURL = fileManager.urls(
    for: .documentDirectory,
    in: .userDomainMask
).first!

// 📁 Caches - Temporary files (cleared by system)
let cacheURL = fileManager.urls(
    for: .cachesDirectory,
    in: .userDomainMask
).first!

// 📁 Temporary - Temporary files (cleaned up frequently)
let tempURL = URL(fileURLWithPath: NSTemporaryDirectory())

// 📁 Application Support - App configuration
let supportURL = fileManager.urls(
    for: .applicationSupportDirectory,
    in: .userDomainMask
).first!

// Get all available directories
let allDirectories = FileManager.default.urls(
    for: .allLibrariesDirectory,
    in: .userDomainMask
)
```

### Sandbox Rules

```swift
// App sandbox prevents access to other app's data
// ✅ Allowed paths
let documentsPath = NSSearchPathForDirectoriesInDomains(
    .documentDirectory,
    .userDomainMask,
    true
).first  // E.g., /var/mobile/Containers/Data/PluginKitPlugin/UUID/Documents

// ❌ Not allowed
// /var/mobile/Containers/Data/PluginKitPlugin/OTHER_APP_UUID  // Other apps
// /private/var/containers/Bundle/Application/UUID/file.txt     // Bundle (read-only)
```

---

## File Operations

### Create File

```swift
import Foundation

let fileManager = FileManager.default

// Simple write
let url = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("greeting.txt")

let content = "Hello, World!"

do {
    try content.write(to: url, atomically: true, encoding: .utf8)
    print("File created")
} catch {
    print("Error: \(error)")
}
```

### Read File

```swift
let url = URL(fileURLWithPath: "/path/to/file.txt")

do {
    // Read as String
    let content = try String(contentsOf: url, encoding: .utf8)
    print(content)
    
    // Read as Data
    let data = try Data(contentsOf: url)
    print("Read \(data.count) bytes")
} catch {
    print("Error: \(error)")
}
```

### Update File

```swift
let url = URL(fileURLWithPath: "/path/to/file.txt")

do {
    // Overwrite completely
    try "New content".write(to: url, atomically: true, encoding: .utf8)
    
    // Append to existing file
    if let data = "Appended text".data(using: .utf8) {
        if fileManager.fileExists(atPath: url.path) {
            let fileHandle = try FileHandle(forWritingTo: url)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            try fileHandle.close()
        }
    }
} catch {
    print("Error: \(error)")
}
```

### Delete File

```swift
let fileManager = FileManager.default
let url = URL(fileURLWithPath: "/path/to/file.txt")

do {
    try fileManager.removeItem(at: url)
    print("File deleted")
} catch {
    print("Error: \(error)")
}
```

### Copy File

```swift
let fileManager = FileManager.default

let sourceURL = URL(fileURLWithPath: "/path/to/source.txt")
let destURL = URL(fileURLWithPath: "/path/to/dest.txt")

do {
    try fileManager.copyItem(at: sourceURL, to: destURL)
    print("File copied")
} catch {
    print("Error: \(error)")
}
```

### Move File

```swift
let fileManager = FileManager.default

let sourceURL = URL(fileURLWithPath: "/path/to/oldname.txt")
let destURL = URL(fileURLWithPath: "/path/to/newname.txt")

do {
    try fileManager.moveItem(at: sourceURL, to: destURL)
    print("File moved")
} catch {
    print("Error: \(error)")
}
```

---

## Directory Management

### Create Directory

```swift
let fileManager = FileManager.default
let dirURL = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("MyFolder")

do {
    // Create single directory
    try fileManager.createDirectory(
        at: dirURL,
        withIntermediateDirectories: false
    )
    
    // Create nested directories
    let nestedURL = dirURL.appendingPathComponent("SubFolder/DeepFolder")
    try fileManager.createDirectory(
        at: nestedURL,
        withIntermediateDirectories: true  // Creates all parent directories
    )
} catch {
    print("Error: \(error)")
}
```

### List Directory Contents

```swift
let fileManager = FileManager.default
let dirURL = URL(fileURLWithPath: "/path/to/folder")

do {
    // Simple list
    let contents = try fileManager.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: nil)
    for fileURL in contents {
        print(fileURL.lastPathComponent)
    }
    
    // With resource keys
    let keys = [URLResourceKey.isDirectoryKey, URLResourceKey.fileSizeKey]
    let contents = try fileManager.contentsOfDirectory(
        at: dirURL,
        includingPropertiesForKeys: keys
    )
    
    for url in contents {
        let resourceValues = try url.resourceValues(forKeys: Set(keys))
        let isDirectory = resourceValues.isDirectory ?? false
        let fileSize = resourceValues.fileSize ?? 0
        
        print("\(url.lastPathComponent) - Directory: \(isDirectory), Size: \(fileSize)")
    }
} catch {
    print("Error: \(error)")
}
```

### Recursive Directory Traversal

```swift
let fileManager = FileManager.default

func traverseDirectory(_ url: URL, level: Int = 0) throws {
    let contents = try fileManager.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)
    
    for itemURL in contents {
        let indent = String(repeating: "  ", count: level)
        print("\(indent)- \(itemURL.lastPathComponent)")
        
        var isDir: ObjCBool = false
        if fileManager.fileExists(atPath: itemURL.path, isDirectory: &isDir), isDir.boolValue {
            try traverseDirectory(itemURL, level: level + 1)
        }
    }
}

// Usage
let documentsURL = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0]

try traverseDirectory(documentsURL)
```

### Delete Directory

```swift
let fileManager = FileManager.default
let dirURL = URL(fileURLWithPath: "/path/to/folder")

do {
    // Remove directory and contents
    try fileManager.removeItem(at: dirURL)
    print("Directory deleted")
} catch {
    print("Error: \(error)")
}
```

---

## Advanced Operations

### Working with JSONCoder

```swift
struct User: Codable {
    let name: String
    let email: String
}

let fileManager = FileManager.default
let documentsURL = fileManager.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0]

let userFileURL = documentsURL.appendingPathComponent("user.json")

// Save to file
let user = User(name: "John", email: "john@example.com")
let encoder = JSONEncoder()
encoder.outputFormatting = .prettyPrinted

do {
    let jsonData = try encoder.encode(user)
    try jsonData.write(to: userFileURL)
} catch {
    print("Error saving: \(error)")
}

// Load from file
do {
    let jsonData = try Data(contentsOf: userFileURL)
    let decoder = JSONDecoder()
    let loadedUser = try decoder.decode(User.self, from: jsonData)
    print(loadedUser)
} catch {
    print("Error loading: \(error)")
}
```

### File Size and Directory Size

```swift
let fileManager = FileManager.default

func getFileSize(_ url: URL) throws -> Int {
    let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
    return resourceValues.fileSize ?? 0
}

func getDirectorySize(_ url: URL) throws -> Int {
    let fileManager = FileManager.default
    let keys = [URLResourceKey.isRegularFileKey, URLResourceKey.fileSizeKey]
    let contents = try fileManager.contentsOfDirectory(
        at: url,
        includingPropertiesForKeys: keys
    )
    
    var size = 0
    for itemURL in contents {
        let resourceValues = try itemURL.resourceValues(forKeys: Set(keys))
        
        if resourceValues.isRegularFile ?? false {
            size += resourceValues.fileSize ?? 0
        } else {
            // Recursively get subdirectory size
            size += try getDirectorySize(itemURL)
        }
    }
    return size
}

// Usage
let documentsURL = fileManager.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0]

let bytes = try getDirectorySize(documentsURL)
let megabytes = Double(bytes) / 1_000_000
print("Directory size: \(megabytes) MB")
```

---

## 🎯 Best Practices

### 1. Use URLs Over Strings
```swift
// ✅ Cross-platform, type-safe
let url = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("data.json")

// ❌ String paths are fragile
let path = "/Users/name/Documents/data.json"
```

### 2. Handle Errors Gracefully
```swift
// ✅ Explicit error handling
do {
    try fileManager.removeItem(at: url)
} catch let error as NSError {
    if error.code == NSFileNoSuchFileError {
        print("File doesn't exist")
    } else {
        print("Error: \(error)")
    }
}

// ❌ Silently fail
try? fileManager.removeItem(at: url)  // What went wrong?
```

### 3. Check Before Operations
```swift
// ✅ Check existence first
if fileManager.fileExists(atPath: url.path) {
    try fileManager.removeItem(at: url)
}

// ❌ Assume it exists
try fileManager.removeItem(at: url)  // Might fail
```

---

## ❌ Common Mistakes

### Mistake 1: Hardcoded Paths

**WRONG:**
```swift
// ❌ Only works on specific device/user
let path = "/Users/Admin/Documents/file.txt"
let content = try String(contentsOfFile: path, encoding: .utf8)
```

**CORRECT:**
```swift
// ✅ Works on all devices
let url = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0].appendingPathComponent("file.txt")
let content = try String(contentsOf: url, encoding: .utf8)
```

---

### Mistake 2: Ignoring Errors

**WRONG:**
```swift
// ❌ Silent failure - hard to debug
try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
```

**CORRECT:**
```swift
// ✅ Handle specific errors
do {
    try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
} catch {
    print("Failed to create directory: \(error)")
}
```

---

### Mistake 3: Wrong Directory

**WRONG:**
```swift
// ❌ Caches cleared by system
let cacheURL = FileManager.default.urls(
    for: .cachesDirectory,
    in: .userDomainMask
)[0]
try importantData.write(to: cacheURL)  // Will be deleted!
```

**CORRECT:**
```swift
// ✅ Documents persist
let documentsURL = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
)[0]
try importantData.write(to: documentsURL)
```

---

## Related Topics

- [Codable and JSON](codable-and-json.md)
- [Data Persistence](persistence-and-storage.md)
- [SwiftData](swiftdata.md)

---

**Master FileManager for robust file system operations!**
