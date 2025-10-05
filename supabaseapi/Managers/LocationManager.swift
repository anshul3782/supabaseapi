import Foundation
import CoreLocation
import Combine
import Supabase

public struct GlobalLocationData: Codable, Identifiable {
    public var id: String { "\(user_id.uuidString)-\(created_at)" }
    public let user_id: UUID
    public let city: String
    public let created_at: String
}

@MainActor
final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    typealias LocationData = GlobalLocationData

    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var isLoading = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let client = SupabaseService().client
    private var permCont: CheckedContinuation<Bool, Never>?

    override init() {
        super.init()
        manager.delegate = self
    }

    func requestPermission() async -> Bool {
        print("Location: Current authorization status: \(manager.authorizationStatus.rawValue)")
        
        return await withCheckedContinuation { cont in
            permCont = cont
            switch manager.authorizationStatus {
            case .notDetermined: 
                print("Location: Requesting when-in-use authorization")
                manager.requestWhenInUseAuthorization()
            case .authorizedAlways, .authorizedWhenInUse: 
                print("Location: Already authorized")
                cont.resume(returning: true)
            default: 
                print("Location: Authorization denied or restricted")
                cont.resume(returning: false)
            }
        }
    }
    func locationManager(_ m: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        if let c = permCont {
            c.resume(returning: status == .authorizedAlways || status == .authorizedWhenInUse)
            permCont = nil
        }
    }

    func fetchCity() async -> String? {
        guard let loc = manager.location else { return nil }
        do {
            let p = try await geocoder.reverseGeocodeLocation(loc)
            return p.first?.locality
        } catch { return nil }
    }

    func insertLocation(userId: UUID, city: String) async throws {
        let row = LocationData(user_id: userId, city: city,
                               created_at: ISO8601DateFormatter().string(from: Date()))
        _ = try await client.from("locations").insert(row).execute()
    }

    func fetchLatest(userId: UUID) async throws -> [LocationData] {
        try await client.from("locations")
            .select()
            .eq("user_id", value: userId.uuidString)
            .order("created_at", ascending: false)
            .limit(1)
            .execute()
            .value
    }
}
