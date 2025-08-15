import Foundation
import HealthKit
import Combine

/// iOS 17+ only (uses .timeInDaylight); UV exposure is intentionally ignored.
public final class HealthKitManager: ObservableObject {
    @Published public private(set) var snapshot: HealthSnapshot = .zero
    @Published public private(set) var authState: HealthAuthState = .notDetermined

    private let store = HKHealthStore()

    private let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private let exerciseType = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime)!
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let daylightType: HKQuantityType? = {
        if #available(iOS 17.0, *) {
            return HKQuantityType.quantityType(forIdentifier: .timeInDaylight)
        } else {
            return nil // ignore UV exposure
        }
    }()

    public init() {
        requestAuthorization()
    }

    public func requestAuthorization() {
        var toRead: Set<HKObjectType> = [stepType, exerciseType, sleepType]
        if let d = daylightType { toRead.insert(d) }

        store.requestAuthorization(toShare: nil, read: toRead) { [weak self] ok, _ in
            DispatchQueue.main.async {
                guard let self else { return }
                self.authState = ok ? .authorized : .denied
                if ok { self.refreshAll(); self.startObservers() }
            }
        }
    }

    public func refreshAll() {
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let now = Date()

        fetchCumulative(type: stepType, unit: .count(), from: start, to: now) { [weak self] v in
            guard let self else { return }
            var snap = self.snapshot
            snap.stepsToday = v
            self.snapshot = snap
        }
        fetchCumulative(type: exerciseType, unit: .minute(), from: start, to: now) { [weak self] v in
            guard let self else { return }
            var snap = self.snapshot
            snap.exerciseMinutesToday = v
            self.snapshot = snap
        }
        if let daylightType {
            fetchCumulative(type: daylightType, unit: .minute(), from: start, to: now) { [weak self] v in
                guard let self else { return }
                var snap = self.snapshot
                snap.daylightMinutesToday = v
                self.snapshot = snap
            }
        } else {
            DispatchQueue.main.async {
                var snap = self.snapshot
                snap.daylightMinutesToday = 0
                self.snapshot = snap
            }
        }
        fetchLastNightSleepHours { [weak self] h in
            guard let self else { return }
            var snap = self.snapshot
            snap.sleepHoursPrevNight = h
            self.snapshot = snap
        }
    }

    private func fetchCumulative(type: HKQuantityType, unit: HKUnit, from: Date, to: Date, completion: @escaping (Double) -> Void) {
        let pred = HKQuery.predicateForSamples(withStart: from, end: to, options: .strictStartDate)
        let q = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: pred, options: .cumulativeSum) { _, stats, _ in
            let v = stats?.sumQuantity()?.doubleValue(for: unit) ?? 0
            DispatchQueue.main.async { completion(v) }
        }
        store.execute(q)
    }

    private func fetchLastNightSleepHours(completion: @escaping (Double) -> Void) {
        let cal = Calendar.current
        let todayStart = cal.startOfDay(for: Date())
        guard let yesterdayStart = cal.date(byAdding: .day, value: -1, to: todayStart) else { completion(0); return }
        let pred = HKQuery.predicateForSamples(withStart: yesterdayStart, end: todayStart, options: .strictStartDate)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let q = HKSampleQuery(sampleType: sleepType, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, samples, _ in
            let secs: Double = (samples as? [HKCategorySample])?
                .filter { s in
                    s.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue ||
                    s.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue ||
                    s.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue ||
                    s.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                }
                .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0
            DispatchQueue.main.async { completion(secs / 3600.0) }
        }
        store.execute(q)
    }

    private func startObservers() {
        startObserver(for: stepType)
        startObserver(for: exerciseType)
        if let daylightType { startObserver(for: daylightType) }
        startObserver(for: sleepType)
    }

    private func startObserver(for type: HKSampleType) {
        let obs = HKObserverQuery(sampleType: type, predicate: nil) { [weak self] _, completion, _ in
            self?.refreshAll()
            completion()
        }
        store.execute(obs)
        store.enableBackgroundDelivery(for: type, frequency: .immediate) { _, _ in }
    }
}
