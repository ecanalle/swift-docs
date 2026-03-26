# WebSockets - Real-Time Communication

## Overview

WebSockets provide full-duplex communication channels over TCP for real-time, bidirectional data exchange. Unlike HTTP requests, WebSockets maintain persistent connections, enabling efficient real-time features.

## Main Topics

- [WebSocket Basics](#websocket-basics)
- [URLSessionWebSocketTask](#urlsessionwebsockettask)
- [Sending and Receiving](#sending-and-receiving)
- [Common Patterns](#common-patterns)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [URLSessionWebSocketTask](https://developer.apple.com/documentation/foundation/urlsessionwebsockettask)

---

## WebSocket Basics

### HTTP vs WebSocket

```swift
// HTTP - Request/Response model
// 1. Client sends request
// 2. Server sends response
// 3. Connection closes
// 4. Must reconnect for new data

// WebSocket - Persistent connection
// 1. Client establishes connection
// 2. Connection stays open (bidirectional)
// 3. Either side can send data anytime
// 4. No reconnect needed
```

### When to Use WebSockets

```swift
// ✅ WebSockets ideal for:
// - Real-time chat
// - Live notifications
// - Live data feeds (stocks, sports scores)
// - Multiplayer games
// - Live collaboration

// ❌ Use REST API for:
// - Static data
// - One-off operations
// - Large payloads
// - Cacheable responses
```

---

## URLSessionWebSocketTask

### Creating a WebSocket Connection

```swift
import Foundation

let url = URL(string: "wss://echo.websocket.org")!  // wss:// for secure
let request = URLRequest(url: url)

// Create task
let webSocket = URLSession.shared.webSocketTask(with: request)
webSocket.resume()  // Start connection
```

### Configuration

```swift
let config = URLSessionConfiguration.default
let session = URLSession(configuration: config)

let url = URL(string: "wss://api.example.com/ws")!
let webSocket = session.webSocketTask(with: url)

// Set headers
var request = URLRequest(url: url)
request.setValue("Bearer token123", forHTTPHeaderField: "Authorization")
request.setValue("my-client", forHTTPHeaderField: "User-Agent")

let webSocket = session.webSocketTask(with: request)
webSocket.resume()
```

---

## Sending and Receiving

### Sending Messages

```swift
import Foundation

let webSocket = URLSession.shared.webSocketTask(
    with: URL(string: "wss://echo.websocket.org")!
)
webSocket.resume()

// Send string message
let message = "Hello, WebSocket!"
webSocket.send(.string(message)) { error in
    if let error = error {
        print("Send error: \(error)")
    } else {
        print("Message sent")
    }
}

// Send data message
let data = "Binary data".data(using: .utf8)!
webSocket.send(.data(data)) { error in
    if let error = error {
        print("Send error: \(error)")
    }
}
```

### Receiving Messages

```swift
import Foundation

func receiveMessage(_ webSocket: URLSessionWebSocketTask) {
    webSocket.receive { result in
        switch result {
        case .success(let message):
            switch message {
            case .string(let text):
                print("Received text: \(text)")
                
            case .data(let data):
                print("Received data: \(data)")
                
            @unknown default:
                fatalError()
            }
            
            // Listen for next message
            receiveMessage(webSocket)
            
        case .failure(let error):
            print("Receive error: \(error)")
        }
    }
}

// Start receiving
receiveMessage(webSocket)
```

### Connection Lifecycle

```swift
import Foundation

class WebSocketManager: NSObject {
    var webSocket: URLSessionWebSocketTask?
    
    func connect(to urlString: String) {
        let url = URL(string: urlString)!
        webSocket = URLSession.shared.webSocketTask(with: url)
        webSocket?.resume()
        
        print("Connecting...")
        listen()
    }
    
    func listen() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.listen()  // Continue listening
                
            case .failure(let error):
                print("Connection closed: \(error)")
                self?.reconnect()
            }
        }
    }
    
    func send(_ text: String) {
        webSocket?.send(.string(text)) { error in
            if let error = error {
                print("Send failed: \(error)")
            }
        }
    }
    
    func disconnect() {
        let code: URLSessionWebSocketTask.CloseCode = .normalClosure
        webSocket?.cancel(with: code, reason: nil)
        webSocket = nil
    }
    
    func reconnect() {
        DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
            self.connect(to: "wss://api.example.com/ws")
        }
    }
    
    func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        switch message {
        case .string(let text):
            print("Received: \(text)")
        case .data(let data):
            print("Received data: \(data.count) bytes")
        @unknown default:
            break
        }
    }
}
```

---

## Common Patterns

### Chat Application

```swift
import Foundation

class ChatManager: NSObject {
    var webSocket: URLSessionWebSocketTask?
    var onMessageReceived: ((String) -> Void)?
    var onConnectionStatusChanged: ((Bool) -> Void)?
    
    func connectToChat(userId: String) {
        let url = URL(string: "wss://chat.example.com/connect?userId=\(userId)")!
        webSocket = URLSession.shared.webSocketTask(with: url)
        webSocket?.resume()
        
        onConnectionStatusChanged?(true)
        startListening()
    }
    
    func sendMessage(_ text: String) {
        let message = """
        {
            "type": "message",
            "text": "\(text)",
            "timestamp": \(Date().timeIntervalSince1970)
        }
        """
        webSocket?.send(.string(message)) { _ in }
    }
    
    func startListening() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let jsonString) = message {
                    if let data = jsonString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let text = json["text"] as? String {
                        self?.onMessageReceived?(text)
                    }
                }
                self?.startListening()
                
            case .failure:
                self?.onConnectionStatusChanged?(false)
            }
        }
    }
    
    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
    }
}

// Usage
let chatManager = ChatManager()
chatManager.onMessageReceived = { message in
    print("New message: \(message)")
}
chatManager.connectToChat(userId: "user123")
chatManager.sendMessage("Hello!")
```

### Real-Time Data Feed

```swift
class PriceStreamManager {
    var webSocket: URLSessionWebSocketTask?
    var onPriceUpdate: ((String, Double) -> Void)?
    
    func startPriceStream(for symbols: [String]) {
        let url = URL(string: "wss://price-api.example.com/stream")!
        webSocket = URLSession.shared.webSocketTask(with: url)
        webSocket?.resume()
        
        // Subscribe to symbols
        let subscription = """
        {
            "action": "subscribe",
            "symbols": \(symbols)
        }
        """
        webSocket?.send(.string(subscription)) { _ in }
        
        startReceivingPrices()
    }
    
    func startReceivingPrices() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(.string(let json)):
                if let data = json.data(using: .utf8),
                   let priceData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let symbol = priceData["symbol"] as? String,
                   let price = priceData["price"] as? Double {
                    self?.onPriceUpdate?(symbol, price)
                }
                self?.startReceivingPrices()
                
            case .success(.data):
                self?.startReceivingPrices()
                
            case .failure(let error):
                print("Price stream error: \(error)")
            }
        }
    }
}
```

### Heartbeat/Ping-Pong

```swift
class HealthyWebSocket {
    var webSocket: URLSessionWebSocketTask?
    var heartbeatTimer: Timer?
    
    func connect(to url: URL) {
        webSocket = URLSession.shared.webSocketTask(with: url)
        webSocket?.resume()
        
        startHeartbeat()
        listen()
    }
    
    func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            self?.sendPing()
        }
    }
    
    func sendPing() {
        webSocket?.sendPing { [weak self] error in
            if let error = error {
                print("Ping failed: \(error)")
                self?.reconnect()
            } else {
                print("Ping sent successfully")
            }
        }
    }
    
    func listen() {
        webSocket?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.listen()  // Continue listening
            case .failure(let error):
                print("Connection failed: \(error)")
                self?.reconnect()
            }
        }
    }
    
    func reconnect() {
        heartbeatTimer?.invalidate()
        webSocket?.cancel(with: .goingAway, reason: nil)
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            // Reconnect logic
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Handle Connection Loss
```swift
// ✅ Implement reconnection logic
func listen() {
    webSocket?.receive { [weak self] result in
        switch result {
        case .success:
            self?.listen()
            
        case .failure:
            self?.scheduleReconnection()
        }
    }
}

// ❌ No reconnection
webSocket?.receive { result in
    // If connection drops, nothing happens
}
```

### 2. Implement Heartbeat
```swift
// ✅ Keep connection alive
let heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
    self?.webSocket?.sendPing { _ in }
}

// ❌ Connection might idle and close
// No heartbeat sent
```

### 3. Use wss:// for Security
```swift
// ✅ Encrypted WebSocket
let url = URL(string: "wss://secure.example.com/ws")!

// ❌ Unencrypted WebSocket
let url = URL(string: "ws://unsecure.example.com/ws")!  // Data exposed
```

---

## ❌ Common Mistakes

### Mistake 1: Not Resuming WebSocket

**WRONG:**
```swift
// ❌ Created but not started
let webSocket = URLSession.shared.webSocketTask(with: url)
// Connection never established!
```

**CORRECT:**
```swift
// ✅ Resume to start connection
let webSocket = URLSession.shared.webSocketTask(with: url)
webSocket.resume()
```

---

### Mistake 2: Not Listening Continuously

**WRONG:**
```swift
// ❌ Receives only one message
webSocket?.receive { result in
    print(result)
    // After this, no more messages received
}
```

**CORRECT:**
```swift
// ✅ Keep listening after each message
func listen() {
    webSocket?.receive { [weak self] result in
        self?.handleMessage(result)
        self?.listen()  // Listen for next message
    }
}
```

---

### Mistake 3: Not Handling Connection Close

**WRONG:**
```swift
// ❌ Connection closes silently
webSocket?.receive { result in
    // No error handling or reconnection
}
```

**CORRECT:**
```swift
// ✅ Handle disconnection and reconnect
webSocket?.receive { [weak self] result in
    switch result {
    case .success(let message):
        self?.handleMessage(message)
        self?.listen()
        
    case .failure(let error):
        print("Connection lost: \(error)")
        self?.reconnect()
    }
}
```

---

## Related Topics

- [Networking and APIs](urlsession.md)
- [REST APIs](rest-api.md)
- [Background Tasks](../../04-app-lifecycle/app-lifecycle.md)

---

**Master WebSockets for real-time communication in iOS apps!**
