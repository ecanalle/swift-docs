# CallKit Advanced - VoIP & System Call Integration 🎯

## Overview
CallKit enables your app to integrate with the native phone interface. Build VoIP apps that work seamlessly with iOS call handling, display caller ID during calls, and provide a native calling experience.

## Main Topics
- [CallKit Fundamentals](#callkit-fundamentals) - Basic setup
- [Incoming Calls](#incoming-calls) - Handling incoming VoIP
- [Outgoing Calls](#outgoing-calls) - Initiating calls
- [Call Management](#call-management) - During-call actions
- [PushKit Integration](#pushkit-integration) - Background notifications
- [Audio Management](#audio-management) - Call audio setup
- [Best Practices](#-best-practices) - VoIP strategies
- [Common Mistakes](#-common-mistakes-anti-patterns) - CallKit pitfalls

## Official Documentation
- [Apple: CallKit Framework](https://developer.apple.com/documentation/callkit)
- [Apple: PushKit](https://developer.apple.com/documentation/pushkit)
- [WWDC 2021: Designing for CallKit](https://developer.apple.com/videos/play/wwdc2021/10110)

---

## CallKit Fundamentals

### Provider Setup

```swift
// ✅ Correct: Initializing CallKit provider
import CallKit

class CallKitManager: NSObject, CXProviderDelegate {
    let callController = CXCallController()
    let provider: CXProvider
    
    override init() {
        let config = CXProviderConfiguration(localizedName: "MyVoIPApp")
        config.supportsVideo = false
        config.maximumCallsPerCallGroup = 1
        config.supportedHandleTypes = [.phoneNumber, .generic]
        
        // Configure audio
        config.iconTemplateImageData = UIImage(named: "app-icon")?.pngData()
        
        self.provider = CXProvider(configuration: config)
        super.init()
        
        self.provider.setDelegate(self, queue: DispatchQueue.main)
    }
    
    // Handle provider reset
    func providerDidReset(_ provider: CXProvider) {
        print("Provider reset - clean up calls")
        // Cancel all active calls
    }
}
```

### Handling Incoming Calls

```swift
// ✅ Correct: Processing incoming VoIP call
class CallKitManager: NSObject, CXProviderDelegate {
    func handleIncomingCall(from caller: String, callID: UUID) {
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: caller)
        update.hasVideo = false
        update.supportsDTMF = true
        update.supportsHolding = true
        update.supportsGrouping = false
        update.supportsUngrouping = false
        
        provider.reportNewIncomingCall(with: callID, update: update) { error in
            if let error = error {
                print("Failed to report incoming call: \(error)")
            } else {
                print("Incoming call reported successfully")
            }
        }
    }
    
    // Provider delegate methods
    func provider(_ provider: CXProvider,
                 perform action: CXAnswerCallAction) {
        print("Call answered: \(action.callUUID)")
        
        // Answer the call
        // Setup audio, connect to server, etc
        
        action.fulfill()  // Mark action complete
    }
    
    func provider(_ provider: CXProvider,
                 perform action: CXEndCallAction) {
        print("Call ended: \(action.callUUID)")
        
        // Disconnect audio, clean up
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider,
                 perform action: CXSetMutedCallAction) {
        print("Call muted: \(action.isMuted)")
        
        // Mute/unmute audio
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider,
                 perform action: CXSetOnHoldCallAction) {
        print("Call on hold: \(action.isOnHold)")
        
        if action.isOnHold {
            // Pause audio
        } else {
            // Resume audio
        }
        
        action.fulfill()
    }
}
```

---

## Incoming Calls

### Detailed Call Handling

```swift
// ✅ Correct: Full incoming call flow
import CallKit
import AVFoundation

class VoIPCallHandler {
    let callKitManager: CallKitManager
    let audioController: AudioController
    var activeCall: Call?
    
    struct Call {
        let uuid: UUID
        let caller: String
        var isConnected = false
        var isMuted = false
    }
    
    init(callKitManager: CallKitManager) {
        self.callKitManager = callKitManager
        self.audioController = AudioController()
    }
    
    func handleIncomingCall(from caller: String) {
        let callUUID = UUID()
        
        // Report to CallKit immediately
        callKitManager.handleIncomingCall(from: caller, callID: callUUID)
        
        // Update local state
        activeCall = Call(uuid: callUUID, caller: caller)
        
        // Update call state after connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let update = CXCallUpdate()
            update.hasConnected = true
            self.callKitManager.provider.reportCall(with: callUUID, updated: update)
        }
    }
    
    func answerCall(_ callUUID: UUID) {
        activeCall?.isConnected = true
        audioController.setupAudio(for: .voip)
        audioController.startAudio()
    }
    
    func endCall(_ callUUID: UUID) {
        audioController.stopAudio()
        activeCall = nil
    }
    
    func muteCall(_ callUUID: UUID, muted: Bool) {
        activeCall?.isMuted = muted
        audioController.setMuted(muted)
    }
}
```

### Custom Caller ID

```swift
// ✅ Correct: Displaying custom caller info
import CallKit

class CallerIDManager {
    func reportIncomingCall(from userID: String,
                           displayName: String,
                           callID: UUID) {
        let callKitManager = CallKitManager()
        
        // Create handle - can be phone number or generic string
        let handle = CXHandle(type: .generic, value: userID)
        
        let update = CXCallUpdate()
        update.remoteHandle = handle
        update.localizedCallerName = displayName
        update.hasVideo = false
        
        callKitManager.provider.reportNewIncomingCall(with: callID, update: update) { error in
            if let error = error {
                print("Error: \(error)")
            }
        }
    }
}
```

---

## Outgoing Calls

### Initiating Calls

```swift
// ✅ Correct: Starting outgoing call
import CallKit

class OutgoingCallHandler {
    let callController: CXCallController
    
    init() {
        self.callController = CXCallController()
    }
    
    func startCall(to recipient: String) async {
        let handle = CXHandle(type: .generic, value: recipient)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        
        // Optional: set call capabilities
        startCallAction.isVideo = false
        
        let transaction = CXTransaction(action: startCallAction)
        
        do {
            try await callController.request(transaction)
            print("Call request submitted")
        } catch {
            print("Failed to start call: \(error)")
        }
    }
    
    func endCall(_ callUUID: UUID) async {
        let endCallAction = CXEndCallAction(call: callUUID)
        let transaction = CXTransaction(action: endCallAction)
        
        do {
            try await callController.request(transaction)
            print("Call ended")
        } catch {
            print("Failed to end call: \(error)")
        }
    }
}
```

---

## Call Management

### During-Call Actions

```swift
// ✅ Correct: Handling call control actions
import CallKit

class CallManager: NSObject, CXProviderDelegate {
    let provider: CXProvider
    var callState: [UUID: CallState] = [:]
    
    enum CallState {
        case connecting
        case connected
        case disconnecting
        case disconnected
    }
    
    func provider(_ provider: CXProvider,
                 perform action: CXPlayDTMFCallAction) {
        print("DTMF pressed: \(action.digits)")
        // Send DTMF tones (keypad sounds)
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider,
                 perform action: CXSendMessageCallAction) {
        print("Message: \(action.message)")
        // Send message during call
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider,
                 timedOutPerforming action: CXAction) {
        print("Action timed out: \(action)")
        // Handle timeout - too long to process
    }
    
    func provider(_ provider: CXProvider,
                 didActivateAudioSession audioSession: AVAudioSession) {
        print("Audio session activated")
        // Start audio playback/recording
    }
    
    func provider(_ provider: CXProvider,
                 didDeactivateAudioSession audioSession: AVAudioSession) {
        print("Audio session deactivated")
        // Stop audio playback/recording
    }
}
```

### Conference Calls

```swift
// ✅ Correct: Managing multiple calls
import CallKit

class ConferenceCallManager {
    let callController: CXCallController
    var activeCalls: [UUID: CallInfo] = [:]
    
    struct CallInfo {
        let uuid: UUID
        let participant: String
    }
    
    func mergeCallsIntoConference(call1UUID: UUID, call2UUID: UUID) async {
        let groupCallAction = CXSetGroupCallAction(call: call1UUID, callUUIDToGroupWith: call2UUID)
        let transaction = CXTransaction(action: groupCallAction)
        
        do {
            try await callController.request(transaction)
            print("Calls merged into conference")
        } catch {
            print("Failed to merge calls: \(error)")
        }
    }
    
    func splitConferenceCall(callUUID: UUID) async {
        let ungroupAction = CXSetGroupCallAction(call: callUUID, callUUIDToGroupWith: nil)
        let transaction = CXTransaction(action: ungroupAction)
        
        do {
            try await callController.request(transaction)
            print("Call split from conference")
        } catch {
            print("Failed to split call: \(error)")
        }
    }
}
```

---

## PushKit Integration

### VoIP Push Notifications

```swift
// ✅ Correct: Setting up VoIP push
import PushKit
import CallKit

class PushKitManager: NSObject, PKPushRegistryDelegate {
    let pushRegistry = PKPushRegistry(queue: DispatchQueue.main)
    
    override init() {
        super.init()
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
    
    // Push registry delegates
    func pushRegistry(_ registry: PKPushRegistry,
                     didUpdate credentials: PKPushCredentials,
                     for type: PKPushType) {
        let token = credentials.token.map { String(format: "%02.2hhx", $0) }.joined()
        print("VoIP token: \(token)")
        
        // Send token to server for push delivery
        sendVoIPTokenToServer(token)
    }
    
    func pushRegistry(_ registry: PKPushRegistry,
                     didReceiveIncomingPushWith payload: PKPushPayload,
                     for type: PKPushType,
                     completion: @escaping () -> Void) {
        
        // Handle incoming VoIP push
        guard let callerID = payload.dictionaryPayload["caller"] as? String else {
            completion()
            return
        }
        
        print("Incoming VoIP call from: \(callerID)")
        
        // Report call to CallKit
        let callUUID = UUID()
        let callKitManager = CallKitManager()
        callKitManager.handleIncomingCall(from: callerID, callID: callUUID)
        
        completion()
    }
    
    private func sendVoIPTokenToServer(_ token: String) {
        // Send to your backend for push notifications
    }
}
```

---

## Audio Management

### Call Audio Setup

```swift
// ✅ Correct: Configuring audio for calls
import AVFoundation

class AudioController {
    let audioEngine = AVAudioEngine()
    let audioSession = AVAudioSession.sharedInstance()
    var isMuted = false
    
    func setupAudio(for mode: AVAudioSession.Mode) {
        do {
            try audioSession.setCategory(.playAndRecord,
                                        mode: mode,
                                        options: [.defaultToSpeaker, .duckOthers])
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            print("Audio setup error: \(error)")
        }
    }
    
    func startAudio() {
        do {
            try audioEngine.start()
            print("Audio engine started")
        } catch {
            print("Error starting audio: \(error)")
        }
    }
    
    func stopAudio() {
        audioEngine.stop()
        do {
            try audioSession.setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error stopping audio: \(error)")
        }
    }
    
    func setMuted(_ muted: Bool) {
        isMuted = muted
        // Implementation depends on your audio setup
        // Could disconnect input node, etc
    }
    
    func switchToSpeaker() {
        do {
            try audioSession.overrideOutputAudioPort(.speaker)
        } catch {
            print("Error switching to speaker: \(error)")
        }
    }
    
    func switchToReceiver() {
        do {
            try audioSession.overrideOutputAudioPort(.none)
        } catch {
            print("Error switching to receiver: \(error)")
        }
    }
}
```

---

## ✅ Best Practices

### Practice 1: Report Calls Immediately
**DO:**
```swift
// ✅ Report to CallKit as soon as notified
provider.reportNewIncomingCall(with: callUUID, update: update) { error in
    // Handle response
}

// ✅ Update call state when connected
let update = CXCallUpdate()
update.hasConnected = true
provider.reportCall(with: callUUID, updated: update)
```

### Practice 2: Handle Audio Session Properly
**DO:**
```swift
// ✅ Setup audio when provider requests it
func provider(_ provider: CXProvider,
             didActivateAudioSession audioSession: AVAudioSession) {
    // Start audio
}
```

### Practice 3: Use PushKit for VoIP
**DO:**
```swift
// ✅ VoIP pushes wake app in background
pushRegistry.desiredPushTypes = [.voIP]

// ✅ Callkit shows native UI even if app was backgrounded
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Not Reporting Calls to CallKit
**WRONG:**
```swift
// ❌ VoIP call happens silently
// User doesn't see lock screen notification
// System doesn't recognize call
```

**CORRECT:**
```swift
// ✅ Always report to CallKit
provider.reportNewIncomingCall(with: callUUID, update: update)
```

### Mistake 2: Setting Up Audio at Wrong Time
**WRONG:**
```swift
// ❌ Audio setup before answer
setupAudio()
handleAnswer()
```

**CORRECT:**
```swift
// ✅ Setup when CallKit requests it
func provider(_ provider: CXProvider,
             didActivateAudioSession audioSession: AVAudioSession) {
    setupAudio()
}
```

### Mistake 3: Forgetting to Fulfill Actions
**WRONG:**
```swift
// ❌ Actions hang without response
func provider(_ provider: CXProvider,
             perform action: CXAnswerCallAction) {
    // Does something but never calls action.fulfill()
}
```

**CORRECT:**
```swift
// ✅ Always fulfill actions
func provider(_ provider: CXProvider,
             perform action: CXAnswerCallAction) {
    handleAnswer()
    action.fulfill()  // Mark complete
}
```

---

## 🔗 Related Topics
- [Audio Processing](../05-features/audio-fundamentals.md) - Audio engine basics
- [Background Execution](../04-app-lifecycle/background-execution.md) - Background modes
- [Notifications](../04-app-lifecycle/notifications.md) - Push notification setup
- [Privacy & Permissions](../07-advanced/permissions-and-security.md) - Call permissions
