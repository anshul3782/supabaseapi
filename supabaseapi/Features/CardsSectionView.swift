//
//  CardsSectionView.swift
//

import SwiftUI
import Combine
import Supabase
import PostgREST

// Match your "card_items" table columns.
// Add fields if your table has more (e.g., created_at).
struct CardItem: Decodable, Identifiable {
    let id: UUID
    let title: String
    let image_path: String
}

@MainActor
final class CardsVM: ObservableObject {
    @Published var items: [CardItem] = []
    @Published var isLoading = false
    @Published var errorMessage = ""

    // Uses your AppConfig-based client from SupabaseService
    private let client = SupabaseService().client

    func fetch() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            // SELECT * FROM card_items ORDER BY created_at DESC
            let rows: [CardItem] = try await client
                .from("card_items")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value

            self.items = rows
            self.errorMessage = ""
        } catch {
            self.errorMessage = "Failed to load cards."
        }
    }

    /// Build a URL for the image stored in Supabase Storage bucket "cards".
    /// If your bucket is private, swap to create a signed URL and make this async.
    func publicURL(for path: String) -> URL? {
        // Quick & safe: swallow errors for now. Ship first, harden later.
        try? client.storage.from("cards").getPublicURL(path: path)
    }
}

struct CardsSectionView: View {
    @StateObject private var vm = CardsVM()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Cards")
                    .font(.title3).bold()
                if vm.isLoading {
                    Spacer()
                    ProgressView()
                }
            }

            if !vm.errorMessage.isEmpty {
                Text(vm.errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.vertical, 4)
            }

            ForEach(vm.items) { item in
                VStack(alignment: .leading, spacing: 8) {
                    if let url = vm.publicURL(for: item.image_path) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity, minHeight: 140)
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(maxWidth: .infinity, minHeight: 140)
                                    .clipped()
                            case .failure:
                                ZStack {
                                    Color.gray.opacity(0.2)
                                    Image(systemName: "photo")
                                        .imageScale(.large)
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity, minHeight: 140)
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .cornerRadius(12)
                    }

                    Text(item.title)
                        .font(.headline)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
        .task { await vm.fetch() }
    }
}
#Preview {
    CardsSectionView()
}