import Foundation

/// Reads and writes the garden as a single JSON file.
///
/// Phase one is entirely local: there is no account and no server, so this file
/// is the whole of a person's garden. It is written atomically and guarded with
/// file protection, because losing it means losing a seed that cannot be minted
/// again.
public struct GardenStore {
    public enum StoreError: Error, LocalizedError {
        case unreadable(underlying: Error)
        case unwritable(underlying: Error)
        case unsupportedSchema(found: Int)

        public var errorDescription: String? {
            switch self {
            case .unreadable(let error):
                return "The garden could not be read: \(error.localizedDescription)"
            case .unwritable(let error):
                return "The garden could not be saved: \(error.localizedDescription)"
            case .unsupportedSchema(let found):
                return "This garden was written by a newer version of the app (format \(found))."
            }
        }
    }

    public let fileURL: URL
    private let fileManager: FileManager

    public init(fileURL: URL, fileManager: FileManager = .default) {
        self.fileURL = fileURL
        self.fileManager = fileManager
    }

    /// Application Support/PeaceGarden/garden.json
    public static func defaultStore(fileManager: FileManager = .default) throws -> GardenStore {
        let base = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let directory = base.appendingPathComponent("PeaceGarden", isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        return GardenStore(fileURL: directory.appendingPathComponent("garden.json"), fileManager: fileManager)
    }

    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    public func load() throws -> Garden {
        guard fileManager.fileExists(atPath: fileURL.path) else { return Garden() }
        do {
            let data = try Data(contentsOf: fileURL)
            let garden = try Self.decoder.decode(Garden.self, from: data)
            guard garden.schemaVersion <= Garden.currentSchemaVersion else {
                throw StoreError.unsupportedSchema(found: garden.schemaVersion)
            }
            return garden
        } catch let error as StoreError {
            throw error
        } catch {
            throw StoreError.unreadable(underlying: error)
        }
    }

    public func save(_ garden: Garden) throws {
        do {
            var garden = garden
            garden.schemaVersion = Garden.currentSchemaVersion
            let data = try Self.encoder.encode(garden)
            try data.write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            throw StoreError.unwritable(underlying: error)
        }
    }
}
