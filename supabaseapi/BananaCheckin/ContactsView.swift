import SwiftUI

struct ContactsView: View {
    @State private var selectedTab = 0
    @State private var showingDiscover = false
    @EnvironmentObject var contactsManager: ContactsManager
    @EnvironmentObject var healthManager: HealthKitManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header with proper spacing
                HStack {
                    Button {
                        showingDiscover = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.blue)
                            .frame(width: 32, height: 32)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 8) {
                        TabButton(title: "Followers", isSelected: selectedTab == 0) {
                            selectedTab = 0
                        }
                        TabButton(title: "Following", isSelected: selectedTab == 1) {
                            selectedTab = 1
                        }
                    }
                    
                    Spacer()
                    
                    Color.clear.frame(width: 32)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 16)

                // Content with proper spacing
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.5))
                    
                    Text("Contacts View")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text("This is a simplified contacts view")
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, 60)
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showingDiscover) {
                DiscoverContactsView()
                    .environmentObject(contactsManager)
            }
        }
    }
}

struct DiscoverContactsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var contactsManager: ContactsManager
    @State private var searchText = ""
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search contacts", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 12)
            
            ScrollView {
                VStack(spacing: 8) {
                    Text("Discover Contacts")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .padding(.top, 40)
                }
                .padding(.horizontal)
                Spacer(minLength: 100)
            }
        }
        .navigationTitle("Discover")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .primary : .gray)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isSelected ? Color(.systemGray6) : Color.clear)
                )
        }
    }
}


#Preview {
    ContactsView()
        .environmentObject(ContactsManager())
        .environmentObject(HealthKitManager())
}
