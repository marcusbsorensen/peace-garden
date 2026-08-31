import Foundation

/// The standing choices about the shared peace garden.
///
/// Phase 1 makes no network request at all, so nothing here is acted on yet —
/// see docs/PHASES.md. The preference exists now because it is a decision about
/// what somebody is willing to be told, and the honest place for it is beside
/// the other things they have already decided rather than sprung on them the
/// day the feature arrives.
enum Sharing {
    /// Whether to be told when a plant this person helped make is shared.
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

    static var wantsInvitations: Bool {
        UserDefaults.standard.object(forKey: invitationsKey) as? Bool ?? invitationsDefault
    }
}
