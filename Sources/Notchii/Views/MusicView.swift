import SwiftUI

/// Artwork and playhead on top, transport underneath. Either half can be
/// switched off in Settings.
struct MusicView: View {
    @EnvironmentObject private var music: MusicController
    @EnvironmentObject private var preferences: Preferences

    var body: some View {
        VStack(spacing: 0) {
            if preferences.isEnabled(.nowPlaying) {
                nowPlaying
                    .frame(maxHeight: .infinity)
            }
            if preferences.isEnabled(.transport) {
                transport
                    .frame(height: 30)
                    .padding(.bottom, 4)
            }
        }
        .frame(height: Layout.contentHeight)
    }

    @ViewBuilder
    private var nowPlaying: some View {
        if let track = music.track {
            HStack(spacing: 12) {
                artwork
                VStack(alignment: .leading, spacing: 5) {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(track.title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(Palette.primaryText)
                            .lineLimit(1)
                        Text(track.artist)
                            .font(.system(size: 11))
                            .foregroundColor(Palette.secondaryText)
                            .lineLimit(1)
                    }
                    // Ticks locally between polls so the playhead stays smooth.
                    TimelineView(.periodic(from: .now, by: 0.5)) { _ in
                        progress(track)
                    }
                }
            }
        } else {
            HStack(spacing: 12) {
                artwork
                Text("Nothing playing")
                    .font(.system(size: 12))
                    .foregroundColor(Palette.mutedText)
                Spacer(minLength: 0)
            }
        }
    }

    private var artwork: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Palette.primaryText.opacity(0.08))
            if let image = music.artwork {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "music.note")
                    .font(.system(size: 16))
                    .foregroundColor(Palette.mutedText)
            }
        }
        .frame(width: 56, height: 56)
    }

    private func progress(_ track: MusicController.Track) -> some View {
        let position = track.livePosition
        let fraction = track.duration > 0 ? min(1, position / track.duration) : 0

        return HStack(spacing: 8) {
            time(position)
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.primaryText.opacity(0.14))
                    Capsule()
                        .fill(Palette.primaryText.opacity(0.75))
                        .frame(width: proxy.size.width * fraction)
                }
            }
            .frame(height: 3)
            time(track.duration)
        }
    }

    private func time(_ seconds: TimeInterval) -> some View {
        let total = Int(seconds.rounded())
        return Text(String(format: "%d:%02d", total / 60, total % 60))
            .font(.system(size: 9, weight: .medium).monospacedDigit())
            .foregroundColor(Palette.mutedText)
    }

    private var transport: some View {
        HStack(spacing: 22) {
            Spacer(minLength: 0)
            button("shuffle", size: 11, tinted: music.track?.isShuffling == true, action: music.toggleShuffle)
            button("backward.end.fill", size: 12, action: music.previous)
            button(music.isPlaying ? "pause.fill" : "play.fill", size: 15, action: music.playPause)
            button("forward.end.fill", size: 12, action: music.next)
            Spacer(minLength: 0)
        }
        .opacity(music.track == nil ? 0.35 : 1)
    }

    private func button(
        _ symbol: String,
        size: CGFloat,
        tinted: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: size))
                .foregroundColor(tinted ? Palette.accent : Palette.primaryText.opacity(0.85))
                .frame(width: 20, height: 18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
