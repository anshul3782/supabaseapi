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
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 10 // Update every 10 meters
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
        // Start location updates if not already started
        if manager.location == nil {
            manager.startUpdatingLocation()
            
            // Wait for location update
            try? await Task.sleep(nanoseconds: 3_000_000_000) // Wait 3 seconds for location
        }
        
        guard let loc = manager.location else { 
            print("Location: No location available")
            return nil 
        }
        
        print("Location: Got location: \(loc.coordinate.latitude), \(loc.coordinate.longitude)")
        
        do {
            let p = try await geocoder.reverseGeocodeLocation(loc)
            let city = p.first?.locality ?? "Unknown City"
            print("Location: Resolved city: \(city)")
            return city
        } catch { 
            print("Location: Reverse geocoding failed: \(error)")
            return nil 
        }
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
