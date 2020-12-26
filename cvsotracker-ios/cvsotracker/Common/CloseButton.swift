//
//  CloseButton.swift
//  cvsotracker
//
//  Created by Marek Stoma on 2/20/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import SwiftUI

struct CloseButton: View {
    @Binding var presentationMode: PresentationMode

    var body: some View {
        Button(action: {
            self.presentationMode.dismiss()
        }) {
            Image(systemName: "xmark").foregroundColor(.primary)
        }.padding()
    }
}
