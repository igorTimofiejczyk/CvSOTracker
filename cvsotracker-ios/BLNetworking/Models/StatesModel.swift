// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let states = try? newJSONDecoder().decode(States.self, from: jsonData)

import Foundation

// MARK: - State
public struct State: Codable {
    public let state: String
    public let cases, todayCases, deaths, todayDeaths: Int
    public let active: Int
}

public typealias States = [State]
