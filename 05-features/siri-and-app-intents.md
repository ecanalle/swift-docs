# Siri and App Intents - Voice Control and Shortcuts

## Overview

Siri integration through App Intents enables voice control, Shortcuts app automation, and Lock Screen widgets. This framework provides seamless voice interaction with your app's core functionality.

## Main Topics

- [App Intents Basics](#app-intents-basics)
- [Creating Intents](#creating-intents)
- [Parameters and Responses](#parameters-and-responses)
- [Siri Suggestions](#siri-suggestions)
- [Shortcuts Integration](#shortcuts-integration)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [App Intents Framework](https://developer.apple.com/documentation/appintents)
- [WWDC 2022: Introducing App Intents](https://developer.apple.com/videos/play/wwdc2022/10169/)
- [Siri Shortcuts Documentation](https://developer.apple.com/documentation/sirikit)

---

## App Intents Basics

### What are App Intents?

App Intents replace SiriKit and provide a modern way to expose app functionality to Siri, Shortcuts, and other system features. They're simpler, more flexible, and deeply integrated with iOS 16+.

**Key Features:**
- Voice control via Siri
- Shortcuts app automation
- Lock Screen widgets
- Focus modes
- Universal clipboard
- Cross-device handoff

### App Intent Structure

```swift
import AppIntents

// Basic structure of an App Intent
struct MakeTeaIntent: AppIntent {
    // MARK: - Metadata
    static let title: LocalizedStringResource = "Make Tea"
    static let description = IntentDescription("Brew a cup of tea")
    static let openAppWhenRun = true
    
    // MARK: - Parameters
    @Parameter(title: "Tea Type", description: "Choose your tea", default: "Green")
    var teaType: String
    
    @Parameter(title: "Temperature", description: "Water temperature in Celsius", default: 80)
    var temperature: Int
    
    // MARK: - Perform
    func perform() async throws -> some IntentResult & OpenAppIntent {
        print("Making \(teaType) tea at \(temperature)°C")
        return .result()
    }
}
```

---

## Creating Intents

### Simple Intent with No Parameters

```swift
import AppIntents

struct StartWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Start Workout"
    static let description = IntentDescription("Begin a new workout session")
    static let openAppWhenRun = true
    
    func perform() async throws -> some IntentResult & OpenAppIntent {
        // Perform workout logic
        WorkoutManager.shared.startWorkout()
        return .result(dialog: "Workout started!")
    }
}
```

### Intent with String Parameter

```swift
import AppIntents

struct SendMessageIntent: AppIntent {
    static let title: LocalizedStringResource = "Send Message"
    static let description = IntentDescription("Send a message to a contact")
    
    @Parameter(title: "Contact", description: "Who to message")
    var contactName: String
    
    @Parameter(title: "Message", description: "Message content")
    var message: String
    
    func perform() async throws -> some IntentResult {
        // ✅ Correct: Validate inputs
        guard !contactName.isEmpty, !message.isEmpty else {
            return .result(dialog: "Both contact and message are required")
        }
        
        try await MessageService.send(message, to: contactName)
        return .result(dialog: "Message sent to \(contactName)")
    }
}
```

### Intent with Enum Parameter

```swift
import AppIntents

enum CoffeeSize: String, AppEnum {
    case small = "S"
    case medium = "M"
    case large = "L"
    case extraLarge = "XL"
    
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Coffee Size")
}

struct OrderCoffeeIntent: AppIntent {
    static let title: LocalizedStringResource = "Order Coffee"
    static let description = IntentDescription("Order a coffee drink")
    
    @Parameter(title: "Size", description: "Coffee size")
    var size: CoffeeSize
    
    @Parameter(title: "Extra Shot", description: "Add extra espresso shot")
    var extraShot: Bool = false
    
    func perform() async throws -> some IntentResult {
        let order = CoffeeOrder(size: size.rawValue, extraShot: extraShot)
        try await CoffeeService.placeOrder(order)
        return .result(dialog: "Your \(size.rawValue) coffee is being prepared")
    }
}
```

---

## Parameters and Responses

### Dynamic Enum Parameters

```swift
import AppIntents

// ✅ Correct: Dynamic list from data
struct PlayPodcastIntent: AppIntent {
    static let title: LocalizedStringResource = "Play Podcast"
    
    @Parameter(
        title: "Podcast",
        description: "Choose a podcast",
        requestValueDialog: IntentRequestValueDialog("Which podcast?")
    )
    var podcast: PodcastEnum
    
    func perform() async throws -> some IntentResult & OpenAppIntent {
        try await PodcastService.play(podcast.id)
        return .result(dialog: "Now playing \(podcast.displayRepresentation.title)")
    }
}

struct PodcastEnum: AppEnum {
    enum ID: Hashable {
        case showId(Int)
    }
    
    let id: ID
    let displayRepresentation: DisplayRepresentation
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Podcast")
    
    static var caseDisplayRepresentations: [Self] {
        PodcastService.allPodcasts.map { podcast in
            Self(
                id: .showId(podcast.id),
                displayRepresentation: DisplayRepresentation(
                    title: "\(podcast.name)",
                    subtitle: podcast.author
                )
            )
        }
    }
}
```

### Intent Results with Data Return

```swift
import AppIntents

struct GetWeatherIntent: AppIntent {
    static let title: LocalizedStringResource = "Get Weather"
    
    @Parameter(title: "City", description: "City name")
    var city: String
    
    func perform() async throws -> some IntentResult {
        let weather = try await WeatherService.fetch(for: city)
        
        return .result(
            dialog: "It's \(weather.temperature)°C and \(weather.condition) in \(city)",
            view: WeatherResultView(weather: weather)
        )
    }
}

struct WeatherResultView: View {
    let weather: Weather
    
    var body: some View {
        VStack {
            Text(weather.condition)
            Text("\(weather.temperature)°C")
        }
    }
}
```

---

## Siri Suggestions

### Donating Intents to Siri

```swift
import AppIntents

// ✅ Correct: Donate intent after action completes
func completeWorkout(_ workout: Workout) {
    // Perform workout
    let intent = LogWorkoutIntent(workoutID: workout.id)
    
    // Donate to Siri
    Task {
        try await intent.perform()
        
        // Tell Siri about this action
        await donate(intent)
    }
}

// Make workouts appear in Siri suggestions
struct LogWorkoutIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Workout"
    static let description = IntentDescription("Record a completed workout")
    
    @Parameter(title: "Workout ID")
    var workoutID: String
    
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "Log Workout")
    }
    
    func perform() async throws -> some IntentResult {
        try await WorkoutService.logWorkout(workoutID)
        return .result()
    }
}
```

---

## Shortcuts Integration

### Creating Shortcut-Friendly Intents

```swift
import AppIntents

struct CreateReminderIntent: AppIntent {
    static let title: LocalizedStringResource = "Create Reminder"
    static let description = IntentDescription("Create a new reminder")
    static let openAppWhenRun = false // Don't open app for Shortcuts automation
    
    @Parameter(title: "Title", description: "Reminder text")
    var title: String
    
    @Parameter(title: "Date", description: "When to remind")
    var date: Date?
    
    func perform() async throws -> some IntentResult {
        let reminder = Reminder(title: title, dueDate: date)
        try await ReminderService.create(reminder)
        
        return .result(
            dialog: "Reminder created: \(title)",
            value: reminder.id
        )
    }
}
```

### Exposing Intent Collections

```swift
import AppIntents

struct ShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartWorkoutIntent(),
            phrases: ["Start \(.applicationName) workout"],
            shortTitle: "Start Workout",
            systemImageName: "figure.walk"
        )
        
        AppShortcut(
            intent: LogMealIntent(),
            phrases: ["Log meal in \(.applicationName)"],
            shortTitle: "Log Meal",
            systemImageName: "fork.knife"
        )
    }
}
```

---

## ✅ Best Practices

### Practice 1: Validate Parameters

**DO:**
```swift
@Parameter(title: "Email", description: "User email")
var email: String

func perform() async throws -> some IntentResult {
    guard email.contains("@") else {
        return .result(dialog: "Invalid email address")
    }
    // Continue...
}
```

### Practice 2: Provide Meaningful Responses

**DO:**
```swift
return .result(
    dialog: "Successfully completed task",
    view: ResultDetailView(result: result)
)
```

### Practice 3: Use Descriptive Titles

**DO:**
```swift
static let title: LocalizedStringResource = "Start 5-Mile Run"
static let description = IntentDescription("Begin a 5-mile running workout")
```

### Practice 4: Donate Frequently Used Actions

**DO:**
```swift
func userCompletedAction() {
    let intent = RecordActionIntent(action: action)
    Task {
        try? await donate(intent)
    }
}
```

---

## ❌ Common Mistakes (Anti-patterns)

### Mistake 1: Too Many Parameters

**WRONG:**
```swift
@Parameter var param1: String
@Parameter var param2: String
@Parameter var param3: String
@Parameter var param4: String
@Parameter var param5: String
@Parameter var param6: String
// Overwhelming for voice control
```

**CORRECT:**
```swift
// Group related parameters or create separate intents
@Parameter(title: "Primary Input")
var mainInput: String

@Parameter(title: "Option", description: "Additional choice")
var option: String
```

### Mistake 2: Opening App Unnecessarily

**WRONG:**
```swift
struct QueryDatabaseIntent: AppIntent {
    static let openAppWhenRun = true // Opens app for simple query
}
```

**CORRECT:**
```swift
struct QueryDatabaseIntent: AppIntent {
    static let openAppWhenRun = false // Only show result in Siri UI
}
```

### Mistake 3: Not Handling Errors

**WRONG:**
```swift
func perform() async throws -> some IntentResult {
    try await service.operation() // May throw
    return .result()
}
```

**CORRECT:**
```swift
func perform() async throws -> some IntentResult {
    do {
        try await service.operation()
        return .result(dialog: "Success")
    } catch {
        return .result(dialog: "Error: \(error.localizedDescription)")
    }
}
```

### Mistake 4: Ignoring Localization

**WRONG:**
```swift
static let title = "Make Coffee"
```

**CORRECT:**
```swift
static let title: LocalizedStringResource = "Make Coffee"
// Automatically translatable for different languages
```

---

## 🔗 Related Topics

- [Widgets](./user-interface-frameworks.md) - Creating Lock Screen widgets
- [Background Modes](../04-app-lifecycle/background-modes.md) - Running tasks in background
- [App Store and Release](../04-app-lifecycle/app-store-and-release.md) - Submitting apps with Siri
- [Notifications](../04-app-lifecycle/notifications.md) - Complementary user communication

---

**Enable powerful voice control with App Intents and Shortcuts integration!**
