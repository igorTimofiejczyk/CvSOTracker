//
//  NetworkClient.swift
//  BLNetworking
//
//  Created by Ihar Tsimafeichyk on 3/27/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Foundation
import Alamofire

public enum APIResut<T> {
    case success(T)
    case failure(Error?)

    public var value: T? {
        switch self {
        case let .success(value):
            return value
        case .failure:
            return nil
        }
    }
}

public enum NetworkError: Error, Equatable {
    case unexpectedResponseType
    case unauthorized
    case missingBody
    case otherClientError(Int)
}

public protocol NetworkClient {
    func execute<Response: Codable>(request: Request<Response>,
                                    completion: @escaping ((APIResut<Response>) -> Void))
}

/// NetworkClientImpl
///
/// Usage example:
///
///     let manager: NetworkClient = NetworkClient.shared
///     let request: RequestManager = RequestManagerImpl().historical()
///     manager.execute(request: request) { result in
///         print(result)
///     }
///
public class NetworkClientImpl: NetworkClient {
    private init() { }
    public static let shared: NetworkClient = NetworkClientImpl()

    public func execute<Response: Codable>(request: Request<Response>,
                                         completion: @escaping ((APIResut<Response>) -> Void)) {

        let successClosure: ((Response) -> Void) = { response in
            DispatchQueue.main.async {
                completion(.success(response))
            }
        }
        let failureClosure: ((Error?) -> Void) = { error in
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }

        AF.request(request.convertable,
                   method: request.method,
                   parameters: request.params)
            .validate()
            .response { response in
                switch response.result {
                case .success(let data):
                    guard let data = data else {
                        failureClosure(NetworkError.missingBody)
                        return
                    }
                    do {
                        let json = try JSONDecoder().decode(Response.self, from: data)
                        successClosure(json)
                    } catch let error {
                        failureClosure(error)
                    }
                case .failure(let error):
                    failureClosure(error)
                }
        }
    }
}
