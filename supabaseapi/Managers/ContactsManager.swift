
// ContactsManager.swift
import Foundation
import Supabase
import Combine

@MainActor
final class ContactsManager: ObservableObject {
    @Published var isLoading = false
    private let client = SupabaseService().client

    // Shape this to your "contacts" table. Keep it minimal for now.
    struct ContactData: Codable, Identifiable {
        let id: UUID                 // primary key (uuid) in your table
        let user_id: UUID
        let contact_name: String?
        let phone: String?
        let email: String?
        let created_at: String?
    }

    /// TEMP: no device sync yet. Just a stub so your UI compiles and runs.
    /// If you want, this can insert a dummy contact row so you see a count > 0.
    func syncContactsToSupabase(userId: UUID) async -> Result<Int, Error> {
        isLoading = true; defer { isLoading = false }
        do {
            // Comment this block out if you DON’T want a dummy insert.
            struct NewRow: Codable {
                let id: UUID
                let user_id: UUID
                let contact_name: String?
                let phone: String?
                let email: String?
            }
            let dummy = NewRow(
                id: UUID(),
                user_id: userId,
                contact_name: "Demo Contact",
                phone: nil,
                email: nil
            )
            _ = try await client.from("contacts").insert(dummy).execute()

            // Return new count so your UI shows something.
            let rows: [ContactData] = try await client
                .from("contacts")
                .select()
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            return .success(rows.count)
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
