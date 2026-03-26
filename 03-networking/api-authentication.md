# API Authentication and Security - OAuth2, JWT, SSL Pinning

## Overview

Secure API communication requires proper authentication mechanisms and encryption. OAuth2, JWT tokens, and certificate pinning protect user data and prevent unauthorized access.

## Main Topics

- [Authentication Methods](#authentication-methods)
- [OAuth2](#oauth2)
- [JWT Tokens](#jwt-tokens)
- [SSL/TLS Pinning](#ssltls-pinning)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [URLSession Security](https://developer.apple.com/documentation/foundation/urlsession)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

---

## Authentication Methods

### API Key Authentication

```swift
import Foundation

class APIKeyAuth {
    let apiKey: String
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func createRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        
        // Header authentication
        request.setValue(apiKey, forHTTPHeaderField: "X-API-Key")
        
        // Or query parameter
        // var components = URLComponents(url: url, resolvingAgainstBaseURL: true)!
        // components.queryItems = [URLQueryItem(name: "api_key", value: apiKey)]
        // request.url = components.url
        
        return request
    }
    
    func fetchData(from url: URL) async throws -> Data {
        let request = createRequest(for: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
}

// Usage
let auth = APIKeyAuth(apiKey: "your-secret-key-123")
let data = try await auth.fetchData(from: URL(string: "https://api.example.com/data")!)
```

### Basic Authentication

```swift
import Foundation

class BasicAuth {
    let username: String
    let password: String
    
    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
    
    func createRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)
        
        // Create credentials string
        let credentials = "\(username):\(password)"
        
        // Base64 encode
        guard let data = credentials.data(using: .utf8) else { return request }
        let base64 = data.base64EncodedString()
        
        // Add to header
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        
        return request
    }
    
    func fetchData(from url: URL) async throws -> Data {
        let request = createRequest(for: url)
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
}

// Usage
let auth = BasicAuth(username: "user", password: "pass")
let data = try await auth.fetchData(from: URL(string: "https://api.example.com/data")!)
```

---

## OAuth2

### OAuth2 Flow

```swift
import AuthenticationServices

class OAuth2Manager: NSObject, ASWebAuthenticationPresentationContextProviding {
    let clientID: String
    let clientSecret: String
    let redirectURL: URL
    let authURL: URL
    let tokenURL: URL
    
    init(clientID: String, clientSecret: String, redirectURL: URL,
         authURL: URL, tokenURL: URL) {
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURL = redirectURL
        self.authURL = authURL
        self.tokenURL = tokenURL
    }
    
    // Step 1: Initiate authorization
    func beginAuth() async throws -> String {
        // Build authorization URL
        var components = URLComponents(url: authURL, resolvingAgainstBaseURL: true)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURL.absoluteString),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "read write"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        
        let authorizationURL = components.url!
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authorizationURL,
                callbackURLScheme: redirectURL.scheme
            ) { [weak self] url, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let url = url,
                      let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: URLError(.cannotParseResponse))
                    return
                }
                
                continuation.resume(returning: code)
            }
            
            session.presentationContextProvider = self
            session.start()
        }
    }
    
    // Step 2: Exchange code for token
    func exchangeCodeForToken(_ code: String) async throws -> String {
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = "grant_type=authorization_code&code=\(code)&client_id=\(clientID)&client_secret=\(clientSecret)&redirect_uri=\(redirectURL.absoluteString)"
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        guard let accessToken = json?["access_token"] as? String else {
            throw URLError(.cannotParseResponse)
        }
        
        return accessToken
    }
    
    // Make authenticated request
    func makeAuthenticatedRequest(_ url: URL, token: String) async throws -> Data {
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
    
    // MARK: - ASWebAuthenticationPresentationContextProviding
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return ASPresentationAnchor()
    }
}
```

---

## JWT Tokens

### JWT Token Handling

```swift
import Foundation

struct JWTToken: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    
    var isExpired: Bool {
        // Check if token expired (simplified)
        return false
    }
}

class JWTAuth {
    private var token: JWTToken?
    private let keychain = KeychainManager()
    
    func loginAndStoreToken(email: String, password: String) async throws {
        let credentials = "\(email):\(password)"
        guard let data = credentials.data(using: .utf8) else { return }
        let base64 = data.base64EncodedString()
        
        var request = URLRequest(url: URL(string: "https://api.example.com/login")!)
        request.httpMethod = "POST"
        request.setValue("Basic \(base64)", forHTTPHeaderField: "Authorization")
        
        let (responseData, _) = try await URLSession.shared.data(for: request)
        let token = try JSONDecoder().decode(JWTToken.self, from: responseData)
        
        // Store securely
        try keychain.store(token.accessToken, for: "access_token")
        if let refreshToken = token.refreshToken {
            try keychain.store(refreshToken, for: "refresh_token")
        }
        
        self.token = token
    }
    
    func getAccessToken() async throws -> String {
        // Load from keychain
        if let stored = try? keychain.retrieve("access_token") {
            return stored
        }
        
        // Or refresh if expired
        if let refreshToken = try? keychain.retrieve("refresh_token") {
            return try await refreshAccessToken(refreshToken)
        }
        
        throw AuthError.noToken
    }
    
    func refreshAccessToken(_ refreshToken: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://api.example.com/refresh")!)
        request.httpMethod = "POST"
        
        let body = ["refresh_token": refreshToken]
        request.httpBody = try JSONEncoder().encode(body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        let newToken = try JSONDecoder().decode(JWTToken.self, from: data)
        
        try keychain.store(newToken.accessToken, for: "access_token")
        return newToken.accessToken
    }
    
    func makeAuthenticatedRequest(_ url: URL) async throws -> Data {
        let token = try await getAccessToken()
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        return data
    }
}

enum AuthError: Error {
    case noToken
    case invalidCredentials
    case refreshFailed
}
```

---

## SSL/TLS Pinning

### Certificate Pinning

```swift
import Foundation

class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    let pinnedCertificates: [SecCertificate]
    
    init?(certificateNames: [String]) {
        var certificates: [SecCertificate] = []
        
        for name in certificateNames {
            guard let path = Bundle.main.path(forResource: name, ofType: "cer"),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let certificate = SecCertificateCreateWithData(nil, data as CFData) else {
                return nil
            }
            certificates.append(certificate)
        }
        
        self.pinnedCertificates = certificates
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        // Only handle server trust challenges
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
        
        // Check pinned certificate
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        for i in 0..<certificateCount {
            guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                continue
            }
            
            for pinnedCertificate in pinnedCertificates {
                if serverCertificate == pinnedCertificate {
                    // Certificate matched
                    completionHandler(.useCredential,
                                    URLCredential(trust: serverTrust))
                    return
                }
            }
        }
        
        // No pinned certificate matched
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
}

// Usage
let delegate = CertificatePinningDelegate(certificateNames: ["api.example.com"])
let config = URLSessionConfiguration.default
let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)

// Use session for secure requests
let url = URL(string: "https://api.example.com/secure")!
let (data, _) = try await session.data(from: url)
```

### Public Key Pinning

```swift
import Security
import CommonCrypto

class PublicKeyPinningDelegate: NSObject, URLSessionDelegate {
    let pinnedPublicKeyHashes: Set<String>
    
    init(publicKeyHashes: Set<String>) {
        self.pinnedPublicKeyHashes = publicKeyHashes
    }
    
    func urlSession(_ session: URLSession,
                    didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get server certificate
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        for i in 0..<certificateCount {
            guard let certificate = SecTrustGetCertificateAtIndex(serverTrust, i),
                  let publicKey = getPublicKey(from: certificate),
                  let hash = getPublicKeyHash(publicKey) else {
                continue
            }
            
            if pinnedPublicKeyHashes.contains(hash) {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
                return
            }
        }
        
        completionHandler(.cancelAuthenticationChallenge, nil)
    }
    
    private func getPublicKey(from certificate: SecCertificate) -> SecKey? {
        var publicKey: SecKey?
        let policy = SecPolicyCreateBasicX509()
        var trust: SecTrust?
        
        SecTrustCreateWithCertificates(certificate, policy, &trust)
        if let trust = trust {
            publicKey = SecTrustCopyPublicKey(trust)
        }
        
        return publicKey
    }
    
    private func getPublicKeyHash(_ key: SecKey) -> String? {
        guard let keyData = SecKeyCopyExternalRepresentation(key, nil) as Data? else {
            return nil
        }
        
        // SHA-256 hash
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = keyData.withUnsafeBytes {
            CC_SHA256($0.baseAddress, CC_LONG(keyData.count), &digest)
        }
        
        return Data(digest).base64EncodedString()
    }
}
```

---

## 🎯 Best Practices

### 1. Store Tokens Securely
```swift
// ✅ Use Keychain
try keychain.store(token, for: "access_token")

// ❌ UserDefaults exposes sensitive data
UserDefaults.standard.set(token, forKey: "access_token")
```

### 2. Use HTTPS Always
```swift
// ✅ Secure connection
let url = URL(string: "https://api.example.com")!

// ❌ Unencrypted
let url = URL(string: "http://api.example.com")!
```

### 3. Validate Certificates
```swift
// ✅ Pin certificates for critical endpoints
let delegate = CertificatePinningDelegate(certificateNames: ["api.example.com"])

// ❌ Trust all certificates
// No validation
```

---

## ❌ Common Mistakes

### Mistake 1: Storing Tokens in UserDefaults

**WRONG:**
```swift
// ❌ Exposed in plist
UserDefaults.standard.set(token, forKey: "token")
```

**CORRECT:**
```swift
// ✅ Secure storage
try keychain.store(token, for: "access_token")
```

---

### Mistake 2: Not Refreshing Expired Tokens

**WRONG:**
```swift
// ❌ Uses expired token
let token = try keychain.retrieve("access_token")
// No check if expired
```

**CORRECT:**
```swift
// ✅ Refresh if needed
let token = try await getValidAccessToken()
```

---

### Mistake 3: Ignoring Certificate Warnings

**WRONG:**
```swift
// ❌ Accepts all certificates
URLSessionConfiguration.default
```

**CORRECT:**
```swift
// ✅ Validate certificates
let delegate = CertificatePinningDelegate(certificateNames: ["api.example.com"])
```

---

## Related Topics

- [Networking and URLs](urlsession.md)
- [REST APIs](rest-api.md)
- [WebSocket Security](websockets.md)
- [Keychain Storage](keychain.md)

---

**Master authentication to build secure, user-friendly apps!**
