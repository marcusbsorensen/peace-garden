#if os(WASI)
import FoundationEssentials
import WASILibc
#else
import Foundation
#endif

/// The broad shape a plant grows into.
///
/// Archetypes exist so that variation reads as *different kinds of plant*
/// rather than one plant with the sliders moved. Each one biases the trait
/// ranges through `ArchetypeProfile`; the seed still decides everything within
/// those bounds.
public enum Archetype: String, CaseIterable, Codable, Sendable {
    case spire      // tall, dense vertical raceme
    case umbel      // flat-topped cluster on fine stalks
    case fern       // no bloom to speak of; deep pinnate foliage
    case orchid     // few, large, asymmetric blooms
    case lotus      // broad cupped petals, heavy centre
    case thistle    // spiny bracts, tight globe head
    case vine       // long lax stem, small paired leaves
    case bell       // nodding tubular flowers
    case star       // flat radial bloom, sharp petals
    case poppy      // single crumpled bloom on a bare stem
    case succulent  // thick short stem, fleshy rosette
    case plume      // feathery many-branched inflorescence

    /// The family's name, built the way a real one is.
    ///
    /// A botanical family is named from a type genus plus `-aceae` — Oleaceae
    /// from *Olea*, Campanulaceae from *Campanula* — so this is derived from
    /// the low-merous root rather than written into a second table that could
    /// disagree with the first. Every root ends in a consonant, so the join is
    /// a join and nothing is elided.
    ///
    /// One lands on a real family by the same root that named it, which was not
    /// arranged: **Olaceae** beside Oleaceae, both from *olea*, the olive.
    /// **Cynaceae** beside Cynareae is likely but not certain — `Cyn` was taken
    /// for Gk *kyōn*, the dog, and *Cynara*'s own descent from it is disputed.
    ///
    /// **Calaceae is not a third.** It was claimed as one against
    /// Campanulaceae, and that is wrong: *Campanula* is a diminutive of
    /// *campana*, a bell, and has nothing to do with *kalos*. The two words
    /// share two letters and no root. Corrected here rather than quietly
    /// dropped, because the claim was used as an argument for which family
    /// `Cal` belongs to.
    ///
    /// Nothing shows this yet. It is here because the rank is real — it is what
    /// holds a floral plan, and what an area's type specimens are types *of* —
    /// and a rank the code cannot name is one the next reader has to infer.
    public var familyName: String {
        PlantName.genusHead(for: self, .few) + "aceae"
    }

    public var displayName: String {
        switch self {
        case .spire: return "Spire"
        case .umbel: return "Umbel"
        case .fern: return "Fern"
        case .orchid: return "Orchid"
        case .lotus: return "Lotus"
        case .thistle: return "Thistle"
        case .vine: return "Vine"
        case .bell: return "Bell"
        case .star: return "Star"
        case .poppy: return "Poppy"
        case .succulent: return "Succulent"
        case .plume: return "Plume"
        }
    }
}

/// How a plant carries its flowers, and therefore what shape it is.
///
/// Until this existed every archetype was one unbranched stem at different
/// proportions, which is why three plants side by side read as the same plant
/// three times — and why they all read as too tall. A tower spends its whole
/// budget on height because there is nowhere else to spend it.
///
/// Named `Inflorescence` rather than `Form`, which is what the build spec
/// called it, for two reasons. `Genome.Form` already exists and a bare `Form`
/// inside `Genome` would resolve to that one. And these three cases *are*
/// inflorescence types in the botany the rest of this file borrows its
/// vocabulary from, so the precise word costs nothing and says more.
public enum Inflorescence: String, CaseIterable, Sendable {
    /// Blooms on the axis: a single stem, flowers at the tip or up the nodes.
    ///
    /// What every plant was before the other two existed, unchanged, and still
    /// the commonest. It is named so that the other two read as choices rather
    /// than as exceptions.
    case raceme
    /// Stalks off the upper stem, a bloom on each.
    ///
    /// `branchSpread` carries the whole range between a flat-topped cluster and
    /// a feathery spray, which is worth having as a number rather than as two
    /// more cases — the two ends are the same construction differently tuned.
    case head
    /// A bare stem and one much larger bloom.
    ///
    /// Fewer blooms is what buys the size. A spire carries a dozen small
    /// flowers and cannot afford a large one; a poppy carries one and can
    /// afford nothing else. The plants should look like they cost the same.
    case solitary
}

