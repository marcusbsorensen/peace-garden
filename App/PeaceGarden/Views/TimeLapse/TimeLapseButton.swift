import SwiftUI

/// The play glyph on a plant's screen: the plant's life again, in twelve
/// seconds.
///
/// **Top left, opposite the way out.** The top right is Close and, beside it,
/// Share; the foot is the row of marks, and it comes and goes with the words.
/// The top left is the one corner nothing stands in, it is always on screen as
/// Close is, and a glyph there is one touch away whether the words are up or
/// not. Drawn exactly as Close is drawn — a system glyph, light, in the same
/// hairline ring — so the two corners read as a pair and the glyph is known
/// before it is read (`docs/CHROME-AND-SETTINGS.md`, the X).
///
/// **The same control stops it.** While the run plays the triangle becomes a
/// square, and a tap stops it; so does a tap or a swipe anywhere on the plant.
/// A replay is just another tap.
struct TimeLapseButton: View {
    let isPlaying: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isPlaying ? "stop" : "play")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Chrome.ink.opacity(0.75))
                // The triangle's weight sits left of its box; nudged so it
                // looks centred in the ring, as a play glyph always is.
                .offset(x: isPlaying ? 0 : 1)
                .frame(width: 18, height: 18)
                .contentTransition(.opacity)
                .pressable(horizontal: 12, vertical: 12)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(isPlaying ? Text("Stop time-lapse") : Text("Play time-lapse"))
    }
}

/// The time-lapse's sky, in a view of its own so that only this redraws on
/// each frame of the run, and not the screen it stands on.
struct TimeLapseSkyLayer: View {
    let player: TimeLapsePlayer

    var body: some View {
        TimeLapseSkyView(moment: player.sky)
    }
}

/// While a run plays, a tap or a swipe anywhere on the plant stops it, rather
/// than turning the plant or raising the words over it.
struct TimeLapseStopCatcher: View {
    let stop: () -> Void

    var body: some View {
        Color.clear
            .contentShape(Rectangle())
            .onTapGesture(perform: stop)
            .gesture(DragGesture(minimumDistance: 12).onEnded { _ in stop() })
            .accessibilityHidden(true)
    }
}
