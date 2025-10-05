import SwiftUI
import Supabase
import Combine

@MainActor
class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    @Published var currentUser: SupabaseUser?
    @Published var isAuthenticated = false
    
    private init() {
        // For now, just simulate being authenticated
        self.isAuthenticated = true
        self.currentUser = SupabaseUser(id: UUID(), email: "demo@example.com")
    }
    
    func signOut() async {
        isAuthenticated = false
        currentUser = nil
    }
}

struct SupabaseUser {
    let id: UUID
    let email: String?
}