/// What holds a flower from beneath: the body the petals stand on.
///
/// **Every flower gets one, because the centre alone was a hollow.** The
/// centre was a dome open underneath, wider than the petals' own base and
/// centred on the one point every petal sprang from, so the petals pierced it
/// and its rim hung outside them — a ring round the flower, and from below the
/// inside of a bowl. Now the petals stand on the centre's rim and something
/// closed sits under both. What it is depends on the family, which is botany
/// rather than taste: a daisy has a shallow green cup, a thistle an urn of
/// scales, a poppy's sepals fall as it opens and leave only the swollen top of
/// the stalk.
public enum Calyx: String, CaseIterable, Sendable {
    /// A lid under the centre in the stem's colour and nothing to see: an
    /// umbel's florets sit straight on their stalks.
    case lid
    /// The top of the stalk swelling into the flower, in the stem's colour.
    case swelling
    /// A thickened flower stalk, as an orchid's ovary is, in the stem's colour.
    case stalk
    /// A small closed green cup hugging the petals' bases.
    case cup
    /// A wide, shallow green cup: a composite's involucre.
    case shallowCup
    /// A bulbous urn of scales the florets stand out of: a thistle's
    /// involucre.
    case urn
}

/// How a flower's sepals are carried, where it has any.
public enum Sepals: String, CaseIterable, Sendable {
    case none
    /// Swept back beneath the flower, as every flower's were before this.
    case reflexed
    /// Five slender lobes standing out from the cup: a bellflower's calyx.
    case spreading
    /// Short lobes held up against the petals' backs.
    case appressed
}

/// How many parts a flower is built in — its merosity.
///
/// **The character that separates the two genus roots of a family**, and the
/// commonest first question in a real key: *petals 5* or *petals 3*. It is
/// discrete rather than a range on purpose. A cut through a continuum is not
/// diagnostic — a key cannot use *petals fewer than average* — so the class is
/// what the seed draws and the count follows from it.
///
/// A real flora then allows the variant a real plant has: *petals 5, rarely 4
/// or 6*. `Genome` draws that too, which is what keeps a bed of one genus from
/// reading as printed rather than grown.
public enum Merosity: String, CaseIterable, Sendable {
    case few
    case many
}

/// Multipliers and overrides an archetype applies to the seed's raw draws.
///
/// **The vegetative multipliers here and the vegetative ranges in `Genome` do
/// two different jobs, and it is worth saying which.** A multiplier moves where
/// a family's centre sits — it is what makes a succulent squat and a vine lax,
/// and it is between-family difference. A range decides how far one plant may
/// stand from its own relatives, which is what docs/TAXONOMY.md
/// §"What the archetype profiles constrain" means by widening the vegetative
/// half. So that widening went into the ranges and left these alone: pushing a
/// multiplier further from 1 would have made the twelve kinds more unlike each
/// other without making any two plants of one kind any less alike.
public struct ArchetypeProfile: Sendable {
    public var heightScale: Double = 1
    public var stemThickness: Double = 1
    public var nodeScale: Double = 1
    public var leafLengthScale: Double = 1
    public var leafWidthScale: Double = 1
    public var leafDroop: Double = 1
    /// The two counts this family's genera are built in, low and high.
    ///
    /// **This replaced `petalCountScale`**, which multiplied a 3...13 draw and
    /// so gave every family a smear of counts with no two plants reliably
    /// alike. A genus that cannot promise its own petal count cannot be keyed
    /// on it, and keying on it is the whole of `docs/TAXONOMY.md` §1.
    ///
    /// Both are real counts for the plant in question rather than a scale:
    /// an orchid is 3-merous and a thistle carries a head of dozens, and no
    /// single multiplier says both.
    public var petals: (few: Int, many: Int) = (5, 8)
    public var petalLengthScale: Double = 1
    public var petalWidthScale: Double = 1
    /// Negative curls cup the petals inward, positive reflex them back.
    public var petalCurlBias: Double = 0
    public var headPitchBias: Double = 0
    public var centreScale: Double = 1
    /// Flowers open at every node rather than only at the tip.
    ///
    /// Meaningful for `.raceme` alone. The other two forms decide where their
    /// flowers go from the form itself, and their profiles leave this be.
    public var bloomsAtNodes: Bool = false
    /// Fraction of blooms present at all — a fern gets almost none.
    public var bloomPresence: Double = 1
    public var swayScale: Double = 1

    public var inflorescence: Inflorescence = .raceme
    /// How large every bloom is drawn, against a raceme's.
    public var bloomScale: Double = 1
    /// Flat-topped at 0, an open spray at 1. `.head` only.
    public var branchSpread: Double = 0
    /// Before the seed's own draw scales it. `.head` only.
    public var branchCount: Int = 5
    /// What holds the flower from beneath. A small green cup unless the family
    /// says otherwise.
    public var calyx: Calyx = .cup
    /// How the sepals are carried. `bloom.hasSepals` still decides whether a
    /// plant shows them, except a bell's, which always has its five.
    public var sepals: Sepals = .appressed

