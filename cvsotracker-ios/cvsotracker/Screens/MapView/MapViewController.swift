//
//  MapViewController.swift
//  nconapp
//
//  Created by Ihar Tsimafeichyk on 2/11/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Combine
import MapKit
import Services
import SwiftUI

struct MapViewController: View {
    @EnvironmentObject var viewModel: NCovViewModelImpl

    @State private var confirmedPins = [MKAnnotation]()
    @State private var deathsPins = [MKAnnotation]()
    @State private var recoveredPins = [MKAnnotation]()
    @State private var activePins = [MKAnnotation]()
    @State private var pins = [MKAnnotation]()

    var location: CLLocationCoordinate2D?
    var isModal: Bool

    var body: some View {
        ZStack {
            MapView(pins: pins, location: location)
                .onReceive(viewModel.outputLoading.publisher) { loading in
                    guard !loading else { return }
                    self.setup()
            }
            if isModal {
            VStack {
                Picker(selection: $viewModel.stateMapOption, label: Text("")) {
                    ForEach(NCovOption.allCases) {
                        Text($0.name).tag($0)
                    }
                }.pickerStyle(SegmentedPickerStyle()).onReceive(viewModel.$stateMapOption) {
                    self.setup(option: $0)
                    logInfo("\($0.name) option selected")
                }
                Spacer()
            }
            }
        }
    }

    private func setup(option: NCovOption) {
        switch option {
        case .confirmed:
            pins = confirmedPins
        case .deaths:
            pins = deathsPins
        case .recovered:
            pins = recoveredPins
        case .active:
            pins = activePins
        }
    }

    private func setup() {
        let maxValue = ContentView.totalPoints(viewModel.outputLoadConfirmed.value)

        confirmedPins = convert(viewModel.outputLoadConfirmed.value, absoluteMaxValue: maxValue, tag: .confirmed)
        deathsPins = convert(viewModel.outputLoadDeaths.value, absoluteMaxValue: maxValue, tag: .deaths)
        recoveredPins = convert(viewModel.outputLoadRecovered.value, absoluteMaxValue: maxValue, tag: .recovered)
        activePins = convert(viewModel.outputActiveCases.value, absoluteMaxValue: maxValue, tag: .active)

        setup(option: viewModel.stateMapOption)
    }

    private func convert(_ items: [NCovDataItem], absoluteMaxValue: Int, tag: NCovOption) -> [MKAnnotation] {
        let maxValue = items.reduce(0) { max($0, $1.points.last?.value ?? 0) }
        return items.compactMap { item -> MKAnnotation? in
            guard let geoPosition = item.geoPosition, let total = item.points.last?.value, total > 0 else { return nil }
            return MapPin(coordinate: geoPosition,
                          title: item.state,
                          subtitle: tag.name + ": " + String(total),
                          value: total,
                          maxValue: maxValue,
                          absoluteMaxValue: absoluteMaxValue,
                          color: tag.uiColor)
        }
    }
}
