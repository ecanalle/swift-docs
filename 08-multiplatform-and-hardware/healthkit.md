# HealthKit - Health and Fitness Data

## Overview

HealthKit provides access to health and fitness data collected on device. It requires user permission and supports various health metrics.

## Main Topics

- [Permission and Authorization](#permission-and-authorization)
- [Reading Health Data](#reading-health-data)
- [Writing Health Data](#writing-health-data)
- [Queries](#queries)
- [Best Practices](#-best-practices)
- [Common Mistakes](#-common-mistakes)

## Official Documentation

- [HealthKit](https://developer.apple.com/documentation/healthkit)

---

## Permission and Authorization

### Requesting Access

```swift
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    
    let healthStore = HKHealthStore()
    
    func requestHealthKitAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false)
            return
        }
        
        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKObjectType.workoutType()
        ]
        
        let shareTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .stepCount)!
        ]
        
        healthStore.requestAuthorization(toShare: shareTypes, read: readTypes) { success, error in
            if success {
                print("HealthKit authorization granted")
            } else if let error = error {
                print("HealthKit authorization error: \(error)")
            }
            completion(success)
        }
    }
    
    func isHealthDataAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
}
```

---

## Reading Health Data

### Fetching Step Count

```swift
import HealthKit

class StepCountReader {
    let healthStore = HKHealthStore()
    
    func getStepsForToday(completion: @escaping (Int) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(0)
            return
        }
        
        let now = Date()
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: now,
            options: .strictStartDate
        )
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0)
                return
            }
            
            let steps = Int(sum.doubleValue(for: HKUnit.count()))
            completion(steps)
        }
        
        healthStore.execute(query)
    }
    
    func getHeartRate(completion: @escaping (Double) -> Void) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
            completion(0)
            return
        }
        
        let query = HKSampleQuery(
            sampleType: heartRateType,
            predicate: HKQuery.predicateForSamples(withStart: Date().addingTimeInterval(-3600), end: Date()),
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { _, samples, _ in
            guard let sample = samples?.first as? HKQuantitySample else {
                completion(0)
                return
            }
            
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            completion(heartRate)
        }
        
        healthStore.execute(query)
    }
}
```

### Fetching Workout Data

```swift
import HealthKit

class WorkoutReader {
    let healthStore = HKHealthStore()
    
    func getRecentWorkouts(completion: @escaping ([HKWorkout]) -> Void) {
        let workoutType = HKWorkoutType.workoutType()
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-7 * 24 * 3600),  // Last 7 days
            end: Date()
        )
        
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { _, samples, _ in
            let workouts = samples as? [HKWorkout] ?? []
            completion(workouts)
        }
        
        healthStore.execute(query)
    }
    
    func getTotalWorkoutDuration(completion: @escaping (TimeInterval) -> Void) {
        let workoutType = HKWorkoutType.workoutType()
        
        let predicate = HKQuery.predicateForSamples(
            withStart: Date().addingTimeInterval(-30 * 24 * 3600),  // Last 30 days
            end: Date()
        )
        
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { _, samples, _ in
            let workouts = samples as? [HKWorkout] ?? []
            let totalDuration = workouts.reduce(0) { $0 + $1.duration }
            completion(totalDuration)
        }
        
        healthStore.execute(query)
    }
}
```

---

## Writing Health Data

### Saving Workout Data

```swift
import HealthKit

class WorkoutRecorder {
    let healthStore = HKHealthStore()
    
    func recordWorkout(type: HKWorkoutActivityType, duration: TimeInterval, calories: Double) throws {
        let startDate = Date().addingTimeInterval(-duration)
        let endDate = Date()
        
        let energyUnit = HKUnit.kilocalorie()
        let energySample = HKQuantitySample(
            type: HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            quantity: HKQuantity(unit: energyUnit, doubleValue: calories),
            start: startDate,
            end: endDate
        )
        
        let workout = HKWorkout(
            activityType: type,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: HKQuantity(unit: energyUnit, doubleValue: calories),
            totalDistance: nil,
            metadata: nil
        )
        
        try healthStore.save([workout, energySample])
    }
    
    func saveSteps(_ stepCount: Int, date: Date) throws {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let quantity = HKQuantity(unit: HKUnit.count(), doubleValue: Double(stepCount))
        let sample = HKQuantitySample(type: stepType, quantity: quantity, start: date, end: date)
        
        try healthStore.save(sample)
    }
}
```

---

## Queries

### Observing Data Changes

```swift
import HealthKit

class HealthDataObserver {
    let healthStore = HKHealthStore()
    var observer: HKObserverQuery?
    var onDataUpdated: (() -> Void)?
    
    func startObservingSteps() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            return
        }
        
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { _, _, error in
            if error != nil {
                print("Observer query error")
            } else {
                // Data updated
                self.onDataUpdated?()
            }
        }
        
        healthStore.execute(query)
        self.observer = query
    }
    
    func stopObserving() {
        if let observer = observer {
            healthStore.stop(observer)
        }
    }
}

// Usage
let observer = HealthDataObserver()
observer.onDataUpdated = {
    print("Health data updated")
}
observer.startObservingSteps()
```

### Statistics Query

```swift
import HealthKit

class HealthStatistics {
    let healthStore = HKHealthStore()
    
    func getDailyStepStatistics(for date: Date, completion: @escaping (HKStatistics?) -> Void) {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay)
        
        let query = HKStatisticsQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum
        ) { _, result, _ in
            completion(result)
        }
        
        healthStore.execute(query)
    }
}
```

---

## 🎯 Best Practices

### 1. Always Request Permission
```swift
// ✅ Request before accessing
HealthKitManager.shared.requestHealthKitAuthorization { granted in
    if granted {
        // Access health data
    }
}

// ❌ Access without permission
try healthStore.save(sample)  // May fail
```

### 2. Check Data Availability
```swift
// ✅ Verify device supports HealthKit
if HKHealthStore.isHealthDataAvailable() {
    // Safe to use HealthKit
}

// ❌ Assume data is available
```

### 3. Use Background Execution
```swift
// ✅ Execute queries in background
DispatchQueue.global().async {
    self.healthStore.execute(query)
}

// ❌ Block main thread
self.healthStore.execute(query)  // UI freezes
```

---

## ❌ Common Mistakes

### Mistake 1: No Permission Check

**WRONG:**
```swift
// ❌ No authorization
try healthStore.save(sample)  // May fail
```

**CORRECT:**
```swift
// ✅ Request first
requestHealthKitAuthorization { granted in
    if granted {
        try? self.healthStore.save(sample)
    }
}
```

---

### Mistake 2: Blocking Main Thread

**WRONG:**
```swift
// ❌ Blocking UI
let query = HKSampleQuery(...) { _, samples, _ in
    // Executes on main thread by default
    updateUI()
}
healthStore.execute(query)
```

**CORRECT:**
```swift
// ✅ Use background queue
DispatchQueue.global().async {
    let query = HKSampleQuery(...) { _, samples, _ in
        DispatchQueue.main.async {
            self.updateUI()
        }
    }
    self.healthStore.execute(query)
}
```

---

## Related Topics

- [CoreMotion - Motion Data](.)
- [Background Tasks](../04-app-lifecycle/app-lifecycle.md)
- [Async/Await](../02-concurrency/async-await.md)

---

**Track health metrics with HealthKit!**
