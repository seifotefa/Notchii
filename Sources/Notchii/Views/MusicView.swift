import SwiftUI

/// One line of now-playing plus transport. Wide and short by design.
struct MusicView: View {
    @EnvironmentObject private var music: MusicController

    var body: some View {
        HStack(spacing: 12) {
            artwork

            if let track = music.track {
                VStack(alignment: .leading, spacing: 2) {
                    Text(track.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Palette.primaryText)
                        .lineLimit(1)
                    Text(track.artist)
                        .font(.system(size: 11))
                        .foregroundColor(Palette.secondaryText)
                        .lineLimit(1)
                }
            } else {
                Text("Nothing playing")
                    .font(.system(size: 12))
                    .foregroundColor(Palette.mutedText)
            }

            Spacer(minLength: 12)

            if music.track != nil {
                HStack(spacing: 16) {
                    transport("backward.fill", size: 12, action: music.previous)
                    transport(music.isPlaying ? "pause.fill" : "play.fill", size: 15, action: music.playPause)
                    transport("forward.fill", size: 12, action: music.next)
                }
            }
        }
        .frame(height: Layout.musicHeight)
    }

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(Palette.primaryText.opacity(0.08))
            if let url = music.track?.artworkURL {
                AsyncImage(url: url) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.clear
                }
                .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 14))
                    .foregroundColor(Palette.mutedText)
            }
        }
        .frame(width: 40, height: 40)
    }

    private func transport(_ symbol: String, size: CGFloat, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundColor(Palette.primaryText.opacity(0.85))
                .frame(width: 22, height: 22)
        }
        .buttonStyle(.plain)
    }
}
