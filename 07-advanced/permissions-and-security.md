# Permissions & Security - User Privacy & Data Protection 🎯

## Overview
iOS is built on privacy by default. Understanding how to request permissions properly, store sensitive data securely, and protect user information is fundamental to building trustworthy apps. Learn to navigate privacy frameworks, use Keychain for secure storage, and implement authentication correctly.

## Main Topics
- [Permission Requests](#permission-requests) - User location, contacts, photos
- [Keychain Integration](#keychain-integration) - Secure credential storage
- [Biometric Authentication](#biometric-authentication) - Face ID and Touch ID
- [Data Encryption](#data-encryption) - Protecting stored data
- [Network Security](#network-security) - HTTPS and certificate pinning
- [Privacy Best Practices](#-best-practices) - User trust strategies
- [Common Mistakes](#-common-mistakes-anti-patterns) - Privacy pitfalls

## Official Documentation
- [Apple: App Privacy](https://developer.apple.com/app-store/app-privacy/)
- [Apple: Local Authentication](https://developer.apple.com/documentation/localauthentication)
- [Apple: Security Framework](https://developer.apple.com/documentation/security)
- [WWDC 2021: Privacy Best Practices](https://developer.apple.com/videos/play/wwdc2021/10077)

---

## Permission Requests

### Requesting Location Permission

Proper permission requests are critical—users expect clear explanations of why you need their data.

```swift
// ✅ Correct: Requesting location with clear messaging
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocationPermission() {
        // Check current status
        let status = CLLocationManager.authorizationStatus()
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            // Already have permission
            locationManager.startUpdatingLocation()
            
        case .notDetermined:
            // First time asking - use .whenInUse unless you absolutely need .always
            locationManager.requestWhenInUseAuthorization()
            
        case .denied, .restricted:
            // User denied - show message directing to Settings
            showPermissionDeniedAlert()
            
        @unknown default:
            break
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            print("Location permission granted")
            manager.startUpdatingLocation()
            
        case .denied:
            print("Location permission denied")
            
        case .notDetermined:
            print("Location permission not determined")
            
        default:
            break
        }
    }
    
    private func showPermissionDeniedAlert() {
        let alert = UIAlertController(title: "Location Access Needed", 
                                     message: "Go to Settings > Your App > Location to enable access",
                                     preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Settings", style: .default) { _ in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
    }
}

// Add to Info.plist:
// NSLocationWhenInUseUsageDescription: "We need your location to find nearby restaurants"
```

**Key Points:**
- Always request the **minimum permission** needed (.whenInUse vs .always)
- Provide clear messaging in Info.plist about why permission is needed
- Handle all permission states gracefully
- Respect user denial—don't repeatedly ask

### Requesting Photo Library Permission

```swift
// ✅ Correct: Requesting photo library access
import Photos

func requestPhotoLibraryPermission() {
    PHPhotoLibrary.requestAuthorization { status in
        DispatchQueue.main.async {
            switch status {
            case .authorized:
                print("Photo library access granted")
                self.loadPhotos()
                
            case .limited:
                // iOS 14+: User selected specific photos
                print("Limited photo access granted")
                self.loadPhotos()
                
            case .denied:
                print("Photo library access denied")
                self.showPermissionAlert()
                
            case .restricted:
                print("Photo library access restricted")
                
            case .notDetermined:
                print("Photo library permission not determined")
                
            @unknown default:
                break
            }
        }
    }
}

// Add to Info.plist:
// NSPhotoLibraryUsageDescription: "We need access to your photos to set a profile picture"
```

### Requesting Microphone and Camera

```swift
// ✅ Correct: Audio and video permission handling
import AVFoundation

class MediaPermissionManager {
    static func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                completion(granted)
            }
        }
    }
    
    static func checkCameraPermission() -> AVAuthorizationStatus {
        return AVCaptureDevice.authorizationStatus(for: .video)
    }
}

// Add to Info.plist:
// NSMicrophoneUsageDescription: "We need microphone access for voice calls"
// NSCameraUsageDescription: "We need camera access for video calls"
```

---

## Keychain Integration

### Storing Credentials Securely

The Keychain is the secure way to store passwords, tokens, and sensitive data. Never store in UserDefaults!

```swift
// ✅ Correct: Storing passwords in Keychain
import Security

class KeychainManager {
    static func savePassword(_ password: String, for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing password first
        SecItemDelete(query as CFDictionary)
        
        // Add new password
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    static func retrievePassword(for account: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw KeychainError.retrieveFailed(status)
        }
        
        guard let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw KeychainError.decodeFailed
        }
        
        return password
    }
    
    static func deletePassword(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
    case decodeFailed
}

// Usage
try KeychainManager.savePassword("SecurePassword123", for: "user@example.com")
let storedPassword = try KeychainManager.retrievePassword(for: "user@example.com")
```

### Storing Authentication Tokens

```swift
// ✅ Correct: Secure token storage
class AuthenticationManager {
    static func saveAuthToken(_ token: String) throws {
        try KeychainManager.savePassword(token, for: "auth_token")
    }
    
    static func retrieveAuthToken() throws -> String? {
        return try KeychainManager.retrievePassword(for: "auth_token")
    }
    
    static func isUserAuthenticated() -> Bool {
        do {
            return try retrieveAuthToken() != nil
        } catch {
            return false
        }
    }
    
    static func logout() throws {
        try KeychainManager.deletePassword(for: "auth_token")
    }
}

// Usage in login flow
func handleLoginResponse(token: String) {
    do {
        try AuthenticationManager.saveAuthToken(token)
        navigateToMainApp()
    } catch {
        showError("Failed to save authentication")
    }
}
```

---

## Biometric Authentication

### Implementing Face ID and Touch ID

```swift
// ✅ Correct: Local Authentication with biometrics
import LocalAuthentication

class BiometricAuthenticator {
    let context = LAContext()
    
    func isBiometricAvailable() -> (available: Bool, type: String) {
        var error: NSError?
        
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        
        let biometricType: String
        if #available(iOS 11, *) {
            switch context.biometryType {
            case .faceID:
                biometricType = "Face ID"
            case .touchID:
                biometricType = "Touch ID"
            case .none:
                biometricType = "None"
            @unknown default:
                biometricType = "Unknown"
            }
        } else {
            biometricType = "Touch ID"
        }
        
        return (canEvaluate, biometricType)
    }
    
    func authenticateUser(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            completion(false, error)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, 
                              localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
    
    func authenticateWithFallback(reason: String, completion: @escaping (Bool, Error?) -> Void) {
        var error: NSError?
        
        // Try biometric first, fall back to passcode
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            completion(false, error)
            return
        }
        
        context.evaluatePolicy(.deviceOwnerAuthentication,
                              localizedReason: reason) { success, error in
            DispatchQueue.main.async {
                completion(success, error)
            }
        }
    }
}

// Usage
let authenticator = BiometricAuthenticator()
let (available, type) = authenticator.isBiometricAvailable()

if available {
    authenticator.authenticateUser(reason: "Authenticate to access your account") { success, error in
        if success {
            print("Authentication successful")
            self.unlockApp()
        } else if let error = error {
            print("Authentication failed: \(error.localizedDescription)")
        }
    }
}
```

---

## Data Encryption

### Encrypting Sensitive Data

```swift
// ✅ Correct: Using CommonCrypto for encryption
import CommonCrypto
import Foundation

class DataEncryptor {
    static let algorithm: CCAlgorithm = UInt32(kCCAlgorithmAES128)
    static let options: CCOptions = UInt32(kCCOptionPKCS7Padding) | UInt32(kCCEncrypt)
    static let keySize = kCCKeySizeAES128
    static let blockSize = kCCBlockSizeAES128
    
    static func encryptData(_ data: Data, with key: Data) -> Data? {
        var encryptedData = Data(count: data.count + blockSize)
        var encryptedDataLength = Int(0)
        
        let status = encryptedData.withUnsafeMutableBytes { encryptedBytes in
            data.withUnsafeBytes { dataBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(kCCEncrypt),
                        algorithm,
                        options,
                        keyBytes.baseAddress,
                        keySize,
                        nil,
                        dataBytes.baseAddress,
                        data.count,
                        encryptedBytes.baseAddress,
                        encryptedData.count,
                        &encryptedDataLength
                    )
                }
            }
        }
        
        guard status == kCCSuccess else { return nil }
        
        encryptedData.removeSubrange(encryptedDataLength..<encryptedData.count)
        return encryptedData
    }
    
    static func decryptData(_ encryptedData: Data, with key: Data) -> Data? {
        var decryptedData = Data(count: encryptedData.count + blockSize)
        var decryptedDataLength = Int(0)
        
        let status = decryptedData.withUnsafeMutableBytes { decryptedBytes in
            encryptedData.withUnsafeBytes { encryptedBytes in
                key.withUnsafeBytes { keyBytes in
                    CCCrypt(
                        CCOperation(kCCDecrypt),
                        algorithm,
                        options,
                        keyBytes.baseAddress,
                        keySize,
                        nil,
                        encryptedBytes.baseAddress,
                        encryptedData.count,
                        decryptedBytes.baseAddress,
                        decryptedData.count,
                        &decryptedDataLength
                    )
                }
            }
        }
        
        guard status == kCCSuccess else { return nil }
        
        decryptedData.removeSubrange(decryptedDataLength..<decryptedData.count)
        return decryptedData
    }
}

// Usage
if let key = Data(count: kCCKeySizeAES128) {
    if let encrypted = DataEncryptor.encryptData("sensitive data".data(using: .utf8)!, with: key) {
        print("Encrypted: \(encrypted.base64EncodedString())")
        
        if let decrypted = DataEncryptor.decryptData(encrypted, with: key) {
            print("Decrypted: \(String(data: decrypted, encoding: .utf8) ?? "")")
        }
    }
}
```

---

## Network Security

### Certificate Pinning

```swift
// ✅ Correct: SSL/TLS certificate pinning
import Foundation

class SecureURLSessionDelegate: NSObject, URLSessionDelegate {
    let pinnedCertificates: Set<Data>
    
    init(pinnedCertificateNames: [String]) {
        var certificates = Set<Data>()
        
        for name in pinnedCertificateNames {
            if let path = Bundle.main.path(forResource: name, ofType: "cer"),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)) {
                certificates.insert(data)
            }
        }
        
        self.pinnedCertificates = certificates
        super.init()
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validate certificate chain
        var secResult = SecTrustResultType.invalid
        let status = SecTrustEvaluate(serverTrust, &secResult)
        
        guard status == errSecSuccess else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Check if certificate is in pinned set
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                continue
            }
            
            let certificateData = SecCertificateCopyData(certificate) as Data
            if pinnedCertificates.contains(certificateData) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }
        
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

// Usage
let delegate = SecureURLSessionDelegate(pinnedCertificateNames: ["api.example.com"])
let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)

var request = URLRequest(url: URL(string: "https://api.example.com/data")!)
session.dataTask(with: request) { data, response, error in
    // Handle response
}.resume()
```

---

## ✅ Best Practices

### Practice 1: Request Minimal Permissions
**DO:**
```swift
// ✅ Request .whenInUse instead of .always
locationManager.requestWhenInUseAuthorization()

// ✅ Only request permissions you actually need
// Don't request "just in case"
```

### Practice 2: Always Save Secrets in Keychain
**DO:**
```swift
// ✅ Secure storage
try KeychainManager.savePassword(apiKey, for: "api_key")

// ❌ Never in UserDefaults
// UserDefaults.standard.set(apiKey, forKey: "api_key")  // WRONG!
```

### Practice 3: Handle Permission Denials Gracefully
**DO:**
```swift
// ✅ Provide fallback functionality
if hasCameraPermission {
    startCamera()
} else {
    showGalleryPicker()  // Alternative
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Storing Passwords in UserDefaults
**WRONG:**
```swift
// ❌ Insecure - visible in app data
UserDefaults.standard.set(password, forKey: "user_password")
UserDefaults.standard.set(apiKey, forKey: "api_key")
```

**CORRECT:**
```swift
// ✅ Secure - stored in Keychain
try KeychainManager.savePassword(password, for: "user_password")
try KeychainManager.savePassword(apiKey, for: "api_key")
```

### Mistake 2: Requesting .always Location When .whenInUse Suffices
**WRONG:**
```swift
// ❌ Excessive permission request
locationManager.requestAlwaysAuthorization()
```

**CORRECT:**
```swift
// ✅ Request only what you need
locationManager.requestWhenInUseAuthorization()

// Upgrade to .always only if truly necessary
// Users are more likely to grant limited access first
```

### Mistake 3: Not Handling Biometric Errors
**WRONG:**
```swift
// ❌ Ignoring auth failures
authenticator.authenticateUser(reason: "Login") { success, _ in
    if success {
        login()  // Crashes if error, no fallback
    }
}
```

**CORRECT:**
```swift
// ✅ Handle all cases
authenticator.authenticateUser(reason: "Login") { success, error in
    if success {
        login()
    } else if let error = error as? LAError {
        switch error.code {
        case .userCancel:
            print("User cancelled")
        case .biometryNotAvailable:
            showPasscodeOption()
        default:
            print("Auth error: \(error.localizedDescription)")
        }
    }
}
```

### Mistake 4: Logging Sensitive Data
**WRONG:**
```swift
// ❌ Exposes secrets
print("API Key: \(apiKey)")
os.log("Password: %@", password)
```

**CORRECT:**
```swift
// ✅ Never log secrets
os.log("Authentication successful", log: logger, type: .info)
// If you must debug, use breakpoints instead
```

---

## 🔗 Related Topics
- [Keychain Deep Dive](../06-data/keychain-storage.md) - Secure storage
- [Authentication Patterns](../02-architecture/authentication-patterns.md) - Login flows
- [Network Security](../03-networking-backend/network-security.md) - HTTPS and APIs
- [User Privacy](privacy-compliance.md) - Privacy laws and compliance
- [Error Handling](../02-architecture/error-handling.md) - Managing errors
