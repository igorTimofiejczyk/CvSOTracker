// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let historical = try? newJSONDecoder().decode(Historical.self, from: jsonData)

import Foundation

// MARK: - HistoricalElement
public struct HistoricalElement: Codable {
    public let country: String
    public let province: String?
    public let timeline: Timeline
}

// MARK: - Timeline
public struct Timeline: Codable {
    public let cases, deaths: [String: Int]
}

public typealias Historical = [HistoricalElement]
