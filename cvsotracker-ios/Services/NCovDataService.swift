//
//  NCovDataService.swift
//  Services
//
//  Created by Marek Stoma on 2/11/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import CoreLocation
import Foundation

public typealias NCovDataService = NCovDataServiceConfiguration & NCovDataServiceInput

public protocol NCovDataServiceHolder {
    var ncovConfirmedDataService: NCovDataService { get }
    var ncovDeathsDataService: NCovDataService { get }
    var ncovRecoveredDataService: NCovDataService { get }
}

public enum NCovDataServiceError: Error {

    case unknown
    case unknownSource
    case dataNotFound
    case service(error: Error)
    case serviceCode(Int, localizedDescription: String)
}

public struct NCovDataItem {

    public struct DatePoint {
        public let date: Date
        public let value: Int

        public init(date: Date, value: Int) {
            self.date = date
            self.value = value
        }
    }

    public let country: String
    public let state: String
    public let geoPosition: CLLocationCoordinate2D?
    public private(set) var points: [DatePoint]

    public init(country: String, state: String, geoPosition: CLLocationCoordinate2D?, points: [DatePoint]) {
        self.country = country
        self.state = state
        self.geoPosition = geoPosition
        self.points = points
    }

    public mutating func removeLastPoint() {
        points.removeLast()
    }

    public mutating func removePoints(after date: Date?) {
        guard let date = date else {
            if !points.isEmpty {
                points.removeLast()
            }
            return
        }
        guard let index = points.firstIndex(where: { $0.date.compare(date) == .orderedSame }) else {
            return
        }
        points = Array(points.prefix(through: index))
    }
}

public enum NCovDataSource {

    case csv(String)
    case json(String)

    func createURL() -> URL? {
        switch self {
        case .csv(let source), .json(let source):
            return URL(string: source)
        }
    }
}

public protocol NCovDataServiceConfiguration {

    var source: NCovDataSource { get }
}

public typealias NCovDataItemResult = Result<[NCovDataItem], NCovDataServiceError>
public typealias NCovDataItemResultHandler = (NCovDataItemResult) -> Void

public protocol NCovDataServiceInput {

    func load(_ handler: @escaping NCovDataItemResultHandler)
}

public final class NCovDataServiceImpl: NCovDataServiceConfiguration {

    private struct LoadCommand {
        let task: URLSessionTask
        private(set) var handlers: [NCovDataItemResultHandler]

        mutating func add(handler: @escaping NCovDataItemResultHandler) {
            handlers.append(handler)
        }
    }

    public let source: NCovDataSource

    private var loadCommand: LoadCommand?
    private let loadDataParser: NCovDataParser
    private let session: URLSession
    private let logger: Logger

    public init(source: NCovDataSource, session: URLSession, logger: Logger) {
        self.source = source
        self.session = session
        self.logger = logger

        switch source {
        case .csv:
            self.loadDataParser = NCovCSVDataParser(logger: logger)
        case .json:
            self.loadDataParser = NCovJSONDataParser(logger: logger)
        }
    }

    deinit {
        loadCommand?.task.cancel()
    }
}

extension NCovDataServiceImpl: NCovDataServiceInput {

    public func load(_ handler: @escaping NCovDataItemResultHandler) {
        logger.debug("load")
        guard loadCommand == nil else {
            logger.debug("loading")
            loadCommand?.add(handler: handler)
            return
        }
        guard let sourceURL = source.createURL() else {
            handler(.failure(.unknownSource))
            return
        }
        loadCommand = .init(
            task: session.dataTask(with: sourceURL) { [weak self] (data, response, error) in
                self?.loadDataParser.parse(data: data, response: response, error: error) { result in
                    guard let handlers = self?.loadCommand?.handlers else {
                        return
                    }
                    self?.loadCommand = nil
                    handlers.forEach { $0(result) }
                }
            },
            handlers: [handler]
        )
        loadCommand?.task.resume()
    }
}

private protocol NCovDataParser {
    typealias Completion = (NCovDataItemResult) -> Void

    var logger: Logger { get }

    func parse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping Completion)
}

private final class NCovCSVDataParser: NCovDataParser {

    let logger: Logger

    private let dateFormatter: DateFormatter

    init(logger: Logger) {
        self.logger = logger
        self.dateFormatter = DateFormatter()
        self.dateFormatter.dateFormat = "MM/dd/yy HH:mm"
    }

    func parse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping Completion) {
        let complete: Completion = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        DispatchQueue.global(qos: .default).async { [weak self] in
            if let error = error {
                complete(.failure(.service(error: error)))
                return
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                complete(.failure(.serviceCode(httpResponse.statusCode, localizedDescription: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))))
                return
            }
            guard let data = data else {
                complete(.failure(.unknown))
                return
            }
            let items = self?.parse(data: data) ?? []
            complete(items.isEmpty ? .failure(.dataNotFound) : .success(items))
        }
    }
}

private extension NCovCSVDataParser {