    // MARK: Habit — how wide a plant stands for its height
    //
    // **Everything below exists because every plant was a stick.** Measured
    // across six thousand seeds on 24 September 2026: a median height of a
    // metre against a spread of forty-five centimetres, and six plants in a
    // hundred wider than tall, nearly all of them plumes. Two things did it.
    // Leaves sat only on nodes between a sixth and nine-tenths of the way up
    // the stem, so nothing ever grew from the ground; and a leaf's length was
    // drawn without reference to the stem carrying it, so a two-metre plant
    // wore the leaves of a forty-centimetre one. There was no rosette, no
    // pad, no frond — no low plant at all.
    //
    // These are the habit a family grows in, the way `inflorescence` is the
    // way it flowers. The seed still decides everything within them.

    /// Every leaf rises from the crown, and the stem is only a flowering stalk.
    ///
    /// A succulent's rosette, a fern's shuttlecock of fronds, a lotus's pads,
    /// an orchid's fan of straps. The node count still says how many leaves
    /// there are — the name counts them — but none of them is carried up the
    /// stem.
    public var rosette: Bool = false
    /// Leaves at the crown as well as those the nodes carry: a basal clump
    /// under a poppy, the big divided leaves at the foot of an umbel.
    ///
    /// On a rosette these are added to the nodes' own, so it is also a floor
    /// on how sparse a rosette can be.
    public var crownLeaves: ClosedRange<Int> = 0...0
    /// How long a crown leaf is against a stem leaf. A plant's largest leaves
    /// are at its foot, where they have had longest to grow.
    public var crownLengthScale: Double = 1.6
    /// How far off vertical the outermost crown leaf lies, in radians. Inner
    /// ones stand more upright, which is what gives a rosette a centre and a
    /// fern its vase.
    public var crownPitch: ClosedRange<Double> = 0.9...1.3
    /// How much shorter the innermost crown leaf is than the outermost.
    ///
    /// A half for most: a rosette's centre is its youngest, smallest leaves.
    /// A fern's shuttlecock is the exception — its inner fronds are nearly as
    /// long as its outer ones and simply stand straighter, which is what gives
    /// it height rather than a bowl.
    public var crownTaper: Double = 0.5
    /// How much more upright the innermost crown leaf stands than the
    /// outermost, as a fraction of the outer one's angle off vertical.
    ///
    /// Most crowns close toward the middle, which is what gives a fern its
    /// vase. A succulent's opens: stood up at the same rate its fleshy leaves
    /// made a wall, and a rosette drawn that way read as a box.
    public var crownRise: Double = 0.55
    /// Crown leaves are round, flat, held up on their own stalks from the
    /// middle of the blade: a lotus's pads. The only family that has them.
    public var pads: Bool = false
    /// How thick a leaf is against its own width, 0 for a blade.
    public var fleshiness: Double = 0
    /// Crown leaves cut nearly to the midrib into this many pairs of
    /// leaflets, 0 for a leaf with an ordinary margin.
    ///
    /// A fern's stem leaves used to read as pinnae up a stalk, which was most
    /// of what made it a fern. Brought down to the crown as whole fronds they
    /// read as broad blades — an agave, not a fern — until the frond itself is
    /// cut.
    public var pinnae: ClosedRange<Int> = 0...0
    /// How far a stem leaf's size follows the stem's height, 0 not at all and
    /// 1 in proportion.
    ///
    /// **This is what keeps a tall plant from being a twig.** Half of the size
    /// is still the leaf's own draw, so a tall plant can be sparse-leaved and a
    /// short one leafy; the other half answers to the plant.
    public var leafReach: Double = 0.55
    /// Where the stem's nodes sit, as fractions of its length.
    public var nodeZone: ClosedRange<Double> = 0.16...0.90

