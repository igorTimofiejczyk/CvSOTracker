//
//  MapViewWrapper.swift
//  cvsotracker
//
//  Created by Ihar Tsimafeichyk on 2/13/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import CoreLocation
import Services
import SwiftUI

struct MapViewModalWraper: View {
    @Environment(\.presentationMode) var presentationMode

    @Binding var loadingView: Bool

    var body: some View {
        NavigationView {
            VStack {
                MapViewController(isModal: true)
            }
            .navigationBarItems(
                leading: LoadingIndicatorView(loading: loadingView),
                trailing: CloseButton(presentationMode: presentationMode)
            )
            .navigationViewStyle(StackNavigationViewStyle())
            .navigationBarTitle("COVID-19", displayMode: .inline)
        }.edgesIgnoringSafeArea(.bottom)
    }
}

struct MapViewListWraper: View {
    var location: CLLocationCoordinate2D?

    var body: some View {
            VStack {
                MapViewController(location: location, isModal: false)
            }.navigationViewStyle(StackNavigationViewStyle())
            .navigationBarTitle("COVID-19", displayMode: .inline)
    }
}
