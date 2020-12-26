// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let jhucsse = try? newJSONDecoder().decode(Jhucsse.self, from: jsonData)

import Foundation

// MARK: - JHUCSSEElement
public struct JHUCSSEElement: Codable {
    public let country: String
    public let province: String?
    public let updatedAt: String
    public let stats: Stats
    public let coordinates: Coordinates
}

// MARK: - Coordinates
public struct Coordinates: Codable {
    let latitude, longitude: String
}

// MARK: - Stats
public struct Stats: Codable {
    public let confirmed, deaths, recovered: Int
}

public typealias Jhucsse = [JHUCSSEElement]
