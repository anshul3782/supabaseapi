//
//  MusicWidget.swift
//  cheakin
//
//  Created by Arnav Gupta on 9/29/25.
//

import SwiftUI

struct MusicWidget: View {
    let mockTracks = [
        SpotifyTrack(title: "Blinding Lights", artist: "The Weeknd", albumArt: "music.note"),
        SpotifyTrack(title: "Anti-Hero", artist: "Taylor Swift", albumArt: "music.note"),
        SpotifyTrack(title: "As It Was", artist: "Harry Styles", albumArt: "music.note"),
        SpotifyTrack(title: "Die For You", artist: "The Weeknd", albumArt: "music.note")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("recently played")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.gray)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(mockTracks) { track in
                        TrackCard(track: track)
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.vertical, 0)
    }
}

struct TrackCard: View {
    let track: SpotifyTrack

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [Color.purple.opacity(0.6), Color.pink.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)

                Image(systemName: track.albumArt)
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }

            Text(track.title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)

            Text(track.artist)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
                .lineLimit(1)
                .frame(width: 120, alignment: .leading)
        }
        .frame(width: 120)
    }
}

struct SpotifyTrack: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let albumArt: String
}

#Preview {
    MusicWidget()
}
