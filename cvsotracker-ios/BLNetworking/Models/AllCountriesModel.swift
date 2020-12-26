// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let country = try? newJSONDecoder().decode(AllCountries.self, from: jsonData)

import Foundation

// MARK: - CountryElement
public struct CountryElement: Codable {
    public let country: String
    public let countryInfo: CountryInfo
    public let cases, todayCases, deaths, todayDeaths: Int
    public let recovered, active, critical: Int
    public let casesPerOneMillion, deathsPerOneMillion: Double
}

// MARK: - CountryInfo
public struct CountryInfo: Codable {
    public let id: Int?
    public let lat, long: Double
    public let flag: String
    public let iso3, iso2: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case lat, long, flag, iso3, iso2
    }
}

public typealias AllCountries = [CountryElement]
