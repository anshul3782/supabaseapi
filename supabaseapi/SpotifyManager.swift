import Foundation
import Combine
import Supabase

final class SpotifyManager: ObservableObject {
    struct MusicActivity: Codable, Identifiable {
        var id: UUID { UUID() } // local-only id for SwiftUI lists
        let userId: UUID
        let trackName: String
        let artistName: String
        let playedAt: String

        enum CodingKeys: String, CodingKey {
            case userId = "user_id"
            case trackName = "track_name"
            case artistName = "artist_name"
            case playedAt = "played_at"
        }
    }

    @Published var isLoading = false
    private let client = SupabaseService().client
    private let iso = ISO8601DateFormatter()

    // Insert a real/explicit activity row
    func syncMusicToSupabase(userId: UUID, trackName: String, artistName: String) async -> Result<Bool, Error> {
        isLoading = true
        defer { isLoading = false }

        do {
            let row = MusicActivity(
                userId: userId,
                trackName: trackName,
                artistName: artistName,
                playedAt: iso.string(from: Date())
            )

            _ = try await client
                .from("music_activity")
                .insert(row)
                .execute()

            return .success(true)
        } catch {
            return .failure(error)
        }
    }

    // Convenience: insert a random mock row
    func syncRandomMusicToSupabase(userId: UUID) async -> Result<Bool, Error> {
        let (t, a) = getRandomMockTrack()
        return await syncMusicToSupabase(userId: userId, trackName: t, artistName: a)
    }

    // Fetch recent rows for a user
    func fetchMusicActivityFromSupabase(userId: UUID, limit: Int = 20) async -> Result<[MusicActivity], Error> {
        do {
            let rows: [MusicActivity] = try await client
                .from("music_activity")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("played_at", ascending: false)
                .limit(limit)
                .execute()
                .value

            return .success(rows)
        } catch {
            return .failure(error)
        }
    }

    // MARK: - Mock data
    private func getRandomMockTrack() -> (String, String) {
        let tracks = [
            ("Blinding Lights", "The Weeknd"),
            ("Anti‑Hero", "Taylor Swift"),
            ("As It Was", "Harry Styles"),
            ("Levitating", "Dua Lipa"),
            ("Bad Habit", "Steve Lacy")
        ]
        return tracks.randomElement()!
    }
}
