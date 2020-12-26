//
//  MapView.swift
//  nconapp
//
//  Created by Ihar Tsimafeichyk on 2/10/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import MapKit
import SwiftUI

//https://www.raywenderlich.com/548-mapkit-tutorial-getting-started

struct MapView: UIViewRepresentable {
    let pins: [MKAnnotation]
    let location: CLLocationCoordinate2D?

    func makeUIView(context: Context) -> MKMapView {
        return MKMapView(frame: .zero)
    }

    let locationManager = CLLocationManager()
    func checkLocationAuthorizationStatus(_ mapView: MKMapView) {
      if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
        mapView.showsUserLocation = true
      } else {
        locationManager.requestWhenInUseAuthorization()
      }
    }

    func updateUIView(_ view: MKMapView, context: Context) {
//        checkLocationAuthorizationStatus(view)
        let regionRadius: CLLocationDistance = 200000
        if let location = location {
            let region = MKCoordinateRegion(center: location,
                                                        latitudinalMeters: regionRadius,
                                                       longitudinalMeters: regionRadius)
            view.setRegion(region, animated: true)
        }
        view.removeAnnotations(view.annotations)
        view.addAnnotations(pins)
//        view.showAnnotations(pins, animated: true)
//        view.showsScale = true
        view.showsCompass = false
//        view.register(MapPinView.self,
//        forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        view.register(MapCircleView.self,
        forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
    }
}

class MapPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var value: Int
    var maxValue: Int
    var absoluteMaxValue: Int
    var color: UIColor

    init(coordinate: CLLocationCoordinate2D, title: String, subtitle: String, value: Int, maxValue: Int, absoluteMaxValue: Int, color: UIColor = .red) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.maxValue = maxValue
        self.absoluteMaxValue = absoluteMaxValue
        self.color = color
    }
}

class MapPinView: MKMarkerAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let pinView = newValue as? MapPin else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: -5, y: 5)

            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            detailLabel.font = detailLabel.font.withSize(12)
            detailLabel.text = pinView.subtitle
            animatesWhenAdded = true

            markerTintColor = pinView.color
            detailCalloutAccessoryView = detailLabel
        }
    }
}

class MapCircleView: MKAnnotationView {
    override var annotation: MKAnnotation? {
        willSet {
            guard let pinView = newValue as? MapPin else { return }
            canShowCallout = true
            calloutOffset = CGPoint(x: 0, y: 5)

            let detailLabel = UILabel()
            detailLabel.numberOfLines = 0
            detailLabel.font = detailLabel.font.withSize(12)
            detailLabel.text = pinView.subtitle

            detailCalloutAccessoryView = detailLabel

            var size = 10.0
            if pinView.absoluteMaxValue > 0 {
                // base is 0.35% from absoluteMaxValue
                let log10Base = Double(pinView.absoluteMaxValue) * 0.0035
                let multiplier = log10((log10Base * (Double(pinView.value) / Double(pinView.absoluteMaxValue))))
                let maxSize = 40.0 * multiplier
                size = max(size, maxSize)
            }

            frame = .init(origin: frame.origin, size: .init(width: size, height: size))
            layer.cornerRadius = CGFloat(size / 2.0)
            backgroundColor = pinView.color.withAlphaComponent(0.5)
        }
    }
}

struct MapView_Preview: PreviewProvider {
    static var previews: some View {
        MapView(pins: [], location: nil)
    }
}
