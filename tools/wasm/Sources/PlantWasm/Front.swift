#if os(WASI)
import FoundationEssentials
#else
import Foundation
#endif
import SeedCore

// The front page's meeting: two people who meet once, and what grows.
//
//   pg_front_meeting(n)   the n-th demonstration meeting as text,
//                         "child parentA parentB encounter" (hex, space-separated) —
//                         the shape `pg_grow_hybrid` takes, so the page grows the
//                         child from it and each parent with `pg_grow`
//
// **A demonstration, and said to be one.** Nobody met: the two parents are
// minted from fixed words, the way every workbench's arrivals are, so the page
// can show what a meeting makes without showing anybody's plant. The arithmetic
// is the app's own — `Pollination.cross` — so the child is what the app would
// grow from those two seeds.

@_expose(wasm, "pg_front_meeting")
@_cdecl("pg_front_meeting")
public func pgFrontMeeting(_ n: Int32) -> Int32 {
    let parentA = SeedMint.mint(fromEntropy: Data("front-meeting-\(n)-a".utf8))
    let parentB = SeedMint.mint(fromEntropy: Data("front-meeting-\(n)-b".utf8))
    let encounter = Pollination.encounterID(
        seedA: parentA, seedB: parentB, nonceA: Data("a".utf8), nonceB: Data("b".utf8)
    )
    let child = Pollination.cross(seedA: parentA, seedB: parentB, encounterID: encounter)
    let digits = Array("0123456789abcdef".utf8)
    var meeting = ""
    for byte in encounter {
        meeting.unicodeScalars.append(UnicodeScalar(digits[Int(byte >> 4)]))
        meeting.unicodeScalars.append(UnicodeScalar(digits[Int(byte & 15)]))
    }
    let text = [child.hex, parentA.hex, parentB.hex, meeting].joined(separator: " ")
    setResult(Array(text.utf8))
    return Int32(text.utf8.count)
}
