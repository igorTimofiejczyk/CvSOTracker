//
//  Request.swift
//  BLNetworking
//
//  Created by Ihar Tsimafeichyk on 3/27/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Foundation
import Alamofire

public struct Request<Response: Codable> {
    let method: HTTPMethod
    let baseUrlString: String
    let path: String
    let params: EndpointParams
    let headers: HTTPHeaders
    init(method: HTTPMethod = .get,
         baseUrlString: String,
         path: Endpoint,
         params: EndpointParams = .none,
         headers: HTTPHeaders = [:]) {
        self.method = method
        self.baseUrlString = baseUrlString
        self.path = path.rawValue
        self.params = params
        self.headers = headers
    }

    var convertable: URLConvertible {
        return baseUrlString + path
    }
}

enum EndpointParams: Encodable {
    case sort(SortParam)
    case none

    func encode(to encoder: Encoder) throws {
        switch self {
        case .sort(let value):
            try value.encode(to: encoder)
        case .none:
            break
        }
    }
}

struct SortParam: Encodable {
    let sort: String?
}

enum Endpoint {
    case all
    case countries
    case states
    case jhucsse
    case historical
    case country(String)
}

extension Endpoint: RawRepresentable {
    typealias RawValue = String
    init?(rawValue: RawValue) {
        switch rawValue {
        case "all": self = .all
        case "countries": self = .countries
        case "states": self = .states
        case "jhucsse": self = .jhucsse
        case "historical": self = .historical
        default:
            self = .country(rawValue)
        }
    }

    var rawValue: RawValue {
        switch self {
        case .all: return "all"
        case .countries: return "countries"
        case .states: return "states"
        case .jhucsse: return "v2/jhucsse"
        case .historical: return "v2/historical"
        case .country(let value): return "countries/" + value
        }
    }
}
