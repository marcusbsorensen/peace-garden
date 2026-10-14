import SwiftUI

/// What the app says about itself: for now, what leaves the phone at a meeting
/// and what a place logged with a seed is.
///
/// **Reached from the foot of Settings, and from the ⓘ beside *Location
/// description*** (Marcus, 14 October 2026: 4A and 5A). Its words stood in
/// Settings until 13 October, under the place settings, where they read — his
/// words — *more like something that can be shown on an About page under
/// Privacy*. So Settings keeps one short line for each choice, and the account
/// behind them is here, offline, in every language the app speaks.
///
/// **The words are the catalogue's own.** The account of a meeting is the key
/// translated in all seven languages since 26 September, which says *made*
/// where the code had drifted back to *drawn* — and so had shown in English in
/// every language. The coordinates paragraph is the one Settings let go on 13
/// October, its translations kept for this. Nothing here is new to translate
/// but the two headings.
///
/// A sheet, as the seed screen is: it rises over Settings, which is still
/// there when it closes.
struct AboutView: View {
    /// Where the sheet opens. The ⓘ beside *Location description* opens it at
    /// Privacy, which is what that ⓘ is asking about.
    enum Part: String, Identifiable {
        case top
        case privacy

        var id: String { rawValue }
    }

    var startsAt: Part = .top
    let close: () -> Void

    /// The title's size, which is Settings' heading's.
    private static let titleSize: CGFloat = 20

    var body: some View {
        ZStack {
            Chrome.ground.ignoresSafeArea()

            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 30) {
                        privacy
                            .id(Part.privacy)
                    }
                    .padding(.horizontal, 30)
                    .padding(.top, 18)
                    .padding(.bottom, 60)
                    .frame(maxWidth: Chrome.readableWidth)
                    .frame(maxWidth: .infinity)
                }
                // The title and the way out stay put and the words pass under
                // them, as in Settings.
                .safeAreaInset(edge: .top, spacing: 0) { header }
                .task {
                    guard startsAt != .top else { return }
                    proxy.scrollTo(startsAt, anchor: .top)
                }
            }
        }
    }

    /// Settings' own header: the mark that opened the screen beside its name,
    /// and the circled X.
    private var header: some View {
        HStack(alignment: .center) {
            Text("About")
                .chromeHeading(size: Self.titleSize)
                // Read as the word is written, not in the heading's capitals,
                // which VoiceOver may spell out (Danish *OM*). A string,
                // because a `Text` label takes the capitals too.
                .accessibilityLabel(String(localized: "About"))
                .accessibilityAddTraits(.isHeader)
                .titleGlyph(InfoGlyph(), size: Self.titleSize)
                .foregroundStyle(Chrome.ink)
            Spacer(minLength: 12)
            CloseButton { close() }
        }
        .padding(.leading, 30)
        .padding(.trailing, 14)
        .padding(.top, 16)
        .padding(.bottom, 12)
        .frame(maxWidth: Chrome.readableWidth + 16)
        .frame(maxWidth: .infinity)
        .background(Chrome.ground)
        .overlay(alignment: .bottom) {
            LinearGradient(colors: [Chrome.ground, Chrome.ground.opacity(0)],
                           startPoint: .top, endPoint: .bottom)
                .frame(height: 18)
                .offset(y: 18)
                .allowsHitTesting(false)
        }
    }

    /// What two phones hand each other, and what a logged place is. Set as the
    /// lines under Settings' controls are set, at Settings' sizes.
    private var privacy: some View {
        VStack(alignment: .leading, spacing: 22) {
            Text("Privacy")
                .chromeHeading(size: 13)
                .foregroundStyle(Chrome.ink)
                .accessibilityLabel(String(localized: "Privacy"))
                .accessibilityAddTraits(.isHeader)

            // The facts of a meeting, each something the phone really sends,
            // and the last sentence what it keeps afterwards. `privacy2` on the
            // website states the same, and the two should agree.
            paragraph("When you meet someone, your phones connect directly, encrypted, and each hands the other its seed, when that seed was made, its plant's name, the name you chose to show, whether a place may be kept with the meeting, and two random numbers: one that makes the new plant, and one the other phone can use later to offer that plant to the web garden. Each phone keeps both second numbers with the plant, and a number for the meeting made from the first two.")

            // Under the name of the answer it is about, so *this* in its first
            // sentence has something to point at.
            VStack(alignment: .leading, spacing: 12) {
                Text(PlantingLocationMode.geographic.label)
                    .chromeLabel()
                    .foregroundStyle(Chrome.sectionLabel)
                paragraph("A seed planted while this is on carries the coordinates the phone measured, to five decimal places. Nothing is looked up and no place is named — the numbers are the honest record, and a map can say the rest.")
            }
        }
    }

    private func paragraph(_ key: LocalizedStringKey) -> some View {
        Text(key)
            .font(.system(size: 13, weight: .light))
            .foregroundStyle(Chrome.muted)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// An i in a ring, in the chrome's pen: the mark for *About*.
///
/// **Drawn rather than borrowed**, so the row at the foot of Settings, the ⓘ
/// beside *Location description* and the mark beside the sheet's title are one
/// drawing at one weight (`TitleGlyph` strokes a `Shape`), as the cog is on
/// the stage and beside *Settings*. It is the system's `info.circle` in shape:
/// a ring, a stem and a dot, which is the one mark for this on every phone.
struct InfoGlyph: Shape {
    func path(in rect: CGRect) -> Path {
        let box = markBox(rect, 0.94)
        let centre = CGPoint(x: box.midX, y: box.midY)
        // The stroke's room inside the box, as every mark keeps.
        let radius = box.width / 2 - 0.9

        var path = Path()
        path.addEllipse(in: CGRect(x: centre.x - radius, y: centre.y - radius,
                                   width: radius * 2, height: radius * 2))
        // The stem, from a little under the middle to a little over the foot.
        path.move(to: CGPoint(x: centre.x, y: centre.y - radius * 0.10))
        path.addLine(to: CGPoint(x: centre.x, y: centre.y + radius * 0.48))
        // The dot: a ring too small to have a hole once the pen goes round it.
        let dot = max(0.3, radius * 0.05)
        let dotY = centre.y - radius * 0.44
        path.addEllipse(in: CGRect(x: centre.x - dot, y: dotY - dot, width: dot * 2, height: dot * 2))
        return path
    }
}
