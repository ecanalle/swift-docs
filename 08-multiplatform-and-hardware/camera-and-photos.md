# Camera and Photos - Image Capture and Library Access

## Overview

Camera and Photos frameworks enable capturing images/videos and accessing the user's photo library. PHPhotoLibrary manages permissions and asset access efficiently.

## Main Topics

- [Camera Basics](#camera-basics)
- [Photo Library Access](#photo-library-access)
- [Image Capture](#image-capture)
- [Permission Handling](#permission-handling)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [AVFoundation Camera](https://developer.apple.com/documentation/avfoundation)
- [Photos Framework](https://developer.apple.com/documentation/photos)

---

## Camera Basics

### UIImagePickerController

```swift
import UIKit

class CameraViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func presentCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func presentPhotoLibrary() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController,
                             didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
        if let image = info[.originalImage] as? UIImage {
            handleImage(image)
        }
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    func handleImage(_ image: UIImage) {
        // Use captured image
        print("Image captured")
    }
}
```

### Camera Availability

```swift
import UIKit

class CameraChecker {
    static func isCameraAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.camera)
    }
    
    static func isPhotoLibraryAvailable() -> Bool {
        return UIImagePickerController.isSourceTypeAvailable(.photoLibrary)
    }
    
    static func canCaptureVideo() -> Bool {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return false }
        
        let types = UIImagePickerController.availableMediaTypes(for: .camera) ?? []
        return types.contains("public.movie")
    }
    
    static func canTakePictures() -> Bool {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return false }
        
        let types = UIImagePickerController.availableMediaTypes(for: .camera) ?? []
        return types.contains("public.image")
    }
}
```

---

## Photo Library Access

### PHPhotoLibrary Basics

```swift
import Photos

class PhotoLibraryManager {
    func fetchAllPhotos() -> PHFetchResult<PHAsset> {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        return PHAsset.fetchAssets(with: .image, options: options)
    }
    
    func fetchRecentPhotos(count: Int) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        options.fetchLimit = count
        
        let result = PHAsset.fetchAssets(with: .image, options: options)
        
        var assets: [PHAsset] = []
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }
    
    func getImage(for asset: PHAsset, targetSize: CGSize, completion: @escaping (UIImage?) -> Void) {
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        
        manager.requestImage(for: asset, targetSize: targetSize, contentMode: .aspectFill, options: options) { image, info in
            completion(image)
        }
    }
}
```

### Collection View Display

```swift
import PhotosUI

class PhotoGridViewController: UICollectionViewController, PHPhotoLibraryChangeObserver {
    var assets: PHFetchResult<PHAsset>?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        
        requestPhotoLibraryAccess()
        PHPhotoLibrary.shared().register(self)
    }
    
    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                self.loadPhotos()
            }
        }
    }
    
    func loadPhotos() {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        
        assets = PHAsset.fetchAssets(with: .image, options: options)
        collectionView.reloadData()
    }
    
    // MARK: - PHPhotoLibraryChangeObserver
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
        DispatchQueue.main.async {
            guard let assets = self.assets,
                  let details = changeInstance.changeDetails(for: assets) else { return }
            
            self.assets = details.fetchResultAfterChanges
            self.collectionView.reloadData()
        }
    }
    
    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                numberOfItemsInSection section: Int) -> Int {
        return assets?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView,
                                cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
        
        if let asset = assets?[indexPath.item] {
            cell.configure(with: asset)
        }
        
        return cell
    }
}

class PhotoCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    
    func configure(with asset: PHAsset) {
        let manager = PHImageManager.default()
        manager.requestImage(for: asset, targetSize: CGSize(width: 100, height: 100),
                            contentMode: .aspectFill, options: PHImageRequestOptions()) { image, _ in
            self.imageView.image = image
        }
    }
}
```

---

## Image Capture

### AVCaptureSession

```swift
import AVFoundation

class CameraCaptureManager: NSObject, AVCapturePhotoCaptureDelegate {
    let captureSession = AVCaptureSession()
    let photoOutput = AVCapturePhotoOutput()
    var previewLayer: AVCameraPreviewLayer?
    
    func setupCamera(in view: UIView) {
        // Request camera permission
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted {
                self.configureCamera(in: view)
            }
        }
    }
    
    func configureCamera(in view: UIView) {
        guard let camera = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: camera) else { return }
        
        captureSession.addInput(input)
        captureSession.addOutput(photoOutput)
        
        previewLayer = AVCameraPreviewLayer(session: captureSession)
        if let previewLayer = previewLayer {
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = view.bounds
            view.layer.insertSublayer(previewLayer, at: 0)
        }
        
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }
    
    func capturePhoto() {
        let settings = AVCapturePhotoSettings()
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput,
                    didFinishProcessingPhoto photo: AVCapturePhoto,
                    error: Error?) {
        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else { return }
        
        handleCapturedImage(image)
    }
    
    func handleCapturedImage(_ image: UIImage) {
        // Process image
        print("Photo captured")
    }
    
    func stopCamera() {
        DispatchQueue.global().async {
            self.captureSession.stopRunning()
        }
    }
}
```

---

## Permission Handling

### Requesting Permissions

```swift
import AVFoundation
import Photos

class PermissionManager {
    static func requestCameraPermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            completion(granted)
        }
    }
    
    static func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            completion(granted)
        }
    }
    
    static func requestPhotoLibraryPermission(completion: @escaping (Bool) -> Void) {
        PHPhotoLibrary.requestAuthorization { status in
            completion(status == .authorized)
        }
    }
    
    static func checkCameraPermission() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }
    
    static func checkPhotoLibraryPermission() -> Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
}
```

### Info.plist Keys

```xml
<!-- Required permissions in Info.plist -->
<key>NSCameraUsageDescription</key>
<string>We need access to your camera to capture photos</string>

<key>NSMicrophoneUsageDescription</key>
<string>We need access to your microphone for video</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>We need access to your photos</string>

<key>NSPhotoLibraryAddUsageDescription</key>
<string>We need to save photos to your library</string>
```

---

## 🎯 Best Practices

### 1. Always Request Permissions
```swift
// ✅ Check and request before use
func accessCamera() {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    
    if status == .authorized {
        openCamera()
    } else if status == .notDetermined {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            if granted { self.openCamera() }
        }
    }
}

// ❌ Assume permission granted
openCamera()  // May crash
```

### 2. Save to Photo Library Properly
```swift
// ✅ Use PHPhotoLibrary
PHPhotoLibrary.shared().performChanges {
    PHAssetChangeRequest.creationRequestForAsset(from: image)
}

// ❌ Direct file access
// May not update user's library correctly
```

---

## ❌ Common Mistakes

### Mistake 1: Not Setting Info.plist Keys

**WRONG:**
```swift
// ❌ App crashes without permission description
AVCaptureDevice.requestAccess(for: .video) { _ in }
```

**CORRECT:**
```swift
// ✅ Add to Info.plist first
// NSCameraUsageDescription
// NSPhotoLibraryUsageDescription
```

---

### Mistake 2: Accessing Library on Main Thread

**WRONG:**
```swift
// ❌ May freeze UI
func loadPhotos() {
    for asset in assets {
        PHImageManager.default().requestImage(for: asset, ...)
    }
}
```

**CORRECT:**
```swift
// ✅ Load in background
DispatchQueue.global().async {
    for asset in assets {
        PHImageManager.default().requestImage(for: asset, ...)
    }
}
```

---

## Related Topics

- [UIImagePickerController](uikit.md)
- [AVFoundation](avfoundation.md)
- [File Management](../06-data/file-management.md)

---

**Master camera and photo access for rich visual apps!**
