import Foundation

// Represents a single averaged reading fetched from the API (matches Go models.Reading)
// Conforms to Decodable to be created from JSON
// Conforms to Identifiable for use in SwiftUI Lists
struct Reading: Codable, Identifiable {
    let id: Int64 // Using Int64 to match Go's potential size
    let timestamp: Date
    let systolic: Int
    let diastolic: Int
    let pulse: Int
    let classification: String
}

// Represents the input required for submitting new readings (matches Go models.ReadingInput)
// Conforms to Encodable to be converted to JSON for the POST request
struct ReadingInput: Codable {
    let systolic1: Int
    let diastolic1: Int
    let pulse1: Int

    let systolic2: Int
    let diastolic2: Int
    let pulse2: Int

    let systolic3: Int
    let diastolic3: Int
    let pulse3: Int

}

// Represents the statistical data returned by the API (matches Go models.Stats)
struct Stats: Codable {
    // Using optional Reading? because the backend might return null if no readings exist for a period
    let lastReading: Reading?
    let sevenDayAvg: Reading?
    let sevenDayCount: Int
    let thirtyDayAvg: Reading?
    let thirtyDayCount: Int
    let allTimeAvg: Reading?
    let allTimeCount: Int

    // Provide default values or handle potential nil averages in the View/ViewModel
    // Example for providing default:
    static let empty = Stats(lastReading: nil,
                           sevenDayAvg: nil, sevenDayCount: 0,
                           thirtyDayAvg: nil, thirtyDayCount: 0,
                           allTimeAvg: nil, allTimeCount: 0)
}

// Helper for handling the date format from the API
// We need to tell the JSONDecoder to use this strategy
extension JSONDecoder.DateDecodingStrategy {
    static let iso8601withFractionalSeconds = custom {
        let container = try $0.singleValueContainer()
        let string = try container.decode(String.self)

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        if let date = formatter.date(from: string) {
            return date
        }
        // Fallback to standard ISO8601 if fractional seconds parsing fails
        formatter.formatOptions = [.withInternetDateTime]
        if let date = formatter.date(from: string) {
            return date
        }

        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(string)")
    }
}
