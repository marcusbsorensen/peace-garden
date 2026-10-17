import Foundation

/// The standing choices about the shared peace garden.
///
/// Phase 1 makes no network request at all, so nothing here is acted on yet —
/// see docs/PHASES.md. The preference exists now because it is a decision about
/// what somebody is willing to be told, and the honest place for it is beside
/// the other things they have already decided rather than sprung on them the
/// day the feature arrives.
enum Sharing {
    /// Whether the app asks the web garden for news each time it starts. In
    /// Settings, *News from the garden*; until 17 October 2026, *Alert me when a
    /// joint seed is shared*. The stored key is the old one, so nobody's choice
    /// moved when the label did.
    ///
    /// The first thing it brings is whether a plant this person helped make has
    /// been shared.
    ///
    /// The story: a plant belongs to two people, so one of them publishing it
    /// is one of them speaking. The public page names the sharer alone. The
    /// other gardener is then asked whether they would like their name on it
    /// too, and the page says nothing about them until they say yes.
    static let invitationsKey = "sharing.invitations.v1"

    /// On unless somebody says otherwise.
    ///
    /// Defensible because of what the tie actually is: these two people met in
    /// person and made a plant together. That is a great deal stronger than the
    /// relationship most apps assume when they decide to contact somebody. The
    /// switch is in Settings from the first day so it is a choice rather than a
    /// discovery.
    static var invitationsDefault: Bool { true }

    /// **Off has to mean no request**, not a suppressed banner.
    ///
    /// Written down here rather than in `docs/WEBSITE.md` alone, because this is
    /// the property the first line of networking code will quietly break. On,
    /// the app asks the service — once, each time it starts — whether anything
    /// has been shared against any of the contact tokens in its garden, with or
    /// without any (Zone C's two slots ride in the same request, so every phone
    /// with the switch on sends one). Off, it does not ask, and the service is
    /// therefore never told this phone exists.
    ///
    /// **Turning it off stops all of that.** No request goes at all, so nothing
    /// is asked about shared plants, nothing goes into either of Zone C's pools,
    /// no seed is taken from Autonaut's `out/` and no return is sent or opened.
    /// And `Seeds/v1/exchange` is deleted (`GardenModel.reconcileSuite`), so
    /// Autonaut stops offering "Send as a seed". Zone C's own switch
    /// (`ZoneCExchange.enabledKey`) is a second condition on top of this one,
    /// not a replacement: it can only narrow what a request carries, and this
    /// one decides whether there is a request.
    ///
    /// A switch that only hid the answer while the question was still being
    /// asked would be the one kind of untruth this project has been careful
    /// about everywhere else: the sentence on the exchange screen listing what
    /// crosses between two phones was rewritten the same day the contact token
    /// made it incomplete, rather than left standing because it was nearly true.
    static var wantsInvitations: Bool {
        UserDefaults.standard.object(forKey: invitationsKey) as? Bool ?? invitationsDefault
    }
}
