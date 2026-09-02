import SwiftUI
import CoreImage.CIFilterBuiltins
import UIKit
import SeedCore

/// Giving a seed to someone whose phone has never heard of this app.
///
/// A code held up to a camera, or a link handed over by AirDrop or message.
/// Where it lands, it takes root: their phone draws a seed of its own and
/// crosses it with this one.
struct SeedOfferView: View {
    @Environment(GardenModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    @State private var offer: URL?
    /// Bumped rather than set, so the haptic fires again on a second copy.
    @State private var copied = 0
    @State private var sharing = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 22) {
                Spacer()

                // The heading voice, not the serif one. `plantName` is italic
                // serif and its own documentation says it is for plant names;
                // this is a screen title, and a title in the name voice claims
                // that "A seed on the wind" is something's name.
                Text("A seed on the wind")
                    .chromeHeading(size: 17)
                    .foregroundStyle(Chrome.ink)

                if let offer, let code = Self.code(for: offer) {
                    // Above the code, not below it. An instruction underneath
                    // the thing it is about is a caption — read after the fact,
                    // if at all — and this one is the whole of what to do next.
                    // Said before the code, it is a sentence somebody acts on.
                    Text("If they scan this QR code, a plant will grow on both of your phones. It is a mix of the unique seeds on them.")
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Chrome.ink.opacity(0.88))
                        .multilineTextAlignment(.center)
                        .lineSpacing(5)
                        .padding(.horizontal, 30)

                    Image(uiImage: code)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 210, height: 210)
                        .padding(16)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    // Between the code and the ways of sending it, because it
                    // is about the code rather than about the screen. At the
                    // foot it was a colophon nobody read, in a grey nobody
                    // could read it in.
                    Text("This seed code is unique to this exchange. A unique plant will grow from every time seeds are exchanged, even with the same person.")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Chrome.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 30)

                    // The row sits at the foot, level with the marks on the
                    // stage, rather than floating under the code. Every screen
                    // in the app now puts what you can do in the same band.
                    Spacer()
                    sending(link: offer, code: code)
                        .padding(.bottom, 30)
                } else {
                    Text("This seed could not be prepared.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Chrome.muted)
                    Spacer()
                }
            }
            .frame(maxWidth: Chrome.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .overlay(alignment: .topTrailing) {
            QuietButton(title: "Close") { dismiss() }
                .padding(.trailing, 12)
                .padding(.top, 12)
        }
        .onAppear {
            // A fresh nonce per screen, so the same two people meeting twice
            // grow two different plants.
            offer = model.makeOffer()
        }
    }

    // MARK: - Sending it instead

    /// Three ways to hand a seed to somebody who is not in the room.
    ///
    /// There used to be one — `ShareLink(item:)` with a bare `URL` — and what
    /// that offers is AirDrop, Copy and whichever document apps are installed.
    /// The messaging apps were the missing ones, which is the only kind of
    /// sending most people do. `SeedInvitation` has the whole diagnosis and the
    /// fix: the item is a sentence with the link in it rather than a URL on its
    /// own, because text is the one thing every messaging app accepts.
    ///
    /// **Copy the link is its own control** rather than a row inside the sheet,
    /// because a link on the clipboard is the answer to every app this list has
    /// never heard of.
    ///
    /// **The picture is a second share** rather than an alternative to the
    /// first. A code sent as an image is scanned by a camera and works where a
    /// link is awkward — printed, on a screen across a room, in an app that
    /// eats URLs — but it cannot be tapped, so it is offered beside the link
    /// and never instead of it.
    @ViewBuilder
    private func sending(link: URL, code: UIImage) -> some View {
        VStack(spacing: 12) {
            Button { sharing = true } label: {
                Text("Send link")
                    .chromeLabel()
                    .foregroundStyle(Chrome.ink)
                    .pressable(isProminent: true)
            }
            .buttonStyle(.plain)
            .sheet(isPresented: $sharing) {
                ActivitySheet(items: [SeedInvitation(url: link, code: code)])
            }

            HStack(spacing: 8) {
                Button {
                    UIPasteboard.general.string = link.absoluteString
                    copied += 1
                } label: {
                    Text(copied > 0 ? "Link copied" : "Copy link")
                        .chromeLabel()
                        .foregroundStyle(copied > 0 ? Chrome.pinkGold : Chrome.muted)
                        .pressable()
                }
                .buttonStyle(.plain)
                .sensoryFeedback(.success, trigger: copied)

                // The picture keeps `ShareLink`: an image needs no item source,
                // because every app that takes a picture takes this one.
                ShareLink(
                    item: Image(uiImage: code),
                    preview: SharePreview(SeedInvitation.subject, image: Image(uiImage: code))
                ) {
                    Text("Send QR code")
                        .chromeLabel()
                        .foregroundStyle(Chrome.muted)
                        .pressable()
                }
            }

            // A fresh code without leaving the screen.
            //
            // The screen already draws a new nonce every time it opens, so
            // somebody standing with three people could get three different
            // codes by closing and reopening it three times. Nobody would
            // guess that, and nobody should have to: the sentence above says
            // to make a new one for every person, so the screen has to offer
            // one.
            Button {
                offer = model.makeOffer()
                copied = 0
            } label: {
                Text("Create a new one")
                    .chromeLabel(size: 10)
                    .foregroundStyle(Chrome.faint)
                    .pressable(horizontal: 14)
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
        }
    }

    /// Rendered dark-on-white: scanners want the contrast, and it reads as
    /// something physical being held out.
    static func code(for url: URL) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(url.absoluteString.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = CIContext().createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
