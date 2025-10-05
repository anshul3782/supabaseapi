import SwiftUI
import Supabase
import PostgREST
import HealthKit
import Foundation
import CoreLocation
import Foundation

// Use the same client everywhere via SupabaseService
private let client = SupabaseService().client

struct ContentView: View {
    // Managers
    @StateObject private var health = HealthKitManager()
    @StateObject private var location = LocationManager()
    @StateObject private var contacts = ContactsManager()   // assumes you already have this

    // Core fields
    @State private var userIdString: String = "00000000-0000-0000-0000-000000000001"
    @State private var name: String = "test_user"

    // Device values (not DB)
    @State private var steps: Int = 0
    @State private var hrAvg: Double = 0
    @State private var sleepHrs: Double = 0
    @State private var calories: Double = 0
    @State private var distanceKm: Double = 0
    @State private var city: String = ""
    @State private var contactsCount: Int = 0

    // Server values (what we read back from DB)
    @State private var serverHealthSummary: String = ""
    @State private var serverLocationSummary: String = ""
    @State private var serverContactsSummary: String = ""

    // UX
    @State private var message: String = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("User")) {
                    TextField("User ID (UUID)", text: $userIdString)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Name / Username", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()

                    HStack {
                        Button("Save User → DB", action: saveUserToDB)
                        Spacer()
                        Button("Load Users Count") {
                            Task { await loadUsersCount() }
                        }
                    }
                }

                Section(header: Text("Apple Health — Today")) {
                    HStack { Text("Steps"); Spacer(); Text("\(steps)") }
                    HStack { Text("HR Avg"); Spacer(); Text("\(Int(hrAvg)) bpm") }
                    HStack { Text("Sleep"); Spacer(); Text(String(format: "%.1f h", sleepHrs)) }
                    HStack { Text("Active Cal"); Spacer(); Text("\(Int(calories))") }
                    HStack { Text("Distance"); Spacer(); Text(String(format: "%.2f km", distanceKm)) }

                    HStack {
                        Button(health.isLoading ? "Reading…" : "Read From Device") {
                            Task { await readHealthFromDevice() }
                        }
                        .disabled(health.isLoading)

                        Spacer()

                        Button("Save → DB") {
                            Task { await saveHealthToDB() }
                        }

                        Spacer()

                        Button("Load From DB") {
                            Task { await loadHealthFromDB() }
                        }
                    }

                    if !serverHealthSummary.isEmpty {
                        Text("DB: \(serverHealthSummary)").font(.footnote)
                    }
                }

                Section(header: Text("Location")) {
                    HStack { Text("City"); Spacer(); Text(city.isEmpty ? "-" : city) }
                    HStack {
                        Button(location.isLoading ? "Getting…" : "Get From Device") {
                            Task { await getCityFromDevice() }
                        }
                        .disabled(location.isLoading)

                        Spacer()

                        Button("Save → DB") {
                            Task { await saveLocationToDB() }
                        }

                        Spacer()

                        Button("Load From DB") {
                            Task { await loadLocationFromDB() }
                        }
                    }
                    if !serverLocationSummary.isEmpty {
                        Text("DB: \(serverLocationSummary)").font(.footnote)
                    }
                }

                Section(header: Text("Contacts")) {
                    HStack { Text("Count (device→DB)"); Spacer(); Text("\(contactsCount)") }
                    HStack {
                        Button(contacts.isLoading ? "Syncing…" : "Sync Device → DB") {
                            Task { await syncContactsToDB() }
                        }
                        .disabled(contacts.isLoading)

                        Spacer()

                        Button("Load From DB") {
                            Task { await loadContactsFromDB() }
                        }
                    }
                    if !serverContactsSummary.isEmpty {
                        Text("DB: \(serverContactsSummary)").font(.footnote)
                    }
                }

                if !message.isEmpty {
                    Section {
                        Text(message)
                            .foregroundColor(.white)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(message.starts(with: "✅") ? .green.opacity(0.9) : .red.opacity(0.9))
                            .cornerRadius(8)
                    }
                }
            }
            .navigationTitle("Cheakin — Debug Console")
        }
    }

    // MARK: - Utilities
    private var userId: UUID? { UUID(uuidString: userIdString) }

    private func flash(_ text: String, success: Bool) {
        message = (success ? "✅ " : "⛔️ ") + text
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) { message = "" }
    }

    // MARK: - Users
    private func saveUserToDB() {
        guard let id = userId, !name.isEmpty else { flash("Invalid user id or name", success: false); return }
        Task {
            struct UserRow: Codable {
                let id: UUID
                let username: String
                let display_name: String?
            }
            do {
                let row = UserRow(id: id, username: name, display_name: name)
                try await client.from("users").upsert(row, onConflict: "id").execute()
                flash("Saved user", success: true)
            } catch {
                flash("Save user failed: \(error.localizedDescription)", success: false)
            }
        }
    }
    private func loadUsersCount() async {
        do {
            // simplest & reliable: fetch typed rows and count
            let rows: [User] = try await client
                .from("users")
                .select()            // or .select("id") if you want just ids
                .execute()
                .value

            flash("Users in DB: \(rows.count)", success: true)
        } catch {
            flash("Load users failed: \(error.localizedDescription)", success: false)
        }
    }


    // MARK: - Health
    private func readHealthFromDevice() async {
        guard await health.requestPermissions() else {
            flash("Health permission denied", success: false); return
        }
        guard let id = userId, let hd = await health.fetchTodaysHealthData(for: id) else {
            flash("Failed to read Health", success: false); return
        }
        steps = hd.steps
        hrAvg = hd.heart_rate_avg
        sleepHrs = hd.sleep_hours
        calories = hd.active_calories
        distanceKm = hd.distance_km
        flash("Read Health from device", success: true)
    }

    private func saveHealthToDB() async {
        guard let id = userId else { flash("Invalid user id", success: false); return }
        // Build a HealthData row with current state
        let day = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        let hd = HealthKitManager.HealthData(
            user_id: id, date: day, steps: steps,
            heart_rate_avg: hrAvg, sleep_hours: sleepHrs,
            active_calories: calories, distance_km: distanceKm
        )
        do {
            try await health.upsertToday(hd)
            flash("Saved health to DB", success: true)
        } catch {
            flash("Save health failed: \(error.localizedDescription)", success: false)
        }
    }

    private func loadHealthFromDB() async {
        guard let id = userId else { flash("Invalid user id", success: false); return }
        do {
            let rows = try await health.fetchToday(for: id)
            if let r = rows.first {
                serverHealthSummary = "steps \(r.steps), hr \(Int(r.heart_rate_avg)), sleep \(String(format: "%.1f", r.sleep_hours))h, cal \(Int(r.active_calories)), dist \(String(format: "%.2f", r.distance_km))km"
                flash("Loaded health from DB", success: true)
            } else {
                serverHealthSummary = "no row for today"
                flash("No health row found for today", success: false)
            }
        } catch {
            flash("Load health failed: \(error.localizedDescription)", success: false)
        }
    }

    // MARK: - Location
    private func getCityFromDevice() async {
        guard await location.requestPermission() else {
            flash("Location permission denied", success: false); return
        }
        if let c = await location.fetchCity() {
            city = c
            flash("Got city from device", success: true)
        } else {
            flash("Could not resolve city", success: false)
        }
    }

    private func saveLocationToDB() async {
        guard let id = userId, !city.isEmpty else { flash("Invalid user id or empty city", success: false); return }
        do {
            try await location.insertLocation(userId: id, city: city)
            flash("Saved location to DB", success: true)
        } catch {
            flash("Save location failed: \(error.localizedDescription)", success: false)
        }
    }

    private func loadLocationFromDB() async {
        guard let id = userId else { flash("Invalid user id", success: false); return }
        do {
            let rows = try await location.fetchLatest(userId: id)
            if let r = rows.first {
                serverLocationSummary = "\(r.city) @ \(r.created_at)"
                flash("Loaded location from DB", success: true)
            } else {
                serverLocationSummary = "no recent row"
                flash("No location row found", success: false)
            }
        } catch {
            flash("Load location failed: \(error.localizedDescription)", success: false)
        }
    }

    // MARK: - Contacts
    private func syncContactsToDB() async {
        guard let id = userId else { flash("Invalid user id", success: false); return }
        let result = await contacts.syncContactsToSupabase(userId: id)
        switch result {
        case .success(let count):
            contactsCount = count
            flash("Synced \(count) contacts to DB", success: true)
        case .failure(let error):
            flash("Contacts sync failed: \(error.localizedDescription)", success: false)
        }
    }

    
    private func loadContactsFromDB() async {
        guard let id = userId else { flash("Invalid user id", success: false); return }
        let result = await contacts.fetchContactsFromSupabase(userId: id)
        switch result {
        case .success(let data):
            serverContactsSummary = "rows in DB for user: \(data.count)"
            flash("Loaded contacts from DB", success: true)
        case .failure(let error):
            flash("Load contacts failed: \(error.localizedDescription)", success: false)
        }
    }
}


#Preview { ContentView() }
