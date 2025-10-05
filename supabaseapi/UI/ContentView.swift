import SwiftUI
import Supabase

struct User: Codable, Identifiable {
    let id: UUID
    let username: String
    let display_name: String?
    let created_at: String?
}

struct ContentView: View {
    @StateObject private var health = HealthKitManager()
    @StateObject private var location = LocationManager()
    @StateObject private var contacts = ContactsManager()
    @StateObject private var toast = ToastCenter()
    
    @State private var users: [User] = []
    @State private var selectedUserId: UUID?
    @State private var isLoading = false
    
    // Health form fields
    @State private var steps = ""
    @State private var heartRate = ""
    @State private var sleepHours = ""
    @State private var activeCalories = ""
    @State private var distanceKm = ""
    
    // Location form fields
    @State private var city = ""
    
    // Contacts form fields
    @State private var contactName = ""
    @State private var contactPhone = ""
    @State private var contactEmail = ""
    
    // Add user form
    @State private var newUsername = ""
    @State private var newDisplayName = ""
    @State private var showingAddUser = false

    var body: some View {
        NavigationView {
            Form {
                usersSection
                if selectedUserId != nil {
                    healthSection
                    locationSection
                    contactsSection
                }
            }
            .navigationTitle("User Data Manager")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("+") { showingAddUser = true }
                }
            }
            .alert("Add New User", isPresented: $showingAddUser) {
                TextField("Username", text: $newUsername)
                TextField("Display Name (optional)", text: $newDisplayName)
                Button("Cancel", role: .cancel) { clearAddUserForm() }
                Button("Add") { Task { await addUser() } }
            }
            .overlay(alignment: .bottom) {
                VStack(spacing: 8) {
                    if !toast.successMessage.isEmpty {
                        Text(toast.successMessage)
                            .padding()
                            .background(.green.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    if !toast.errorMessage.isEmpty {
                        Text(toast.errorMessage)
                            .padding()
                            .background(.red.opacity(0.9))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding()
            }
            .task { 
                await requestAllPermissions()
                await loadUsers() 
            }
        }
    }

    private var selectedUser: User? {
        users.first { $0.id == selectedUserId }
    }
    
    private var usersSection: some View {
        Section("Users") {
            ForEach(users) { user in
                HStack {
                    VStack(alignment: .leading) {
                        Text(user.username)
                            .fontWeight(selectedUserId == user.id ? .bold : .regular)
                        if let displayName = user.display_name {
                            Text(displayName)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Spacer()
                    if selectedUserId == user.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    selectedUserId = user.id
                    Task { await loadUserData() }
                }
            }
        }
    }
    
    private var healthSection: some View {
        Section("Health Data") {
                    HStack {
                TextField("Steps", text: $steps)
                    .keyboardType(.numberPad)
                Button("Fetch") {
                    Task { await fetchHealthData() }
                }
                .disabled(health.isLoading)
            }
            
            HStack {
                TextField("Heart Rate", text: $heartRate)
                    .keyboardType(.decimalPad)
                Button("Fetch") {
                    Task { await fetchHealthData() }
                }
                .disabled(health.isLoading)
            }
            
            HStack {
                TextField("Sleep Hours", text: $sleepHours)
                    .keyboardType(.decimalPad)
                Button("Fetch") {
                    Task { await fetchHealthData() }
                }
                .disabled(health.isLoading)
            }
            
            HStack {
                TextField("Active Calories", text: $activeCalories)
                    .keyboardType(.decimalPad)
                Button("Fetch") {
                    Task { await fetchHealthData() }
                }
                .disabled(health.isLoading)
            }
            
            HStack {
                TextField("Distance (km)", text: $distanceKm)
                    .keyboardType(.decimalPad)
                Button("Fetch") {
                    Task { await fetchHealthData() }
                }
                .disabled(health.isLoading)
            }
            
            Button("Save to Database") {
                Task { await saveHealthData() }
            }
            .disabled(isLoading)
        }
    }
    
    private var locationSection: some View {
        Section("Location") {
            HStack {
                TextField("City", text: $city)
                Button("Locate") {
                    Task { await fetchLocation() }
                }
                .disabled(location.isLoading)
            }
            
            Button("Save to Database") {
                Task { await saveLocation() }
            }
            .disabled(isLoading)
        }
    }
    
    private var contactsSection: some View {
        Section("Contacts") {
            TextField("Contact Name", text: $contactName)
            TextField("Phone", text: $contactPhone)
                .keyboardType(.phonePad)
            TextField("Email", text: $contactEmail)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            Button("Import from Device") {
                Task { await importContacts() }
            }
            .disabled(contacts.isLoading)
            
            Button("Save to Database") {
                Task { await saveContact() }
            }
            .disabled(isLoading)
        }
    }
    
    private func clearAddUserForm() {
        newUsername = ""
        newDisplayName = ""
    }
    
    private func loadUsers() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let client = SupabaseService().client
            users = try await client.from("users")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
        } catch {
            toast.flashError("Failed to load users: \(error.localizedDescription)")
        }
    }
    
    private func addUser() async {
        guard !newUsername.isEmpty else {
            toast.flashError("Username is required")
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            let client = SupabaseService().client
            let newUser = User(
                id: UUID(),
                username: newUsername,
                display_name: newDisplayName.isEmpty ? nil : newDisplayName,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            
            _ = try await client.from("users").insert(newUser).execute()
            clearAddUserForm()
            await loadUsers()
            toast.flashSuccess("User added successfully")
        } catch {
            toast.flashError("Failed to add user: \(error.localizedDescription)")
        }
    }
    
    private func loadUserData() async {
        guard let userId = selectedUserId else { return }
        
        // Load health data
        do {
            let healthData = try await health.fetchToday(for: userId)
            if let data = healthData.first {
                steps = String(data.steps)
                heartRate = String(format: "%.1f", data.heart_rate_avg)
                sleepHours = String(format: "%.1f", data.sleep_hours)
                activeCalories = String(format: "%.0f", data.active_calories)
                distanceKm = String(format: "%.2f", data.distance_km)
            } else {
                clearHealthForm()
            }
        } catch {
            clearHealthForm()
        }
        
        // Load location data
        do {
            let locationData = try await location.fetchLatest(userId: userId)
            city = locationData.first?.city ?? ""
        } catch {
            city = ""
        }
        
        // Load contacts data (get latest contact)
        let contactsResult = await contacts.fetchContactsFromSupabase(userId: userId)
        switch contactsResult {
        case .success(let contactsData):
            if let contact = contactsData.first {
                contactName = contact.name
                contactPhone = contact.phone
                contactEmail = "" // No email field in database
            } else {
                clearContactsForm()
            }
        case .failure:
            clearContactsForm()
        }
    }
    
    private func clearHealthForm() {
        steps = ""
        heartRate = ""
        sleepHours = ""
        activeCalories = ""
        distanceKm = ""
    }
    
    private func clearContactsForm() {
        contactName = ""
        contactPhone = ""
        contactEmail = ""
    }
    
    private func fetchHealthData() async {
        guard let userId = selectedUserId else { return }
        
        guard await health.requestPermissions() else {
            toast.flashError("Health permission denied")
            return
        }
        
        guard let healthData = await health.fetchTodaysHealthData(for: userId) else {
            toast.flashError("Failed to fetch health data")
            return
        }
        
        steps = String(healthData.steps)
        heartRate = String(format: "%.1f", healthData.heart_rate_avg)
        sleepHours = String(format: "%.1f", healthData.sleep_hours)
        activeCalories = String(format: "%.0f", healthData.active_calories)
        distanceKm = String(format: "%.2f", healthData.distance_km)
        
        toast.flashSuccess("Health data fetched from device")
    }
    
    private func saveHealthData() async {
        guard let userId = selectedUserId else { return }
        
        let day = ISO8601DateFormatter().string(from: Calendar.current.startOfDay(for: Date()))
        let healthData = HealthKitManager.HealthData(
            user_id: userId,
            date: day,
            steps: Int(steps) ?? 0,
            heart_rate_avg: Double(heartRate) ?? 0,
            sleep_hours: Double(sleepHours) ?? 0,
            active_calories: Double(activeCalories) ?? 0,
            distance_km: Double(distanceKm) ?? 0
        )
        
        do {
            try await health.upsertToday(healthData)
            toast.flashSuccess("Health data saved")
        } catch {
            toast.flashError("Failed to save health data: \(error.localizedDescription)")
        }
    }
    
    private func fetchLocation() async {
        guard await location.requestPermission() else {
            toast.flashError("Location permission denied")
            return
        }
        
        if let fetchedCity = await location.fetchCity() {
            city = fetchedCity
            toast.flashSuccess("Location fetched")
        } else {
            toast.flashError("Failed to fetch location")
        }
    }
    
    private func saveLocation() async {
        guard let userId = selectedUserId, !city.isEmpty else {
            toast.flashError("Invalid user or empty city")
            return
        }
        
        do {
            try await location.insertLocation(userId: userId, city: city)
            toast.flashSuccess("Location saved")
        } catch {
            toast.flashError("Failed to save location: \(error.localizedDescription)")
        }
    }
    
    private func importContacts() async {
        guard let userId = selectedUserId else { return }
        
        let result = await contacts.syncContactsToSupabase(userId: userId)
        switch result {
        case .success(let count):
            toast.flashSuccess("Imported \(count) contacts")
        case .failure(let error):
            toast.flashError("Failed to import contacts: \(error.localizedDescription)")
        }
    }
    
    private func saveContact() async {
        guard let userId = selectedUserId, !contactName.isEmpty else {
            toast.flashError("Invalid user or empty contact name")
            return
        }
        
        do {
            let client = SupabaseService().client
            let contact = ContactsManager.ContactData(
                id: UUID(),
                user_id: userId,
                name: contactName,
                phone: contactPhone,
                created_at: ISO8601DateFormatter().string(from: Date())
            )
            
            _ = try await client.from("contacts").insert(contact).execute()
            toast.flashSuccess("Contact saved")
        } catch {
            toast.flashError("Failed to save contact: \(error.localizedDescription)")
        }
    }
    
    private func requestAllPermissions() async {
        // Add a small delay to ensure app is fully loaded
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Request HealthKit permissions
        print("Requesting HealthKit permissions...")
        let healthGranted = await health.requestPermissions()
        print("HealthKit permission result: \(healthGranted)")
        if healthGranted {
            toast.flashSuccess("HealthKit permissions granted")
        } else {
            toast.flashError("HealthKit permissions denied - check entitlements")
        }
        
        // Request Location permissions
        print("Requesting Location permissions...")
        let locationGranted = await location.requestPermission()
        print("Location permission result: \(locationGranted)")
        if locationGranted {
            toast.flashSuccess("Location permissions granted")
        } else {
            toast.flashError("Location permissions denied")
        }
        
        // Request Contacts permissions
        print("Requesting Contacts permissions...")
        let contactsGranted = await contacts.requestContactsPermission()
        print("Contacts permission result: \(contactsGranted)")
        if contactsGranted {
            toast.flashSuccess("Contacts permissions granted")
        } else {
            toast.flashError("Contacts permissions denied")
        }
    }
}


#Preview { ContentView() }
