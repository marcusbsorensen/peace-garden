import SwiftUI
import CoreImage.CIFilterBuiltins
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

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 26) {
                Spacer()

                // The heading voice, not the serif one. `plantName` is italic
                // serif and its own documentation says it is for plant names;
                // this is a screen title, and a title in the name voice claims
                // that "A seed on the wind" is something's name.
                Text("A seed on the wind")
                    .chromeHeading(size: 17)
                    .foregroundStyle(Chrome.ink)

                if let offer, let code = Self.code(for: offer) {
                    Image(uiImage: code)
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 220, height: 220)
                        .padding(18)
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 4))

                    Text("Have them point their camera at this. A plant grows on their phone from your seed and one drawn for them.")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Chrome.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 44)

                    ShareLink(item: offer) {
                        Text("Send it instead")
                            .chromeLabel()
                            .foregroundStyle(Chrome.muted)
                            .pressable()
                    }
                } else {
                    Text("This seed could not be prepared.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Chrome.muted)
                }

                Spacer()

                Text("Each code is for one meeting. Make a new one next time and a different plant grows.")
                    .chromeLabel(size: 10)
                    .foregroundStyle(Chrome.faint)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 44)
                    .padding(.bottom, 34)
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
