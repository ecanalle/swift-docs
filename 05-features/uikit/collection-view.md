# UICollectionView - Flexible Grid Layouts

## Overview

UICollectionView displays collections of items in customizable layouts. It supports grids, carousels, and complex layouts with efficient cell reuse and animation capabilities.

## Main Topics

- [Collection View Basics](#collection-view-basics)
- [Data Source and Delegate](#data-source-and-delegate)
- [Cell Configuration](#cell-configuration)
- [Layouts](#layouts)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [UICollectionView](https://developer.apple.com/documentation/uikit/uicollectionview)

---

## Collection View Basics

### Simple Grid Setup

```swift
import UIKit

class PhotoGridViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var photos: [UIImage] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCollectionView()
    }
    
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Register cell
        collectionView.register(
            PhotoCell.self,
            forCellWithReuseIdentifier: PhotoCell.identifier
        )
        
        // Setup layout
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        collectionView.collectionViewLayout = layout
    }
}

extension PhotoGridViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoCell.identifier,
            for: indexPath
        ) as! PhotoCell
        
        cell.configure(with: photos[indexPath.item])
        return cell
    }
}

extension PhotoGridViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        print("Selected photo: \(indexPath.item)")
    }
}

class PhotoCell: UICollectionViewCell {
    static let identifier = "PhotoCell"
    
    @IBOutlet weak var imageView: UIImageView!
    
    func configure(with image: UIImage) {
        imageView.image = image
    }
}
```

---

## Data Source and Delegate

### Complete Data Source Implementation

```swift
import UIKit

class ItemsViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    var items: [[String]] = [
        ["Apple", "Banana", "Cherry"],
        ["Date", "Elderberry", "Fig"],
        ["Grape", "Honeydew"]
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        collectionView.register(
            ItemCell.self,
            forCellWithReuseIdentifier: "ItemCell"
        )
    }
}

extension ItemsViewController: UICollectionViewDataSource {
    // Number of sections
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return items.count
    }
    
    // Items per section
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return items[section].count
    }
    
    // Configure cell
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ItemCell",
            for: indexPath
        ) as! ItemCell
        
        let item = items[indexPath.section][indexPath.item]
        cell.configure(with: item)
        return cell
    }
    
    // Section headers
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        
        if kind == UICollectionView.elementKindSectionHeader {
            let header = collectionView.dequeueReusableSupplementaryView(
                ofKind: kind,
                withReuseIdentifier: "HeaderView",
                for: indexPath
            )
            
            let title = UILabel()
            title.text = "Section \(indexPath.section)"
            header.addSubview(title)
            
            return header
        }
        
        return UICollectionReusableView()
    }
}

extension ItemsViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.section][indexPath.item]
        print("Selected: \(item)")
    }
}

class ItemCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    
    func configure(with text: String) {
        label.text = text
    }
}
```

---

## Cell Configuration

### Custom Cell with Images

```swift
import UIKit

class ImageCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        // Rounded corners
        layer.cornerRadius = 8
        clipsToBounds = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
    }
    
    func configure(with image: UIImage, title: String) {
        imageView.image = image
        titleLabel.text = title
    }
    
    func configure(with url: URL, title: String) {
        titleLabel.text = title
        
        Task {
            if let image = try await ImageCache.shared.image(for: url) {
                imageView.image = image
            }
        }
    }
}
```

### Cell with Interactive Elements

```swift
import UIKit

class InteractiveCell: UICollectionViewCell {
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!
    
    var onFavoriteToggled: ((Bool) -> Void)?
    var isFavorited = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        favoriteButton.addTarget(
            self,
            action: #selector(favoriteButtonTapped),
            for: .touchUpInside
        )
    }
    
    @objc func favoriteButtonTapped() {
        isFavorited.toggle()
        updateFavoriteButton()
        onFavoriteToggled?(isFavorited)
    }
    
    func configure(with text: String, isFavorited: Bool = false) {
        contentLabel.text = text
        self.isFavorited = isFavorited
        updateFavoriteButton()
    }
    
    private func updateFavoriteButton() {
        let imageName = isFavorited ? "heart.fill" : "heart"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
}
```

---

## Layouts

### Flow Layout Customization

```swift
import UIKit

class ViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layout = UICollectionViewFlowLayout()
        
        // Item size
        layout.itemSize = CGSize(width: 100, height: 100)
        
        // Spacing
        layout.minimumInteritemSpacing = 10 // Horizontal
        layout.minimumLineSpacing = 20      // Vertical
        
        // Section inset
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        // Header/Footer size
        layout.headerReferenceSize = CGSize(width: 0, height: 40)
        layout.footerReferenceSize = CGSize(width: 0, height: 20)
        
        collectionView.collectionViewLayout = layout
    }
}
```

### Adaptive Grid Layout

```swift
import UIKit

class AdaptiveGridViewController: UIViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        updateLayout()
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideChanges: { _ in
            self.updateLayout()
        })
    }
    
    func updateLayout() {
        let layout = UICollectionViewFlowLayout()
        
        let width = collectionView.bounds.width
        let padding: CGFloat = 20
        let cellDimension = (width - padding * 3) / 2  // 2 columns
        
        layout.itemSize = CGSize(width: cellDimension, height: cellDimension)
        layout.minimumInteritemSpacing = padding
        layout.minimumLineSpacing = padding
        
        collectionView.collectionViewLayout = layout
    }
}
```

### Custom Circular Layout

```swift
import UIKit

class CircleLayout: UICollectionViewLayout {
    var itemSize: CGSize = CGSize(width: 100, height: 100)
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        let center = CGPoint(
            x: collectionView!.bounds.midX,
            y: collectionView!.bounds.midY
        )
        let radius = collectionView!.bounds.width / 3
        
        var attributes: [UICollectionViewLayoutAttributes] = []
        let itemCount = collectionView?.numberOfItems(inSection: 0) ?? 0
        
        for i in 0..<itemCount {
            let angle = CGFloat(i) * CGFloat.pi * 2 / CGFloat(itemCount)
            
            let attr = UICollectionViewLayoutAttributes(forCellWith: IndexPath(item: i, section: 0))
            attr.center = CGPoint(
                x: center.x + radius * cos(angle),
                y: center.y + radius * sin(angle)
            )
            attr.size = itemSize
            
            attributes.append(attr)
        }
        
        return attributes
    }
    
    override var collectionViewContentSize: CGSize {
        return collectionView?.bounds.size ?? .zero
    }
}
```

---

## 🎯 Best Practices

### 1. Optimize Cell Reuse
```swift
// ✅ Reuse cells efficiently
override func prepareForReuse() {
    super.prepareForReuse()
    imageView.image = nil
    label.text = nil
    // Cancel pending operations
}

// ❌ Create new cell each time
// Wasteful of memory
```

### 2. Handle Different Screen Sizes
```swift
// ✅ Adapt layout to screen
let width = collectionView.bounds.width
let columns = UIDevice.current.userInterfaceIdiom == .pad ? 4 : 2

// ❌ Fixed layout
layout.itemSize = CGSize(width: 100, height: 100)
```

### 3. Animate Changes
```swift
// ✅ Smooth transitions
collectionView.performBatchUpdates {
    collectionView.insertItems(at: indexPaths)
}

// ❌ Jarring reload
collectionView.reloadData()
```

---

## ❌ Common Mistakes

### Mistake 1: Not Reusing Cells

**WRONG:**
```swift
// ❌ Memory inefficient
func collectionView(_ collectionView: UICollectionView,
                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = PhotoCell()  // Creates new cell every time
    cell.configure(with: photos[indexPath.item])
    return cell
}
```

**CORRECT:**
```swift
// ✅ Dequeue and reuse
func collectionView(_ collectionView: UICollectionView,
                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(
        withReuseIdentifier: "PhotoCell",
        for: indexPath
    ) as! PhotoCell
    cell.configure(with: photos[indexPath.item])
    return cell
}
```

---

### Mistake 2: Heavy Operations in cellForItemAt

**WRONG:**
```swift
// ❌ Blocks UI scrolling
func collectionView(_ collectionView: UICollectionView,
                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let image = heavyImageProcessing(photos[indexPath.item])
    cell.imageView.image = image
    return cell
}
```

**CORRECT:**
```swift
// ✅ Load asynchronously
func collectionView(_ collectionView: UICollectionView,
                    cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath)
    
    Task {
        let image = try await processImage(photos[indexPath.item])
        cell.imageView.image = image
    }
    return cell
}
```

---

### Mistake 3: Not Handling Rotation

**WRONG:**
```swift
// ❌ Layout doesn't adapt
override func viewDidLoad() {
    super.viewDidLoad()
    
    layout.itemSize = CGSize(width: 100, height: 100)
    // Layout fixed regardless of device rotation
}
```

**CORRECT:**
```swift
// ✅ Update layout on rotation
override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
    super.viewWillTransition(to: size, with: coordinator)
    
    coordinator.animate(alongsideChanges: { _ in
        self.updateLayout(for: size)
    })
}
```

---

## Related Topics

- [UITableView](tableview.md)
- [UIView Animations](../../05-features/swiftui-basics.md)
- [Performance Optimization](../07-advanced/performance-optimization.md)

---

**Master UICollectionView for beautiful, efficient grid interfaces!**
