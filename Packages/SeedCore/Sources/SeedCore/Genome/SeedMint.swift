import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Mints a person's own seed, once, on first launch.
///
/// The seed is 32 bytes of SHA-256 over a blob of entropy. The part that
/// actually guarantees uniqueness is the 32 CSPRNG bytes; the contextual
/// ingredients (device, locale, the moment of minting) are there because the
/// seed should be *of* a particular phone at a particular instant, and they
/// cost nothing to fold in. Nothing here is reversible: the digest is one-way,
/// and none of these values ever leave the device — only the resulting seed
/// does, during an exchange.
public enum SeedMint {
    public struct Ingredients: Sendable {
        public var randomBytes: Data
        public var wallClock: Date
        public var uptime: TimeInterval
        public var deviceModel: String
        public var vendorIdentifier: String
        public var localeIdentifier: String
        public var timeZoneIdentifier: String
        public var hardwareDescription: String

        public init(
            randomBytes: Data,
            wallClock: Date,
            uptime: TimeInterval,
            deviceModel: String,
            vendorIdentifier: String,
            localeIdentifier: String,
            timeZoneIdentifier: String,
            hardwareDescription: String
        ) {
            self.randomBytes = randomBytes
            self.wallClock = wallClock
            self.uptime = uptime
            self.deviceModel = deviceModel
            self.vendorIdentifier = vendorIdentifier
            self.localeIdentifier = localeIdentifier
            self.timeZoneIdentifier = timeZoneIdentifier
            self.hardwareDescription = hardwareDescription
        }

        var entropyBlob: Data {
            var blob = Data()
            blob.append(randomBytes)
            blob.append(Data(String(wallClock.timeIntervalSince1970).utf8))
            blob.append(Data(String(uptime).utf8))
            blob.append(Data(deviceModel.utf8))
            blob.append(Data(vendorIdentifier.utf8))
            blob.append(Data(localeIdentifier.utf8))
            blob.append(Data(timeZoneIdentifier.utf8))
            blob.append(Data(hardwareDescription.utf8))
            return blob
        }
    }

    public static func mint(from ingredients: Ingredients) -> SeedID {
        mint(fromEntropy: ingredients.entropyBlob)
    }

    /// The one derivation step, exposed so the reference implementation in
    /// `tools/reference` can be checked against this one byte for byte.
    public static func mint(fromEntropy entropy: Data) -> SeedID {
        SeedID(digest: seedDigest(SeedDomain.seed, entropy))
    }

    /// Gathers what this device can see and mints from it.
    public static func mintOnThisDevice(now: Date = Date()) -> SeedID {
        mint(from: gatherIngredients(now: now))
    }

    public static func gatherIngredients(now: Date = Date()) -> Ingredients {
        var random = [UInt8](repeating: 0, count: 32)
        for index in random.indices {
            random[index] = UInt8.random(in: 0...255)
        }

        #if canImport(UIKit) && !os(watchOS)
        let device = UIDevice.current
        let model = "\(device.model)/\(device.systemName) \(device.systemVersion)"
        let vendor = device.identifierForVendor?.uuidString ?? UUID().uuidString
        // Not the screen: `UIScreen.main` is deprecated, and on an iPad running
        // two windows it does not describe anything in particular. The
        // randomness is what makes a seed unique regardless.
        let hardware = "\(ProcessInfo.processInfo.processorCount)x\(ProcessInfo.processInfo.physicalMemory)"
        #else
        let model = ProcessInfo.processInfo.operatingSystemVersionString
        let vendor = UUID().uuidString
        let hardware = "headless"
        #endif

        return Ingredients(
            randomBytes: Data(random),
            wallClock: now,
            uptime: ProcessInfo.processInfo.systemUptime,
            deviceModel: model,
            vendorIdentifier: vendor,
            localeIdentifier: Locale.current.identifier,
            timeZoneIdentifier: TimeZone.current.identifier,
            hardwareDescription: hardware
        )
    }
}