    public static func profile(for archetype: Archetype) -> ArchetypeProfile {
        var profile = ArchetypeProfile()
        switch archetype {
        case .spire:
            profile.petals = (4, 6)
            profile.heightScale = 1.35
            profile.nodeScale = 1.6
            profile.petalLengthScale = 0.55
            profile.bloomsAtNodes = true
            profile.leafLengthScale = 0.8
            // A tower on purpose, and one of three the garden keeps. A few
            // leaves at its foot so it stands on something.
            profile.crownLeaves = 0...3
            profile.crownPitch = 0.6...1.0
        case .umbel:
            profile.petals = (5, 8)
            profile.inflorescence = .head
            profile.branchSpread = 0
            profile.branchCount = 5
            profile.bloomScale = 0.8
            profile.heightScale = 0.9
            profile.petalLengthScale = 0.45
            profile.centreScale = 0.6
            profile.leafDroop = 1.2
            // The big divided leaves an umbellifer makes at its foot before it
            // sends up a flowering stem at all.
            profile.crownLeaves = 2...5
            profile.crownLengthScale = 1.7
            profile.crownPitch = 0.7...1.2
            profile.leafReach = 0.6
            profile.calyx = .lid
            profile.sepals = .none
        case .fern:
            profile.petals = (3, 5)
            profile.nodeScale = 1.9
            profile.leafLengthScale = 1.5
            profile.leafWidthScale = 0.7
            // **The one vegetative multiplier that came down**, from 1.5, and
            // it buys the widening for the other eleven families. `Genome`'s
            // droop range went from `0...1` to `0...1.15`, and 1.15 times 1.5
            // is past where a frond stops reading — `addLeaf` sags a blade
            // along its own frame, so on a leaf held close to the stem the sag
            // goes sideways and the blade kinks back over itself. Drawn at a
            // ladder of droops, the fern was the only family that could reach
            // that, because its multiplier was the largest on this table.
            //
            // 1.15 times 1.3 is 1.495, so **a fern's droop ceiling is where it
            // already was** and its worst-looking individual is the same one
            // the garden already had. Nothing was lost to buy the rest.
            //
            // Since the fronds came down to the crown they arch rather than sag
            // — `PlantBuilder.addBlade` turns the midrib instead of pushing it —
            // so the kink cannot happen at any droop. 1.3 stays because it is
            // the curve a fern already had.
            profile.leafDroop = 1.3
            profile.bloomPresence = 0.05
            profile.swayScale = 1.3
            // **A shuttlecock, not a stalk with leaves on.** Every frond comes
            // from the crown, the outer ones arching out and the inner ones
            // standing up, so a fern is a vase as wide as it is tall. Its
            // height is its fronds'; the stem is only the crown between them.
            profile.rosette = true
            profile.crownLeaves = 2...4
            profile.crownLengthScale = 2.2
            profile.crownPitch = 0.15...0.45
            profile.heightScale = 0.32
            profile.crownTaper = 0.2
            profile.pinnae = 9...15
            profile.sepals = .none
        case .orchid:
            profile.petals = (3, 6)
            profile.inflorescence = .solitary
            profile.bloomScale = 1.7
            profile.heightScale = 0.6
            profile.stemThickness = 0.8
            profile.nodeScale = 0.6
            profile.petalLengthScale = 1.0
            profile.petalWidthScale = 1.3
            profile.petalCurlBias = 0.25
            profile.headPitchBias = 0.5
            profile.leafLengthScale = 1.2
            // A fan of broad straps at the base and one flower on a bare
            // spike, which is a slipper orchid exactly.
            profile.rosette = true
            profile.crownLeaves = 1...3
            profile.crownLengthScale = 1.7
            profile.crownPitch = 0.95...1.35
            profile.leafWidthScale = 1.5
            profile.calyx = .stalk
            profile.sepals = .none
        case .lotus:
            profile.petals = (8, 14)
            profile.inflorescence = .solitary
            profile.bloomScale = 1.7
            profile.heightScale = 0.31
            profile.stemThickness = 1.4
            // A water lily's flower is smaller than its pads and opens wide
            // over them. At a whole petal and a deep cup it was a goblet half
            // a metre across on a stalk, and the pads were a saucer under it.
            profile.petalLengthScale = 0.6
            profile.petalWidthScale = 1.5
            profile.petalCurlBias = -0.3
            profile.centreScale = 1.7
            profile.nodeScale = 0.5
            // **Low and broad**: round pads lying over one another just off
            // the ground on short stalks, and the flower held just clear of
            // them — `Genome` sizes the stem from the pads. It was a seventy-
            // centimetre stem with three ordinary leaves.
            profile.rosette = true
            profile.pads = true
            profile.crownLeaves = 2...4
            profile.crownLengthScale = 1.9
            profile.leafLengthScale = 1.25
            profile.sepals = .none
        case .thistle:
            profile.petals = (13, 21)
            profile.inflorescence = .solitary
            profile.bloomScale = 2.4
            profile.heightScale = 0.9
            profile.nodeScale = 0.55
            profile.stemThickness = 1.2
            profile.petalLengthScale = 0.4
            profile.petalWidthScale = 0.3
            profile.petalCurlBias = -0.3
            profile.centreScale = 1.3
            // A thistle is a rosette for its first year and bolts in its
            // second; the flat spiny rosette stays at its foot.
            profile.crownLeaves = 3...7
            profile.crownPitch = 1.1...1.4
            profile.leafReach = 0.4
            profile.calyx = .urn
            profile.sepals = .none
        case .vine:
            profile.petals = (4, 6)
            profile.heightScale = 1.45
            profile.stemThickness = 0.6
            profile.nodeScale = 1.7
            profile.leafLengthScale = 0.65
            profile.leafWidthScale = 1.1
            profile.swayScale = 1.8
            profile.bloomsAtNodes = true
            profile.petalLengthScale = 0.5
            profile.leafReach = 0.3
        case .bell:
            // Five and ten rather than five and six: *Campanula* single, and
            // Campanula 'Flore Pleno' doubled. Six was drawn and looked at, and
            // the two genera were not tellable apart — a nodding tube is small
            // and one lobe is nothing at this size. Doubling is what a garden
            // does to a bell anyway, and twice the parts is the one number that
            // is both legible and true.
            profile.petals = (5, 10)
            profile.petalCurlBias = -0.75
            profile.petalLengthScale = 1.1
            profile.headPitchBias = 1.0
            profile.bloomsAtNodes = true
            profile.crownLeaves = 3...7
            profile.crownPitch = 0.95...1.35
            profile.leafLengthScale = 1.3
            profile.crownLengthScale = 2.3
            profile.leafReach = 0.8
            profile.sepals = .spreading
        case .star:
            profile.petals = (5, 8)
            profile.petalCurlBias = 0.35
            profile.petalWidthScale = 0.6
            profile.centreScale = 0.7
            // A daisy's habit: leafy from the ground up, and bushy for it.
            profile.crownLeaves = 4...9
            profile.nodeZone = 0.08...0.85
            profile.leafReach = 0.8
            profile.leafLengthScale = 1.25
            profile.heightScale = 0.9
            profile.crownLengthScale = 2.3
            profile.crownPitch = 0.95...1.35
            profile.calyx = .shallowCup
            profile.sepals = .reflexed
        case .poppy:
            profile.petals = (4, 6)
            profile.inflorescence = .solitary
            profile.bloomScale = 1.7
            profile.heightScale = 0.75
            profile.nodeScale = 0.35
            profile.leafLengthScale = 1.2
            profile.petalLengthScale = 1.0
            profile.petalWidthScale = 1.6
            profile.petalCurlBias = -0.35
            profile.headPitchBias = 0.35
            profile.swayScale = 1.4
            // Upright still, but out of a clump of leaves at the ground, and
            // the stem bare above its few low nodes. The clump is few, held
            // up, and cut to the midrib as a poppy's leaves are: longer and
            // flatter, it lay out round the stem as a large green star.
            profile.crownLeaves = 3...6
            profile.crownLengthScale = 2.0
            profile.crownPitch = 0.7...1.1
            profile.nodeZone = 0.05...0.35
            profile.leafReach = 0.7
            profile.calyx = .swelling
            profile.sepals = .none
            profile.pinnae = 5...8
        case .succulent:
            // **A rosette at last.** It was a thick stem with small leaves up
            // it — a leafy column forty-five centimetres tall and twenty
            // across — and nothing in the garden sat on the ground. Now every
            // leaf comes from the crown, fleshy, the outer ones lying out and
            // the inner ones cupped, and the stem is only the short flowering
            // stalk that four plants in ten never send up.
            profile.petals = (8, 12)
            profile.rosette = true
            profile.fleshiness = 1
            profile.crownPitch = 0.95...1.3
            profile.crownLengthScale = 1
            profile.heightScale = 0.31
            profile.stemThickness = 0.9
            profile.nodeScale = 2.1
            profile.leafLengthScale = 1.4
            profile.leafWidthScale = 0.85
            profile.leafDroop = 0.3
            profile.petalLengthScale = 0.5
            profile.bloomPresence = 0.6
            profile.crownRise = 0.3
        case .plume:
            profile.petals = (5, 10)
            profile.inflorescence = .head
            profile.branchSpread = 1
            profile.branchCount = 7
            profile.bloomScale = 0.8
            profile.heightScale = 0.75
            profile.nodeScale = 1.8
            profile.petalLengthScale = 0.35
            profile.petalWidthScale = 0.35
            profile.leafLengthScale = 0.6
            profile.leafWidthScale = 0.4
            profile.crownLeaves = 0...3
        }
        return profile
    }
}
