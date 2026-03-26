# EventKit - Calendar and Reminders

## Overview

EventKit manages calendar events and reminders. It provides access to user calendars, event creation, and reminder management.

## Main Topics

- [Calendar Access](#calendar-access)
- [Creating Events](#creating-events)
- [Reminders](#reminders)
- [Permission Handling](#permission-handling)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [EventKit](https://developer.apple.com/documentation/eventkit)

---

## Calendar Access

### Reading Events

```swift
import EventKit

class CalendarManager {
    static let shared = CalendarManager()
    
    let eventStore = EKEventStore()
    
    func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                completion(granted)
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                completion(granted)
            }
        }
    }
    
    func fetchUpcomingEvents(daysAhead: Int = 7) -> [EKEvent] {
        let calendar = Calendar.current
        let startDate = Date()
        guard let endDate = calendar.date(byAdding: .day, value: daysAhead, to: startDate) else {
            return []
        }
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        return eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
    }
    
    func getEventsByCalendar(_ calendar: EKCalendar, from startDate: Date, to endDate: Date) -> [EKEvent] {
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: [calendar]
        )
        
        return eventStore.events(matching: predicate)
    }
    
    func getAvailableCalendars() -> [EKCalendar] {
        return eventStore.calendars(for: .event)
    }
}
```

### Searching Events

```swift
import EventKit

class EventSearcher {
    let eventStore = EKEventStore()
    
    func findEventsByTitle(_ title: String) -> [EKEvent] {
        let calendar = Calendar.current
        let startDate = calendar.date(byAdding: .month, value: -12, to: Date()) ?? Date()
        let endDate = calendar.date(byAdding: .month, value: 12, to: Date()) ?? Date()
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        return events.filter { $0.title.localizedCaseInsensitiveContains(title) }
    }
    
    func findEventsByLocation(_ location: String) -> [EKEvent] {
        let calendar = Calendar.current
        let startDate = Date()
        let endDate = calendar.date(byAdding: .day, value: 30, to: startDate) ?? Date()
        
        let predicate = eventStore.predicateForEvents(
            withStart: startDate,
            end: endDate,
            calendars: nil
        )
        
        let events = eventStore.events(matching: predicate)
        return events.filter { $0.location?.localizedCaseInsensitiveContains(location) ?? false }
    }
}
```

---

## Creating Events

### Adding Calendar Events

```swift
import EventKit

class EventCreator {
    let eventStore = EKEventStore()
    
    func createEvent(title: String, startDate: Date, endDate: Date, location: String? = nil) throws -> EKEvent {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = endDate
        event.location = location
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .thisEvent)
        return event
    }
    
    func createRepeatingEvent(title: String, startDate: Date, recurrenceRule: EKRecurrenceRule) throws {
        let event = EKEvent(eventStore: eventStore)
        event.title = title
        event.startDate = startDate
        event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate) ?? startDate
        event.addRecurrenceRule(recurrenceRule)
        event.calendar = eventStore.defaultCalendarForNewEvents
        
        try eventStore.save(event, span: .futureEvents)
    }
    
    func createDailyEvent(_ title: String, at time: Date, for daysCount: Int = 365) throws {
        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: daysCount, to: time) ?? time
        
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .daily,
            interval: 1,
            end: EKRecurrenceEnd(endDate: endDate)
        )
        
        try createRepeatingEvent(title: title, startDate: time, recurrenceRule: recurrenceRule)
    }
    
    func createWeeklyEvent(_ title: String, on day: EKWeekday, at time: Date) throws {
        let recurrenceRule = EKRecurrenceRule(
            recurrenceWith: .weekly,
            interval: 1,
            daysOfTheWeek: [EKRecurrenceDayOfWeek(day)]
        )
        
        try createRepeatingEvent(title: title, startDate: time, recurrenceRule: recurrenceRule)
    }
}
```

---

## Reminders

### Managing Reminders

```swift
import EventKit

class ReminderManager {
    let eventStore = EKEventStore()
    
    func requestReminderAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                completion(granted)
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, error in
                completion(granted)
            }
        }
    }
    
    func createReminder(title: String, dueDate: Date? = nil, notes: String? = nil) throws {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        reminder.notes = notes
        
        if let dueDate = dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)
        }
        
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        try eventStore.save(reminder, commit: true)
    }
    
    func getReminders() -> [EKReminder] {
        guard let reminderList = eventStore.defaultCalendarForNewReminders() else {
            return []
        }
        
        let predicate = eventStore.predicateForReminders(in: [reminderList])
        var reminders: [EKReminder] = []
        
        eventStore.enumerateReminders(matching: predicate) { reminder in
            reminders.append(reminder)
        }
        
        return reminders
    }
    
    func completeReminder(_ reminder: EKReminder) throws {
        reminder.isCompleted = true
        try eventStore.save(reminder, commit: true)
    }
    
    func deleteReminder(_ reminder: EKReminder) throws {
        try eventStore.remove(reminder, commit: true)
    }
}
```

### Time-based Reminders

```swift
import EventKit

class TimeBasedReminder {
    let eventStore = EKEventStore()
    
    func createReminderWithTime(title: String, minutesBefore: Int = 15) throws {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = title
        
        let alarm = EKAlarm(relativeOffset: TimeInterval(-minutesBefore * 60))
        reminder.addAlarm(alarm)
        
        reminder.calendar = eventStore.defaultCalendarForNewReminders()
        
        try eventStore.save(reminder, commit: true)
    }
    
    func setDueDateAndReminder(reminder: EKReminder, dueDate: Date, minutesBefore: Int) throws {
        reminder.dueDateComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: dueDate
        )
        
        let alarm = EKAlarm(relativeOffset: TimeInterval(-minutesBefore * 60))
        reminder.addAlarm(alarm)
        
        try eventStore.save(reminder, commit: true)
    }
}
```

---

## Permission Handling

### Access Control

```swift
import EventKit

class EventKitPermissionManager {
    static let shared = EventKitPermissionManager()
    
    let eventStore = EKEventStore()
    
    func checkCalendarPermission() -> EKAuthorizationStatus {
        if #available(iOS 17.0, *) {
            return EKEventStore.authorizationStatus(for: .event)
        } else {
            return EKEventStore.authorizationStatus(for: .event)
        }
    }
    
    func checkReminderPermission() -> EKAuthorizationStatus {
        if #available(iOS 17.0, *) {
            return EKEventStore.authorizationStatus(for: .reminder)
        } else {
            return EKEventStore.authorizationStatus(for: .reminder)
        }
    }
    
    func requestAllPermissions(completion: @escaping (Bool, Bool) -> Void) {
        var calendarGranted = false
        var reminderGranted = false
        var completed = 0
        
        func checkCompletion() {
            completed += 1
            if completed == 2 {
                completion(calendarGranted, reminderGranted)
            }
        }
        
        requestCalendarAccess { granted in
            calendarGranted = granted
            checkCompletion()
        }
        
        requestReminderAccess { granted in
            reminderGranted = granted
            checkCompletion()
        }
    }
    
    private func requestCalendarAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                completion(granted)
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                completion(granted)
            }
        }
    }
    
    private func requestReminderAccess(completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToReminders { granted, error in
                completion(granted)
            }
        } else {
            eventStore.requestAccess(to: .reminder) { granted, error in
                completion(granted)
            }
        }
    }
}
```

---

## 🎯 Best Practices

### 1. Request Permissions First
```swift
// ✅ Check and request before access
CalendarManager.shared.requestCalendarAccess { granted in
    if granted {
        let events = CalendarManager.shared.fetchUpcomingEvents()
    }
}

// ❌ Access without permission
let events = eventStore.events(matching: predicate)
```

### 2. Use Correct Span
```swift
// ✅ Use appropriate span
try eventStore.save(event, span: .thisEvent)

// ❌ Modify all recurring instances unintentionally
try eventStore.save(event, span: .futureEvents)
```

### 3. Handle Errors
```swift
// ✅ Handle save errors
do {
    try eventStore.save(event, span: .thisEvent)
} catch {
    print("Error: \(error)")
}

// ❌ Ignore errors
try? eventStore.save(event, span: .thisEvent)
```

---

## ❌ Common Mistakes

### Mistake 1: No Permission Check

**WRONG:**
```swift
// ❌ May fail silently
let events = eventStore.events(matching: predicate)
```

**CORRECT:**
```swift
// ✅ Check permission first
eventStore.requestAccess(to: .event) { granted, _ in
    if granted {
        let events = self.eventStore.events(matching: predicate)
    }
}
```

---

## Related Topics

- [Notifications](notifications.md)
- [UserDefaults - Preferences](userdefaults.md)
- [Background Tasks](../04-app-lifecycle/app-lifecycle.md)

---

**Integrate with user calendars and reminders!**
