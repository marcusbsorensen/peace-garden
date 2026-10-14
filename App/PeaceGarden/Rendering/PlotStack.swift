import SwiftUI

/// Everything on the plot, each laid over the whole of it in turn: a
/// `ZStack(alignment: .topLeading)` that never asks what is in it where its
/// edges are (14 October 2026).
///
/// **Why not the `ZStack`.** Every plant, pool, light and shadow on the plot is
/// placed by its own `position` or transform, so the stack's alignment did
/// nothing but ask each of them, all the way down through their modifiers, for
/// the alignment guides it then ignored — and it asked on every layout pass of
/// the screen, which the sky's moving clock causes every frame. Measured with
/// `sample` on a garden of five hundred, that was most of what a frame cost
/// once nothing on the plot was being drawn again. This takes the size it is
/// offered and puts each child at its top-left corner, offered the same size,
/// which is what the `ZStack` did with them too.
struct PlotStack: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions()
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews,
                       cache: inout ()) {
        let offered = ProposedViewSize(bounds.size)
        for subview in subviews {
            subview.place(at: bounds.origin, anchor: .topLeading, proposal: offered)
        }
    }

    // **Nothing in here has a guide of its own to offer.** A `Layout`'s own
    // answer, left to its default, merges every child's — the same walk down
    // through every plant the `ZStack` made.
    func explicitAlignment(of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize,
                           subviews: Subviews, cache: inout ()) -> CGFloat? {
        nil
    }

    func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize,
                           subviews: Subviews, cache: inout ()) -> CGFloat? {
        nil
    }
}