    func parse(data: Data) -> [NCovDataItem] {
        guard let csvString = String(data: data, encoding: .utf8) else {
            return []
        }

        let rows = csvString.components(separatedBy: .newlines).compactMap { $0.isEmpty ? nil : $0 }
        let columns: Set = ["Province/State", "Country/Region", "Lat", "Long"]
        var mustHaveColumns = columns

        guard let header = rows.first?.components(separatedBy: ",") else {
            return []
        }

        // If header column exists in mustHaveColumns then it will be removed
        // So if mustHaveColumns will be empty after for loop it means that data contains necessary information
        for column in header {
            mustHaveColumns.remove(column)
            if mustHaveColumns.isEmpty {
                break
            }
        }
        guard mustHaveColumns.isEmpty else {
            return []
        }

        var trimCharset = CharacterSet.whitespaces
        trimCharset.insert(charactersIn: "\"")
        let headerDates = header.suffix(from: columns.count)
        var items = [NCovDataItem]()
        let dataRows = rows.suffix(from: 1)
        for row in dataRows {
            let values = parseRow(row)
            let itemData = values.prefix(columns.count)
            if itemData.count == columns.count {
                var geoPosition: CLLocationCoordinate2D?
                if let lat = Double(itemData[2]), let long = Double(itemData[3]) {
                    geoPosition = CLLocationCoordinate2D(latitude: lat, longitude: long)
                }
                let pointsData = values.suffix(from: columns.count)
                var points = [NCovDataItem.DatePoint]()
                for point in pointsData.enumerated() {
                    let offset = point.offset + columns.count
                    if headerDates.count + columns.count > offset {
                        let headerDateString = headerDates[offset]
                        let valueString = point.element
                        if let value = valueString.isEmpty ? 0.0 : Double(valueString), let date = dateFormatter.date(from: headerDateString) {
                            points.append(.init(date: date, value: Int(value)))
                        }
                    }
                }

                items.append(NCovDataItem(
                    country: itemData[1].trimmingCharacters(in: trimCharset),
                    state: itemData[0].trimmingCharacters(in: trimCharset),
                    geoPosition: geoPosition,
                    points: points.sorted(by: { (d1, d2) in
                        switch d1.date.compare(d2.date) {
                        case .orderedAscending:
                            return true
                        default:
                            return false
                        }
                    })
                    )
                )
            }
        }

        return items
    }

    // handle csv cases:
    // 1. "a,b,c,...,"
    // 2. "\"a, aa\",b,c,...,"
    func parseRow(_ row: String) -> [String] {
        var dataRow = row[row.startIndex..<row.endIndex]
        var columns = [String]()
        var prefixSum: String = ""
        while let index = dataRow.firstIndex(of: ",") {
            let prefix = dataRow[dataRow.startIndex..<index]
            dataRow = dataRow.suffix(from: dataRow.index(after: index))
            if prefix.contains("\"") {
                prefixSum += prefix + ","
                if ((prefixSum.components(separatedBy: "\"").count - 1) % 2) == 0 {
                    prefixSum.removeLast()
                    columns.append(String(prefixSum))
                    prefixSum = ""
                }
            } else if !prefixSum.isEmpty {
                prefixSum += prefix + ","
            } else {
                columns.append(String(prefix))
            }
        }
        columns.append(String(dataRow))
        return columns
    }
}

private struct NCovDataItemJSONResult: Decodable {

    let latest: Int
    let locations: [NCovDataItem]
}

extension NCovDataItem: Decodable {

    enum CodingKeys: String, CodingKey {
        case country
        case state = "province"
        case geoPosition = "coordinates"
        case history
    }

    enum CoordinatesKeys: String, CodingKey {
        case lat
        case long
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        country = try values.decode(String.self, forKey: .country)
        state = try values.decode(String.self, forKey: .state)

        let coordinates = try values.nestedContainer(keyedBy: CoordinatesKeys.self, forKey: .geoPosition)
        if let latValue = try? coordinates.decode(String.self, forKey: .lat),
            let longValue = try? coordinates.decode(String.self, forKey: .long),
            let lat = CLLocationDegrees(latValue), let long = CLLocationDegrees(longValue) {
            geoPosition = CLLocationCoordinate2D(latitude: lat, longitude: long)
        } else {
            geoPosition = nil
        }

        let history = try values.decode(Dictionary<String, Int>.self, forKey: .history)

        points = history.compactMap { item -> NCovDataItem.DatePoint? in
            guard let date = NCovJSONDataParser.dateFormatter.date(from: item.key) else {
                return nil
            }
            return .init(date: date, value: item.value)
        }.sorted(by: { (d1, d2) in
            switch d1.date.compare(d2.date) {
            case .orderedAscending:
                return true
            default:
                return false
            }
        })
    }
}

//extension NCovDataItem.DatePoint: Decodable {}

private final class NCovJSONDataParser: NCovDataParser {

    let logger: Logger

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()

    init(logger: Logger) {
        self.logger = logger
    }

    func parse(data: Data?, response: URLResponse?, error: Error?, completion: @escaping Completion) {
        let complete: Completion = { result in
            DispatchQueue.main.async {
                completion(result)
            }
        }
        DispatchQueue.global(qos: .default).async { [weak self] in
            if let error = error {
                complete(.failure(.service(error: error)))
                return
            } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                complete(.failure(.serviceCode(httpResponse.statusCode, localizedDescription: HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))))
                return
            }
            guard let data = data else {
                complete(.failure(.unknown))
                return
            }
            let items = self?.parse(data: data) ?? []
            complete(items.isEmpty ? .failure(.dataNotFound) : .success(items))
        }
    }
}

private extension NCovJSONDataParser {

    func parse(data: Data) -> [NCovDataItem] {
        do {
            let result = try JSONDecoder().decode(NCovDataItemJSONResult.self, from: data)
            return result.locations
        } catch let error {
            logger.error("\(error)")
            return []
        }
    }
}
