//
//  SettingsView.swift
//  cheakin
//
//  Created by Arnav Gupta on 9/29/25.
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("themeMode") private var themeMode = "light"
    @EnvironmentObject var supabaseManager: SupabaseManager

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    Text("settings")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    VStack(spacing: 12) {
                        Text("appearance")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)

                        HStack(spacing: 8) {
                            ThemeCapsule(
                                title: "Light",
                                icon: "sun.max.fill",
                                isSelected: themeMode == "light"
                            ) {
                                themeMode = "light"
                            }

                            ThemeCapsule(
                                title: "Dark",
                                icon: "moon.fill",
                                isSelected: themeMode == "dark"
                            ) {
                                themeMode = "dark"
                            }

                            ThemeCapsule(
                                title: "Multi",
                                icon: "paintbrush.fill",
                                isSelected: themeMode == "multi",
                                isMultiColor: true
                            ) {
                                themeMode = "multi"
                            }
                        }
                        .padding(.horizontal)
                    }
                    
                    // Account Section
                    VStack(spacing: 12) {
                        Text("account")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            if let user = supabaseManager.currentUser {
                                HStack {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.blue)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Signed in as")
                                            .font(.system(size: 12))
                                            .foregroundColor(.secondary)
                                        Text(user.email ?? "Unknown")
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .padding(.horizontal)
                            }
                            
                            Button(action: {
                                Task {
                                    await supabaseManager.signOut()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                        .font(.system(size: 16))
                                    Text("Sign Out")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(.red)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }

                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(themeMode == "dark" ? .dark : .light)
    }
}

struct ThemeCapsule: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var isMultiColor: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? (isMultiColor ? .white : .primary) : .gray)

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? (isMultiColor ? .white : .primary) : .gray)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Group {
                    if isMultiColor && isSelected {
                        LinearGradient(
                            colors: [.purple, .pink, .orange, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    } else {
                        Color(isSelected ? .systemGray6 : .systemGray5)
                            .opacity(isSelected ? 1 : 0.5)
                    }
                }
            )
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .stroke(isSelected && !isMultiColor ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
    }
}

#Preview {
    SettingsView()
}
