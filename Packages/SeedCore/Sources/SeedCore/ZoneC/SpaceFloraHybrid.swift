#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

/// A cross of two space seeds, drawn as space flora.
///
/// **The same ladder as `GeneSource`, trait by name.** Each named trait of the
/// child is, 36 times in 100, its first parent's draw; 36 in 100 its second's;
/// 22 a blend of the two; and 6 a draw of its own. A hybrid reads as clearly
/// descended from both and still holds a surprise.
///
/// **Sorted, so both phones draw the same plant.** The parents arrive in either
/// order — the finder's phone holds the found seed second and the sender's holds
/// it first — and are sorted on their whole seeds, byte by byte, exactly as
/// `Pollination` sorts them. Neither phone needs to know who found whom.
///
/// **Each parent is read by its first 16 bytes**, which for a found seed is `r`
/// and for the finder's own Zone C seed is the front half of it. The child is
/// read the same way, from `Pollination.cross`'s digest.
///
/// **The kind is inherited on the same ladder**, with one change: a kind cannot
/// be blended, so the 22% a blend would take is a coin between the two parents'
/// kinds. A child is then its first parent's kind 47 times in 100, its second's
/// 47, and 6 times in 100 a kind drawn afresh from all five — which, with two
/// parents of different kinds, is a kind neither parent was about one cross in
/// twenty-eight.
///
/// **A cross of two kinds carries one small point of the other**: the heart of
/// every flower takes its hue from the other kind's band. Every other trait
/// reads through the child's own kind: a parent's proportions travel and the
/// child's kind sets the bounds, so a tall Comet Reed crossed into a Star
/// Cluster gives a Star Cluster near the top of its height range and never a
/// two-metre one. Structure — rosette, strap, cushion, inflorescence, calyx,
/// outline — is the child's kind's and never a parent's, so no cross is half a
/// reed and half a cushion.
public enum SpaceFloraHybrid {
    /// The plant a Zone C cross grows.
    ///
    /// - Parameters:
    ///   - child: `Pollination.cross`'s seed.
    ///   - parentA: either parent; they are sorted here.
    ///   - parentB: the other.
    ///   - encounterID: the meeting, kept in the lineage.
    public static func draw(
        child: SeedID,
        parentA: SeedID,
        parentB: SeedID,
        encounterID: Data
    ) -> SpaceFlora {
        let sorted = parentA < parentB ? (parentA, parentB) : (parentB, parentA)
        let genes = SpaceGenes.hybrid(child: child.bytes, first: sorted.0.bytes, second: sorted.1.bytes)
        return SpaceFlora(
            genes: genes,
            lineage: .crossed(parentA: sorted.0, parentB: sorted.1, encounterID: encounterID)
        )
    }
}

extension SpaceFlora {
    /// The child's kind, from its parents' on the 36/36/22/6 ladder with the
    /// blend settled by a coin. See `SpaceFloraHybrid`.
    static func inheritedKind(genes: SpaceGenes, parentKinds: (SpaceKind, SpaceKind)) -> SpaceKind {
        let roll = SpaceGenes.rawUnit(genes.key, "inherit:space.kind")
        if roll < GeneSource.inheritFirstParent {
            return parentKinds.0
        }
        if roll < GeneSource.inheritSecondParent {
            return parentKinds.1
        }
        if roll < GeneSource.inheritBlend {
            return SpaceGenes.rawUnit(genes.key, "blend:space.kind") < 0.5 ? parentKinds.0 : parentKinds.1
        }
        return SpaceKind.drawn(from: SpaceGenes.rawUnit(genes.key, "mutate:space.kind"))
    }
}

public extension CrossPollinationResult {
    /// The plant this cross grows in Zone C: space flora, drawn from the child
    /// seed and the two parents. The ordinary garden's `genome` is the same
    /// cross drawn as an earthly plant, and Zone C never shows it.
    ///
    /// Built from the sorted parents the result already holds, so the finder's
    /// phone and the sender's reach the same plant from the same encounter.
    var spaceFlora: SpaceFlora {
        SpaceFloraHybrid.draw(
            child: childSeed,
            parentA: parentA,
            parentB: parentB,
            encounterID: encounterID
        )
    }
}
