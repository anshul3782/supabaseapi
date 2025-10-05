import Foundation
import HealthKit
import Combine
import Supabase

public struct GlobalHealthData: Codable, Identifiable {
    public var id: String { "\(user_id.uuidString)-\(date)" }
    public let user_id: UUID
    public let date: String
    public let steps: Int
    public let heart_rate_avg: Double
    public let sleep_hours: Double
    public let active_calories: Double
    public let distance_km: Double
}

@MainActor
final class HealthKitManager: NSObject, ObservableObject {
    typealias HealthData = GlobalHealthData

    @Published var isLoading = false

    private let healthStore = HKHealthStore()
    private let client = SupabaseService().client

    private var readTypes: Set<HKObjectType> {
        [
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
    }

    func requestPermissions() async -> Bool {
        print("HealthKit: Requesting authorization for types: \(readTypes)")
        
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit: Health data not available on this device")
            return false
        }
        
        do {
            try await healthStore.requestAuthorization(toShare: [], read: readTypes)
            print("HealthKit: Authorization request completed")
            return true
        } catch {
            print("HealthKit: Authorization request failed with error: \(error)")
            return false
        }
    }

    func fetchTodaysHealthData(for userId: UUID) async -> HealthData? {
        isLoading = true; defer { isLoading = false }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date()); let end = Date()

        guard
            let stepType = HKObjectType.quantityType(forIdentifier: .stepCount),
            let hrType   = HKObjectType.quantityType(forIdentifier: .heartRate),
            let energy   = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned),
            let dist     = HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning),
            let sleep    = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
        else { return nil }

        func sum(_ type: HKQuantityType, unit: HKUnit) async -> Double {
            await withCheckedContinuation { cont in
                let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
                let q = HKSampleQuery(sampleType: type, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) {
                    _, samples, _ in
                    let total = (samples as? [HKQuantitySample])?
                        .reduce(0.0) { $0 + $1.quantity.doubleValue(for: unit) } ?? 0.0
                    cont.resume(returning: total)
                }
                self.healthStore.execute(q)
            }
        }
        func avgHR() async -> Double {
            await withCheckedContinuation { cont in
                let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
                let q = HKSampleQuery(sampleType: hrType, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) {
                    _, samples, _ in
                    let arr = (samples as? [HKQuantitySample])?
                        .map { $0.quantity.doubleValue(for: .count().unitDivided(by: .minute())) } ?? []
                    cont.resume(returning: arr.isEmpty ? 0.0 : arr.reduce(0,+)/Double(arr.count))
                }
                self.healthStore.execute(q)
            }
        }
        func sleepHours() async -> Double {
            await withCheckedContinuation { cont in
                let pred = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
                let q = HKSampleQuery(sampleType: sleep, predicate: pred, limit: HKObjectQueryNoLimit, sortDescriptors: nil) {
                    _, samples, _ in
                    let secs = (samples as? [HKCategorySample])?
                        .filter { s in
                            let v = s.value
                            return v == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                                || v == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                                || v == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                                || v == HKCategoryValueSleepAnalysis.asleepREM.rawValue
                        }
                        .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) } ?? 0.0
                    cont.resume(returning: secs/3600.0)
                }
                self.healthStore.execute(q)
            }
        }

        let steps  = Int(await sum(stepType, unit: .count()))
        let hrAvg  = await avgHR()
        let active = await sum(energy, unit: .kilocalorie())
        let distKm = await sum(dist, unit: .meter()) / 1000.0
        let sleepH = await sleepHours()

        let day = ISO8601DateFormatter().string(from: cal.startOfDay(for: Date()))
        return HealthData(user_id: userId, date: day, steps: steps,
                          heart_rate_avg: hrAvg, sleep_hours: sleepH,
                          active_calories: active, distance_km: distKm)
    }

    func upsertToday(_ hd: HealthData) async throws {
        try await client.from("health_data")
            .upsert(hd, onConflict: "user_id,date")
            .execute()
    }

    func fetchToday(for userId: UUID) async throws -> [HealthData] {
        let day = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        return try await client.from("health_data")
            .select()
            .eq("user_id", value: userId.uuidString)
            .eq("date", value: day)
            .execute()
            .value
    }
}
