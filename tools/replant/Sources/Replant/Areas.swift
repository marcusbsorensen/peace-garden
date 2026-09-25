import Foundation
import SeedCore

/// One area's table, and how to replay arrivals through the area's own rule.
///
/// **The place is written in the service's words.** Each key is what the
/// area's PHP rule returns and `replant.php` compares against: `plot`, the
/// slot's own fields, `nudgeX` and `nudgeZ`. They are the same names the
/// vector files use, because they are the same port being held to the same
/// Swift, and `Server/.api/replant.php` refuses to write a table whose PHP
/// replay does not come out exactly as this one did.
struct AreaTable: Sendable {
    let table: String
    let area: Area
    /// The slot's fields, in the words of the PHP rule's result.
    let slot: [String]
    let replay: @Sendable ([(SeedID, PlantTraits)]) -> [[String: Double]]

    static let all: [AreaTable] = [
        AreaTable(table: "long_walk", area: .travel, slot: ["side", "tier", "index"]) { arrivals in
            var ways = LongWalk.Walk.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "side": Double(p.slot.side.rawValue),
                        "tier": Double(p.slot.tier.rawValue), "index": Double(p.slot.index),
                        "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
        AreaTable(table: "quiet_garden", area: .peace, slot: ["corner", "index"]) { arrivals in
            var ways = QuietGarden.Room.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "corner": Double(p.slot.corner.rawValue),
                        "index": Double(p.slot.index), "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
        AreaTable(table: "crossing", area: .meeting, slot: ["quarter", "index"]) { arrivals in
            var ways = Crossing.Ways.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "quarter": Double(p.slot.quarter.rawValue),
                        "index": Double(p.slot.index), "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
        AreaTable(table: "orchard", area: .kinship, slot: ["guild", "index"]) { arrivals in
            var ways = Orchard.Ways.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "guild": Double(p.slot.guild.rawValue),
                        "index": Double(p.slot.index), "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
        AreaTable(table: "knot_garden", area: .pattern, slot: ["compartment", "index"]) { arrivals in
            var ways = KnotGarden.Ways.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "compartment": Double(p.slot.compartment.rawValue),
                        "index": Double(p.slot.index), "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
        // **The span is part of the place** in these two since 25 September
        // 2026: how many places a planting holds, two for a lotus. A copy
        // taken before the deploy has no `slot_span` column, and every row in
        // it held one place (`Planner.make` reads a missing span as 1).
        AreaTable(table: "seedbed", area: .beginnings, slot: ["drill", "index", "span"]) { arrivals in
            var ways = Seedbed.Ways.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "drill": Double(p.slot.drill),
                        "index": Double(p.slot.index), "span": Double(p.span),
                        "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
        AreaTable(table: "cold_frame", area: .waiting, slot: ["frame", "rank", "index", "span"]) { arrivals in
            var ways = ColdFrame.Ways.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "frame": Double(p.slot.frame.rawValue),
                        "rank": Double(p.slot.rank.rawValue), "index": Double(p.slot.index),
                        "span": Double(p.span), "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
        AreaTable(table: "glasshouse", area: .light, slot: ["bed", "index", "row"]) { arrivals in
            var ways = Glasshouse.Ways.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "bed": Double(p.slot.bed.rawValue),
                        "index": Double(p.slot.index), "row": Double(p.slot.row),
                        "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
        AreaTable(table: "coppice", area: .renewal, slot: ["coupe", "place", "index"]) { arrivals in
            var ways = Coppice.Ways.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "coupe": Double(p.slot.coupe),
                        "place": Double(p.slot.place.rawValue), "index": Double(p.slot.index),
                        "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
        // **The crop is not in the place**, though the slot holds it: it is a
        // word, the plan's places are numbers, and it is the habit's, which the
        // plan already carries. `replant.php` writes it from its own rule and
        // checks it against the habit.
        AreaTable(table: "home_ground", area: .ground, slot: ["bed", "index"]) { arrivals in
            var ways = HomeGround.Ways.opened()
            return arrivals.map { seed, traits in
                let p = ways.plant(seed: seed, traits: traits)
                return ["plot": Double(p.plot), "bed": Double(p.slot.bed), "index": Double(p.slot.index),
                        "nudgeX": p.nudge.x, "nudgeZ": p.nudge.z]
            }
        },
    ]
}
