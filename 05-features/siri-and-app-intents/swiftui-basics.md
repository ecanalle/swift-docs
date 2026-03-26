# SwiftUI Fundamentals

## Overview

SwiftUI is Apple's modern declarative UI framework. It provides a fundamental shift from UIKit's imperative approach, making UI code more concise, reactive, and easier to maintain through data-driven views.

## Main Topics

- [SwiftUI Basics](#swiftui-basics)
- [View Hierarchy](#view-hierarchy)
- [State and Binding](#state-and-binding)
- [Modifiers](#modifiers)
- [Navigation](#navigation)
- [Data Flow](#data-flow)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [WWDC: SwiftUI Essentials](https://developer.apple.com/videos/play/wwdc2023/10154/)

---

## SwiftUI Basics

### Creating Your First View

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("Hello, SwiftUI!")
                .font(.title)
            
            Button("Tap Me") {
                print("Button tapped")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
```

### View Composition

```swift
struct ContentView: View {
    var body: some View {
        VStack {
            HeaderView()
            
            ForEach(1...5, id: \.self) { i in
                ItemRow(number: i)
            }
            
            Spacer()
            
            BottomButtonView()
        }
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Title").font(.headline)
                Text("Subtitle").font(.caption)
            }
            Spacer()
            Image(systemName: "gear")
        }
        .padding()
    }
}

struct ItemRow: View {
    let number: Int
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: 50, height: 50)
            
            VStack(alignment: .leading) {
                Text("Item \(number)").font(.headline)
                Text("Description").font(.caption)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct BottomButtonView: View {
    var body: some View {
        Button(action: {}) {
            Label("Add", systemImage: "plus")
        }
        .buttonStyle(.bordered)
    }
}
```

---

## View Hierarchy

### Container Views

```swift
struct LayoutExample: View {
    var body: some View {
        // VStack - vertical stacking
        VStack(alignment: .center, spacing: 10) {
            Text("Top")
            Text("Middle")
            Text("Bottom")
        }
        
        // HStack - horizontal stacking
        HStack(alignment: .top) {
            Text("Left")
            Spacer()
            Text("Right")
        }
        
        // ZStack - layering
        ZStack {
            Color.blue
            Text("On top").foregroundColor(.white)
        }
    }
}
```

### Spacing and Sizing

```swift
struct SpacingExample: View {
    var body: some View {
        VStack(spacing: 10) {
            // Flexible sizing
            VStack {
                Text("Grows to fill").frame(maxHeight: .infinity)
            }
            .frame(height: 100)
            
            // Fixed sizing
            Text("Fixed").frame(width: 100, height: 50)
            
            // Relative sizing
            Rectangle()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Spacer for flexible spacing
            VStack {
                Text("Top")
                Spacer()  // Takes all available space
                Text("Bottom")
            }
        }
    }
}
```

---

## State and Binding

### @State Property

```swift
struct CounterView: View {
    @State private var count = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Count: \(count)")
                .font(.title)
            
            Button("Increment") {
                count += 1
            }
            
            Button("Decrement") {
                count -= 1
            }
        }
    }
}
```

### @Binding Property

```swift
struct ParentView: View {
    @State private var isToggled = false
    
    var body: some View {
        VStack {
            Text("Toggle status: \(isToggled ? "ON" : "OFF")")
            
            ChildView(isToggled: $isToggled)  // Pass binding with $
        }
    }
}

struct ChildView: View {
    @Binding var isToggled: Bool  // Receive as binding
    
    var body: some View {
        Toggle("Toggle", isOn: $isToggled)
    }
}
```

### @StateObject and @ObservedObject

```swift
class UserModel: ObservableObject {
    @Published var name = "John"
    @Published var age = 30
    
    func birthday() {
        age += 1
    }
}

struct UserProfileView: View {
    @StateObject private var user = UserModel()  // Owns the object
    
    var body: some View {
        VStack {
            TextField("Name", text: $user.name)
            Text("Age: \(user.age)")
            
            Button("Birthday") {
                user.birthday()
            }
        }
    }
}

// When passed to child view, use @ObservedObject
struct UserDetailsView: View {
    @ObservedObject var user: UserModel  // Observes, doesn't own
    
    var body: some View {
        Text("\(user.name) is \(user.age) years old")
    }
}
```

---

## Modifiers

### Common Modifiers

```swift
struct ModifierExample: View {
    var body: some View {
        VStack(spacing: 20) {
            // Text modifiers
            Text("Title")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.blue)
                .lineLimit(1)
            
            // Background and border
            Text("Styled")
                .padding()
                .background(Color.blue)
                .cornerRadius(8)
                .shadow(radius: 5)
            
            // Opacity and rotation
            Image(systemName: "star.fill")
                .opacity(0.5)
                .rotationEffect(.degrees(45))
                .scaleEffect(1.5)
            
            // Gestures
            Text("Tap me")
                .onTapGesture {
                    print("Tapped")
                }
        }
    }
}
```

### Combining Modifiers

```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue)
        .foregroundColor(.white)
        .cornerRadius(8)
    }
}
```

---

## Navigation

### NavigationStack (iOS 16+)

```swift
struct NavigationExample: View {
    @State private var path: [Int] = []
    
