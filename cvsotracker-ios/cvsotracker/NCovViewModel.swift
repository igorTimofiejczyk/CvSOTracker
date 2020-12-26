//
//  NCovViewModel.swift
//  cvsotracker
//
//  Created by Marek Stoma on 2/17/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Combine
import Services

typealias NCovViewModel = NCovViewModelInput & NCovViewModelOutput & NCovViewModelState

enum NCovOption: CaseIterable, Hashable, Identifiable {
    var id: NCovOption { self }

    case confirmed
    case deaths
    case recovered
    case active
}

struct NCovValueEmitter<T, E: Error> {
    fileprivate let signal: CurrentValueSubject<T, E>

    var value: T { return signal.value }
    let publisher: AnyPublisher<T, E>

    init(_ value: T) {
        signal = CurrentValueSubject<T, E>(value)
        publisher = signal.eraseToAnyPublisher()
    }
}

protocol NCovViewModelInput {

    func load()
    func loadConfirmed() -> Future<[NCovDataItem], NCovDataServiceError>
    func loadDeaths() -> Future<[NCovDataItem], NCovDataServiceError>
    func loadRecovered() -> Future<[NCovDataItem], NCovDataServiceError>
}

// Properties to be used with @Published in implementation
protocol NCovViewModelState {
    var stateOption: NCovOption { get set }
    var stateMapOption: NCovOption { get set }

    var stateFiltered: Bool { get set }

    var stateTimeSliceConfirmed: Date? { get set }
    var stateTimeSliceDeaths: Date? { get set }
    var stateTimeSliceRecovered: Date? { get set }
}

protocol NCovViewModelOutput: ObservableObject {
    var outputLoading: NCovValueEmitter<Bool, Never> { get }

    var outputLoadConfirmed: NCovValueEmitter<[NCovDataItem], NCovDataServiceError> { get }
    var outputLoadDeaths: NCovValueEmitter<[NCovDataItem], NCovDataServiceError> { get }
    var outputLoadRecovered: NCovValueEmitter<[NCovDataItem], NCovDataServiceError> { get }
    var outputActiveCases: NCovValueEmitter<[NCovDataItem], Never> { get }
}

final class NCovViewModelImpl: NCovViewModelOutput, NCovViewModelState {
    @Published var stateOption: NCovOption
    @Published var stateMapOption: NCovOption

    @Published var stateFiltered: Bool
    @Published var stateTimeSliceConfirmed: Date?
    @Published var stateTimeSliceDeaths: Date?
    @Published var stateTimeSliceRecovered: Date?

    private(set) var outputLoading = NCovValueEmitter<Bool, Never>(false)
    private(set) var outputLoadConfirmed = NCovValueEmitter<[NCovDataItem], NCovDataServiceError>([])
    private(set) var outputLoadDeaths = NCovValueEmitter<[NCovDataItem], NCovDataServiceError>([])
    private(set) var outputLoadRecovered = NCovValueEmitter<[NCovDataItem], NCovDataServiceError>([])
    private(set) var outputActiveCases = NCovValueEmitter<[NCovDataItem], Never>([])

    private let modelConfirmed: NCovDataService
    private let modelDeaths: NCovDataService
    private let modelRecovered: NCovDataService

    private var loading: AnyCancellable?

    init(option: NCovOption,
         filtered: Bool,
         model: NCovDataServiceHolder) {
        self.stateOption = option
        self.stateMapOption = option
        self.stateFiltered = filtered
        self.modelConfirmed = model.ncovConfirmedDataService
        self.modelDeaths = model.ncovDeathsDataService
        self.modelRecovered = model.ncovRecoveredDataService
    }
}

extension NCovViewModelImpl: NCovViewModelInput {

    func load() {
        guard !outputLoading.value else { return }

        outputLoading.signal.send(true)

        loading = Publishers.CombineLatest3(
            loadConfirmed().replaceError(with: []),
            loadDeaths().replaceError(with: []),
            loadRecovered().replaceError(with: [])
        ).sink(receiveCompletion: { [weak self] _ in
            if let active = self?.calculateActiveCases() {
                self?.outputActiveCases.signal.send(active)
            }
            self?.outputLoading.signal.send(false)
        }, receiveValue: { _ in })
    }

    func loadConfirmed() -> Future<[NCovDataItem], NCovDataServiceError> {
        return Future { [weak self] promise in
            self?.modelConfirmed.load { result in
                switch result {
                case .success(let items):
                    self?.outputLoadConfirmed.signal.send(items)
                    if self?.stateTimeSliceConfirmed == nil {
                        self?.stateTimeSliceConfirmed = items.first?.points.suffix(2).first?.date
                    }
                    promise(.success(items))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }

    func loadDeaths() -> Future<[NCovDataItem], NCovDataServiceError> {
        return Future { [weak self] promise in
            self?.modelDeaths.load { result in
                switch result {
                case .success(let items):
                    self?.outputLoadDeaths.signal.send(items)
                    if self?.stateTimeSliceDeaths == nil {
                        self?.stateTimeSliceDeaths = items.first?.points.suffix(2).first?.date
                    }
                    promise(.success(items))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }

    func loadRecovered() -> Future<[NCovDataItem], NCovDataServiceError> {
        return Future { [weak self] promise in
            self?.modelRecovered.load { result in
                switch result {
                case .success(let items):
                    self?.outputLoadRecovered.signal.send(items)
                    if self?.stateTimeSliceRecovered == nil {
                        self?.stateTimeSliceRecovered = items.first?.points.suffix(2).first?.date
                    }
                    promise(.success(items))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }
    }
}

private extension NCovViewModelImpl {

    func calculateActiveCases() -> [NCovDataItem] {
        let confirmed = outputLoadConfirmed.value
        let deaths = outputLoadDeaths.value
        let recovered = outputLoadRecovered.value


        let mapDeaths = deaths.reduce(into: [String: Int]()) { (result, item) in
            result["\(item.country)-\(item.state)"] = item.points.last?.value ?? 0
        }
        let mapRecovered = recovered.reduce(into: [String: Int]()) { (result, item) in
            result["\(item.country)-\(item.state)"] = item.points.last?.value ?? 0
        }

        var active = [NCovDataItem]()

        for item in confirmed {
            let key = "\(item.country)-\(item.state)"
            if let deathValue = mapDeaths[key], let recoveredValue = mapRecovered[key] {
                let lastValue = (item.points.last?.value ?? 0) - (deathValue + recoveredValue)
                active.append(.init(country: item.country,
                                    state: item.state,
                                    geoPosition: item.geoPosition,
                                    points: [.init(date: item.points.last?.date ?? Date(),
                                                   value: lastValue)]))
            }
        }

        return active
    }
}
