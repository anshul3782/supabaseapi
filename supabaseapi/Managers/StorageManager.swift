import Foundation
import Supabase

final class StorageManager {
    private let client = SupabaseService().client

    func publicURL(bucket: String, path: String) -> URL? {
        try? client.storage.from(bucket).getPublicURL(path: path)
    }

    func signedURL(bucket: String, path: String, expiresIn seconds: Int = 3600) async -> URL? {
        do {
            return try await client.storage.from(bucket).createSignedURL(path: path, expiresIn: seconds)
        } catch {
            return nil
        }
    }
}
