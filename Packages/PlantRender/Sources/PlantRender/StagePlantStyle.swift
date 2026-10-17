/// How the plant itself is drawn.
///
/// Colour has always been the plants' alone in Peace Garden — every piece of
/// chrome is white at four opacities on black, precisely so that the one
/// saturated thing on screen is the thing you grew. These two alternatives give
/// that up on purpose, and each is a different reason for wanting to.
///
/// The words and the marks that name the three live in the app, as an extension
/// beside the settings that show them: they are localised, and a package has no
/// string catalogue of its own to translate them from.
public enum StagePlantStyle: String, CaseIterable, Sendable {
    /// The plant as its seed drew it: its own palette, lit and shaded.
    case full
    /// One colour, still lit. The normal and roughness maps stay, so the form
    /// is all there and only the hue is gone — which is a botanical plate
    /// rather than a silhouette.
    case monochrome
    /// The mesh itself, unlit. What the plant is made of rather than what it
    /// looks like, and the only view in the app that admits there is geometry
    /// underneath.
    case wireframe

    /// Whether the tint is the plant's whole colour, and therefore worth
    /// letting somebody choose.
    public var isTinted: Bool { self != .full }
}
