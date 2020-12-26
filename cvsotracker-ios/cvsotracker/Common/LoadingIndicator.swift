//
//  LoadingIndicator.swift
//  cvsotracker
//
//  Created by Marek Stoma on 2/23/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import SwiftUI

struct LoadingIndicatorView: UIViewRepresentable {

    let loading: Bool

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        return UIActivityIndicatorView(style: .medium)
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: UIViewRepresentableContext<LoadingIndicatorView>) {
        if loading {
            uiView.startAnimating()
        } else {
            uiView.stopAnimating()
        }
    }
}
