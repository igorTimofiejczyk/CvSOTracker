//
//  RequestManager.swift
//  BLNetworking
//
//  Created by Ihar Tsimafeichyk on 3/27/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Foundation
import Alamofire

public protocol RequestManagerProtocol {
    /// Request for all total cases, recovery, and deaths
    func allCases() -> Request<AllCases>
    /// Request for all countries that has COVID-19
    func dataForAllCountries() -> Request<AllCountries>
    /// Request for all countries that has COVID-19 sortedBy specific parameter
    func dataForAllCountries(sortBy sortByValue: String) -> Request<AllCountries>
    /// Request for a specific country
    func dataForCountry(_ country: String) -> Request<CountryElement>
    /// Request for Corona data at United States of America
    func states() -> Request<States>
    /// Request for data from the John Hopkins CSSE Data Repository (Provinces and such).
    func jhucsse() -> Request<Jhucsse>
    /// Request for historical data from the start of 2020. (JHU CSSE GISand Data).
    func historical() -> Request<Historical>
}

public final class RequestManagerImpl {
    private let baseUrlString: String

    public init(baseUrlString: String = "https://corona.lmao.ninja/") {
        self.baseUrlString = baseUrlString
    }
}

extension RequestManagerImpl: RequestManagerProtocol {
    public func allCases() -> Request<AllCases> {
        return Request(baseUrlString: baseUrlString,
                       path: .all)
    }

    public func dataForAllCountries() -> Request<AllCountries> {
        return Request(baseUrlString: baseUrlString,
                       path: .countries)
    }

    public func dataForAllCountries(sortBy sortByValue: String) -> Request<AllCountries> {
        return Request(baseUrlString: baseUrlString,
                       path: .countries,
                       params: .sort(.init(sort: sortByValue)))
    }

    public func dataForCountry(_ country: String) -> Request<CountryElement> {
        return Request(baseUrlString: baseUrlString,
                       path: .country(country))
    }

    public func states() -> Request<States> {
        return Request(baseUrlString: baseUrlString,
                       path: .states)
    }

    public func jhucsse() -> Request<Jhucsse> {
        return Request(baseUrlString: baseUrlString,
                       path: .jhucsse)
    }

    public func historical() -> Request<Historical> {
        return Request(baseUrlString: baseUrlString,
                       path: .historical)
    }
}
