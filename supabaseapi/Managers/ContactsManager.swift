
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

    // Shape this to your "contacts" table. Keep it minimal for now.
    struct ContactData: Codable, Identifiable {
        let id: UUID                 // primary key (uuid) in your table
        let user_id: UUID
        let contact_name: String?
        let phone: String?
        let email: String?
        let created_at: String?
    }
    
    func requestContactsPermission() async -> Bool {
        switch CNContactStore.authorizationStatus(for: .contacts) {
        case .authorized:
            return true
        case .notDetermined:
            return await withCheckedContinuation { continuation in
                contactStore.requestAccess(for: .contacts) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        default:
            return false
        }
    }

    /// Sync real contacts from device to Supabase
    func syncContactsToSupabase(userId: UUID) async -> Result<Int, Error> {
        isLoading = true; defer { isLoading = false }
        
        // Request contacts permission first
        guard await requestContactsPermission() else {
            return .failure(NSError(domain: "ContactsManager", code: 403, userInfo: [NSLocalizedDescriptionKey: "Contacts permission denied"]))
        }
        
        do {
            // Fetch contacts from device
            let keys = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey, CNContactEmailAddressesKey]
            let request = CNContactFetchRequest(keysToFetch: keys as [CNKeyDescriptor])
            
            var deviceContacts: [CNContact] = []
            try contactStore.enumerateContacts(with: request) { contact, _ in
                deviceContacts.append(contact)
            }
            
            // Convert to our ContactData format and insert into database
            var insertedCount = 0
            for contact in deviceContacts.prefix(10) { // Limit to first 10 contacts for demo
                let fullName = "\(contact.givenName) \(contact.familyName)".trimmingCharacters(in: .whitespaces)
                let phoneNumber = contact.phoneNumbers.first?.value.stringValue
                let emailAddress = contact.emailAddresses.first?.value as String?
                
                let contactData = ContactData(
                    id: UUID(),
                    user_id: userId,
                    contact_name: fullName.isEmpty ? nil : fullName,
                    phone: phoneNumber,
                    email: emailAddress,
                    created_at: ISO8601DateFormatter().string(from: Date())
                )
                
                _ = try await client.from("contacts").insert(contactData).execute()
                insertedCount += 1
            }
            
            return .success(insertedCount)
        } catch {
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
