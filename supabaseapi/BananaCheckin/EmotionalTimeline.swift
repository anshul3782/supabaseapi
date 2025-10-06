//
//  EmotionalTimeline.swift
//  supabaseapi (simplified version without Lottie)
//

import SwiftUI

struct EmotionalTimeline: View {
    let emotions = ["sad", "angry", "cold-face", "crying", "flushed", "gasp", "grimacing"]
    let times = ["08", "11", "14", "17", "20", "23", "02", "05"]
    @State private var showInsights = false
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("emotional timeline")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(alignment: .top, spacing: 0) {
                        VStack(spacing: 6) {
                            Spacer().frame(height: 50)
                            Text(times[0])
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .frame(width: 60)
                        
                        ForEach(Array(emotions.enumerated()), id: \.offset) { index, emotion in
                            VStack(spacing: 6) {
                                Button(action: {
                                    showInsights = true
                                }) {
                                    StaticEmojiView(emojiName: emotion, size: 24)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(Color.blue.opacity(0.1))
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                                .id(index)
                                
                                Text(times[index + 1])
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 60)
                        }
                    }
                    .padding(.horizontal)
                }
                .frame(height: 80)
            }
            
            if showInsights {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Emotional Insights")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Your emotional patterns show variation throughout the day. Consider taking breaks during high-stress periods.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
                        )
                )
                .padding(.horizontal)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                isVisible = true
            }
        }
    }
}

#Preview {
    EmotionalTimeline()
}