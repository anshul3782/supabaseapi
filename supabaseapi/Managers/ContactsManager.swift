
// ContactsManager.swift
import Foundation
import Supabase
import Combine
import Contacts

@MainActor
final class ContactsManager: ObservableObject {
    @Published var isLoading = false
    private let client = SupabaseService().client
    private let contactStore = CNContactStore()

    // Matches your actual database schema - minimal for bulk imports
    struct ContactData: Codable, Identifiable {
        let id: UUID
        let user_id: UUID
        let name: String        // Changed from contact_name to match DB
        let phone: String
        let created_at: String?
    }
    
    func requestContactsPermission() async -> Bool {
        let status = CNContactStore.authorizationStatus(for: .contacts)
        print("Contacts: Current authorization status: \(status.rawValue)")
        
        switch status {
        case .authorized:
            print("Contacts: Already authorized")
            return true
        case .notDetermined:
            print("Contacts: Requesting access")
            return await withCheckedContinuation { continuation in
                contactStore.requestAccess(for: .contacts) { granted, error in
                    if let error = error {
                        print("Contacts: Request failed with error: \(error)")
                    }
                    print("Contacts: Request result: \(granted)")
                    continuation.resume(returning: granted)
                }
            }
        default:
            print("Contacts: Authorization denied or restricted")
            return false
        }
    }

    /// Sync ALL contacts from device to Supabase (bulk import)
    func syncContactsToSupabase(userId: UUID) async -> Result<Int, Error> {
        isLoading = true; defer { isLoading = false }
        
        // Request contacts permission first
        guard await requestContactsPermission() else {
            return .failure(NSError(domain: "ContactsManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "Contacts permission denied"]))
        }
        
        do {
            // Fetch ALL contacts from device (no limit for bulk import)
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            
            var deviceContacts: [CNContact] = []
            try contactStore.enumerateContacts(with: request) { contact, _ in
                deviceContacts.append(contact)
            }
            
            print("Contacts: Found \(deviceContacts.count) contacts on device")
            
            // Convert to our ContactData format and insert into database
            var insertedCount = 0
            for contact in deviceContacts {
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                let phoneNumber = contact.phoneNumbers.first?.value.stringValue
                
                // Skip contacts without name or phone
                guard !fullName.isEmpty, let phone = phoneNumber, !phone.isEmpty else {
                    continue
                }
                
                let contactData = ContactData(
                    id: UUID(),
                    user_id: userId,
                    name: fullName,
                    phone: phone,
                    created_at: ISO8601DateFormatter().string(from: Date())
                )
                
                _ = try await client.from("contacts").insert(contactData).execute()
                insertedCount += 1
                
                // Log progress every 50 contacts
                if insertedCount % 50 == 0 {
                    print("Contacts: Inserted \(insertedCount) contacts...")
                }
            }
            
            print("Contacts: Successfully synced \(insertedCount) contacts to database")
            return .success(insertedCount)
        } catch {
            print("Contacts: Sync failed with error: \(error)")
            return .failure(error)
        }
    }

    /// Load contacts for this user from DB (your UI only uses .count right now)
    func fetchContactsFromSupabase(userId: UUID) async -> Result<[ContactData], Error> {
        isLoading = true; defer { isLoading = false }
        do {
            let rows: [ContactData] = try await client
                .from("contacts")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            return .success(rows)
        } catch {
            return .failure(error)
        }
    }
}
