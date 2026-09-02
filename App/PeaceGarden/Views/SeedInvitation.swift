import LinkPresentation
import SwiftUI
import UIKit

/// A seed handed to somebody who is not in the room, as the share sheet sees it.
///
/// The screen used to offer `ShareLink(item: url)` and nothing else, and a share
/// sheet handed a bare `URL` is a narrow thing: the apps it lists are the ones
/// that accept `public.url`, the header is a favicon and a domain, and there is
/// no body text for anything to put in a message. What you get is AirDrop, Copy,
/// and whichever document apps happen to be installed.
///
/// **A text item is the widest thing there is.** Every messaging app on a phone
/// accepts plain text — Messages, WhatsApp, Signal, Telegram, Mail, the lot —
/// and every one of them turns a URL sitting in that text back into a tappable
/// link. So the item this offers is a sentence with the link in it, which is
/// also simply what a person would have written.
///
/// The three overrides each buy one thing:
///
/// - `placeholderItem` returns an empty `String`, which is how the sheet decides
///   what to list before the real item has been asked for. A `URL` here would
///   put us back where we started.
/// - `subjectForActivityType` fills Mail's subject line, which is otherwise
///   blank and has to be typed.
/// - `linkMetadata` gives the sheet a title and the code itself to show, so the
///   header says what is being sent rather than showing a domain.
final class SeedInvitation: NSObject, UIActivityItemSource {
    let url: URL
    let code: UIImage?

    /// What arrives with the link, so a message is written rather than a URL
    /// dropped into a chat on its own. In the app's voice, because whoever
    /// receives it has never heard of any of this.
    ///
    /// **Written in the sender's language, and read in the receiver's.** There
    /// is no way round that: the message is composed on this phone and handed
    /// to a messaging app, which knows nothing about who is going to open it.
    /// The link itself carries no words, so the worst case is a sentence
    /// somebody has to guess at above a link that works anyway.
    static var message: String {
        String(localized: """
            A seed from my peace garden. Open this and a plant grows on your phone \
            from my seed and one drawn for you — one that neither of us could have \
            grown alone.
            """)
    }

    static var subject: String { String(localized: "A seed on the wind") }

    init(url: URL, code: UIImage?) {
        self.url = url
        self.code = code
    }

    /// The link on its own line. Some apps trim a trailing sentence and most
    /// linkify the last thing in a message most reliably.
    var body: String { "\(Self.message)\n\n\(url.absoluteString)" }

    func activityViewControllerPlaceholderItem(_ controller: UIActivityViewController) -> Any { "" }

    func activityViewController(
        _ controller: UIActivityViewController,
        itemForActivityType activityType: UIActivity.ActivityType?
    ) -> Any? {
        body
    }

    func activityViewController(
        _ controller: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        Self.subject
    }

    func activityViewControllerLinkMetadata(_ controller: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = Self.subject
        metadata.originalURL = url
        if let code {
            metadata.imageProvider = NSItemProvider(object: code)
        }
        return metadata
    }
}

/// The system share sheet, presented as a sheet.
///
/// `ShareLink` cannot carry a `UIActivityItemSource`, and the item source is the
/// whole point — see `SeedInvitation`. This is the smallest wrapper that lets
/// one be handed over.
struct ActivitySheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
