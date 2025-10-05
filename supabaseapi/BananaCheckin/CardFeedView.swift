//
//  CardFeedView.swift
//  cheakin
//
//  Created by Arnav Gupta on 9/29/25.
//

import SwiftUI

struct CardFeedView: View {
    @State private var currentIndex = 0
    @State private var dragOffset: CGFloat = 0
    @State private var showIndicator = true

    let mockCards = [
        FeedCard(title: "morning motivation", content: "you're doing better than you think. today's health metrics show consistent improvement.", backgroundColor: "#FF6B6B", textColor: "#FFFFFF"),
        FeedCard(title: "check-in reminder", content: "3 friends nearby want to meet up. tap to see who's around.", backgroundColor: "#4ECDC4", textColor: "#FFFFFF"),
        FeedCard(title: "mood insight", content: "your emotional patterns suggest you're most productive between 2-5pm. schedule important tasks then.", backgroundColor: "#95E1D3", textColor: "#2C3E50"),
        FeedCard(title: "health milestone", content: "you've walked 10k steps for 7 days straight. keep it going!", backgroundColor: "#F3A683", textColor: "#FFFFFF"),
        FeedCard(title: "social pulse", content: "your friend group's average mood is up 15% this week. good vibes all around.", backgroundColor: "#786FA6", textColor: "#FFFFFF")
    ]

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(mockCards.indices, id: \.self) { index in
                    CardView(
                        card: mockCards[index],
                        currentIndex: currentIndex,
                        totalCards: mockCards.count,
                        showIndicator: showIndicator
                    )
                    .frame(width: geometry.size.width - 32)
                    .offset(x: CGFloat(index - currentIndex) * geometry.size.width + dragOffset)
                    .gesture(
                        index == currentIndex ?
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation.width
                                showIndicator = true
                            }
                            .onEnded { value in
                                let threshold: CGFloat = 100
                                if value.translation.width > threshold && currentIndex > 0 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        currentIndex -= 1
                                    }
                                } else if value.translation.width < -threshold && currentIndex < mockCards.count - 1 {
                                    withAnimation(.easeOut(duration: 0.3)) {
                                        currentIndex += 1
                                    }
                                }
                                withAnimation(.easeOut(duration: 0.2)) {
                                    dragOffset = 0
                                }

                                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                    withAnimation {
                                        showIndicator = false
                                    }
                                }
                            }
                        : nil
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct CardView: View {
    let card: FeedCard
    let currentIndex: Int
    let totalCards: Int
    let showIndicator: Bool

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 24) {
                Text(card.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(Color(hex: card.textColor))

                Text(card.content)
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(Color(hex: card.textColor).opacity(0.9))
                    .lineSpacing(6)

                Spacer()
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

            if showIndicator {
                HStack(spacing: 6) {
                    ForEach(0..<totalCards, id: \.self) { index in
                        Capsule()
                            .fill(Color(hex: card.textColor).opacity(index == currentIndex ? 0.9 : 0.3))
                            .frame(
                                width: index == currentIndex ? 20 : 6,
                                height: 6
                            )
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentIndex)
                    }
                }
                .padding(.bottom, 20)
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hex: card.backgroundColor))
        )
        .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

struct FeedCard: Identifiable {
    let id = UUID()
    let title: String
    let content: String
    let backgroundColor: String
    let textColor: String
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    CardFeedView()
}