    var body: some View {
        NavigationStack(path: $path) {
            VStack {
                NavigationLink("Go to Detail", value: 1)
                NavigationLink("Go to Settings", value: 2)
            }
            .navigationDestination(for: Int.self) { value in
                if value == 1 {
                    DetailView()
                } else {
                    SettingsView()
                }
            }
        }
    }
}

struct DetailView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Detail View")
            Button("Go Back") {
                dismiss()
            }
        }
    }
}

struct SettingsView: View {
    var body: some View {
        Text("Settings View")
    }
}
```

### Sheet Navigation

```swift
struct SheetExample: View {
    @State private var showSheet = false
    @State private var selectedItem: String?
    
    var body: some View {
        VStack {
            Button("Show Sheet") {
                showSheet = true
            }
        }
        .sheet(isPresented: $showSheet) {
            ModalView(isPresented: $showSheet)
        }
    }
}

struct ModalView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack {
            HStack {
                Text("Modal").font(.headline)
                Spacer()
                Button("Done") {
                    isPresented = false
                }
            }
            .padding()
            
            Spacer()
        }
    }
}
```

---

## Data Flow

### Environment and EnvironmentObject

```swift
class AppSettings: ObservableObject {
    @Published var isDarkMode = false
}

@main
struct MyApp: App {
    @StateObject private var settings = AppSettings()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settings)  // Inject into tree
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var settings: AppSettings
    
    var body: some View {
        VStack {
            Toggle("Dark Mode", isOn: $settings.isDarkMode)
        }
        .background(settings.isDarkMode ? Color.black : Color.white)
    }
}
```

---

## 🎯 Best Practices

### 1. Keep Views Small
- Compose views from smaller pieces
- Each view should have single responsibility
- Makes previews and reuse easier

### 2. Use @State for Local State
- Private, limited scope
- Owned and managed by view

### 3. Extract Subviews Early
- Even for small pieces
- Improves readability
- Enables reuse

### 4. Use Proper Property Wrappers
- @State for local values
- @StateObject for owned objects
- @ObservedObject for observed objects
- @Environment for system values

### 5. Preview Everything
- Use #Preview for testing
- Catch layout issues early
- Much faster than running full app

---

## ❌ Common Mistakes

### Mistake 1: Large Monolithic Views

**WRONG:**
```swift
struct MainView: View {
    var body: some View {
        VStack {
            // 500 lines of UI code
        }
    }
}
```

**CORRECT:**
```swift
struct MainView: View {
    var body: some View {
        VStack {
            HeaderSection()
            ContentSection()
            FooterSection()
        }
    }
}

struct HeaderSection: View { /*...*/ }
struct ContentSection: View { /*...*/ }
struct FooterSection: View { /*...*/ }
```

---

### Mistake 2: Not Using @Published

**WRONG:**
```swift
class ViewModel {
    var count = 0  // Changes don't update UI
}
```

**CORRECT:**
```swift
class ViewModel: ObservableObject {
    @Published var count = 0  // Changes automatically update UI
}
```

---

### Mistake 3: State in the Wrong Place

**WRONG:**
```swift
struct ParentView: View {
    var body: some View {
        ChildView()
    }
}

struct ChildView: View {
    @State var value = ""  // Parent can't access
}
```

**CORRECT:**
```swift
struct ParentView: View {
    @State private var value = ""
    
    var body: some View {
        ChildView(value: $value)
    }
}

struct ChildView: View {
    @Binding var value: String
}
```

---

## Related Topics

- [View Modifiers](../../swiftui-avancado/)
- [SwiftUI Architecture](../../02-architecture/swiftui-architecture.md)
- [Animations in SwiftUI](../../01-fundamentals/animation-in-swift/swiftui-animations.md)

---

**Master SwiftUI to build modern, reactive user interfaces!**
