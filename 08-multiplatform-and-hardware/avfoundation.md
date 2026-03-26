# AVFoundation - Audio and Video Playback

## Overview

AVFoundation handles audio and video playback, recording, and processing. It provides comprehensive media capabilities beyond simple playback.

## Main Topics

- [Audio Playback](#audio-playback)
- [Video Playback](#video-playback)
- [Audio Recording](#audio-recording)
- [Audio Session Management](#audio-session-management)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [AVFoundation](https://developer.apple.com/documentation/avfoundation)

---

## Audio Playback

### Simple Audio Playback

```swift
import AVFoundation

class AudioPlayer {
    var player: AVAudioPlayer?
    
    func playSound(filename: String, fileType: String) {
        guard let url = Bundle.main.url(forResource: filename, withExtension: fileType) else {
            print("File not found")
            return
        }
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.play()
        } catch {
            print("Error loading audio: \(error)")
        }
    }
    
    func pause() {
        player?.pause()
    }
    
    func resume() {
        player?.play()
    }
    
    func stop() {
        player?.stop()
        player?.currentTime = 0
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        print("Playback finished")
    }
}
```

### Advanced Audio Control

```swift
import AVFoundation

class AdvancedAudioPlayer: NSObject, AVAudioPlayerDelegate {
    var player: AVAudioPlayer?
    var onProgress: ((TimeInterval) -> Void)?
    var displayLink: CADisplayLink?
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: .duckOthers
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    func playAudio(url: URL) {
        setupAudioSession()
        
        do {
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = 0.5
            player?.play()
            
            startProgressTracking()
        } catch {
            print("Error: \(error)")
        }
    }
    
    func setVolume(_ volume: Float) {
        player?.volume = max(0, min(1, volume))
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
    }
    
    func startProgressTracking() {
        displayLink = CADisplayLink(
            target: self,
            selector: #selector(updateProgress)
        )
        displayLink?.add(to: .main, forMode: .common)
    }
    
    @objc func updateProgress() {
        guard let duration = player?.duration, duration > 0 else { return }
        
        let progress = (player?.currentTime ?? 0) / duration
        onProgress?(progress)
    }
    
    func stopProgressTracking() {
        displayLink?.invalidate()
        displayLink = nil
    }
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        stopProgressTracking()
    }
}
```

---

## Video Playback

### AVPlayer Basic

```swift
import AVKit

class VideoPlayerViewController: UIViewController {
    var playerViewController: AVPlayerViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        playVideo()
    }
    
    func playVideo() {
        guard let url = URL(string: "https://example.com/video.mp4") else { return }
        
        let player = AVPlayer(url: url)
        
        playerViewController = AVPlayerViewController()
        playerViewController?.player = player
        
        guard let playerVC = playerViewController else { return }
        
        addChild(playerVC)
        view.addSubview(playerVC.view)
        playerVC.view.frame = view.bounds
        playerVC.didMove(toParent: self)
        
        player.play()
    }
}
```

### Custom Video Control

```swift
import AVFoundation

class CustomVideoPlayer: UIView {
    var player: AVPlayer?
    let playerLayer = AVPlayerLayer()
    var timeObserver: Any?
    var onTimeUpdate: ((CMTime) -> Void)?
    
    func setupPlayer(url: URL) {
        player = AVPlayer(url: url)
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        
        layer.addSublayer(playerLayer)
        
        addPeriodicTimeObserver()
    }
    
    override func layoutSublayers(of layer: CALayer) {
        super.layoutSublayers(of: layer)
        
        playerLayer.frame = bounds
    }
    
    func play() {
        player?.play()
    }
    
    func pause() {
        player?.pause()
    }
    
    func seek(to time: CMTime) {
        player?.seek(to: time)
    }
    
    private func addPeriodicTimeObserver() {
        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        
        timeObserver = player?.addPeriodicTimeObserver(
            forInterval: interval,
            queue: .main
        ) { [weak self] time in
            self?.onTimeUpdate?(time)
        }
    }
    
    deinit {
        if let observer = timeObserver {
            player?.removeTimeObserver(observer)
        }
    }
}
```

---

## Audio Recording

### Basic Recording

```swift
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    var recorder: AVAudioRecorder?
    var isRecording = false
    
    func startRecording() {
        setupAudioSession()
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let audioFilePath = (documentsPath as NSString).appendingPathComponent("recording.m4a")
        let audioFileURL = URL(fileURLWithPath: audioFilePath)
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        do {
            recorder = try AVAudioRecorder(url: audioFileURL, settings: settings)
            recorder?.delegate = self
            recorder?.record()
            isRecording = true
        } catch {
            print("Error: \(error)")
        }
    }
    
    func stopRecording() {
        recorder?.stop()
        isRecording = false
    }
    
    func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .record,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Audio session error: \(error)")
        }
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        print("Recording finished: \(flag)")
    }
}
```

---

## Audio Session Management

### Managing Audio Context

```swift
import AVFoundation

class AudioSessionManager {
    static let shared = AudioSessionManager()
    
    func setupForPlayback() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: .duckOthers
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error: \(error)")
        }
    }
    
    func setupForRecording() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .record,
                mode: .default,
                options: []
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error: \(error)")
        }
    }
    
    func setupForPlaybackAndRecording() {
        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playAndRecord,
                mode: .default,
                options: .defaultToSpeaker
            )
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Error: \(error)")
        }
    }
    
    func deactivate() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        } catch {
            print("Error: \(error)")
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Configure Audio Session
```swift
// ✅ Set up session before playback
AVAudioSession.sharedInstance().setCategory(.playback)
player.play()

// ❌ No session configuration
player.play()  // May conflict with other apps
```

### 2. Handle Interruptions
```swift
// ✅ Listen for interruptions
NotificationCenter.default.addObserver(
    self,
    selector: #selector(handleInterruption),
    name: AVAudioSession.interruptionNotification,
    object: nil
)

// ❌ Ignore interruptions
// Audio may not resume properly
```

### 3. Clean Up Resources
```swift
// ✅ Stop and deactivate
player?.pause()
try? AVAudioSession.sharedInstance().setActive(false)

// ❌ Leave audio session active
// Drains battery
```

---

## ❌ Common Mistakes

### Mistake 1: Not Setting Audio Session

**WRONG:**
```swift
// ❌ May not work with other audio
let player = AVAudioPlayer(contentsOf: url)
player.play()
```

**CORRECT:**
```swift
// ✅ Configure first
try AVAudioSession.sharedInstance().setCategory(.playback)
let player = AVAudioPlayer(contentsOf: url)
player.play()
```

---

### Mistake 2: Strong Reference to Player

**WRONG:**
```swift
// ❌ Player deallocates immediately
func playSound(url: URL) {
    let player = AVAudioPlayer(contentsOf: url)
    player.play()
    // player deallocates here
}
```

**CORRECT:**
```swift
// ✅ Keep strong reference
class AudioManager {
    var player: AVAudioPlayer?
    
    func playSound(url: URL) {
        player = try? AVAudioPlayer(contentsOf: url)
        player?.play()
    }
}
```

---

## Related Topics

- [Camera and Photos](camera-and-photos.md)
- [Background Tasks](../04-app-lifecycle/notifications.md)
- [AVKit Framework](.)

---

**Master AVFoundation for rich media experiences!**
