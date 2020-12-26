//
//  SearchBar.swift
//  cvsotracker
//
//  Created by Ihar Tsimafeichyk on 2/12/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import CoreLocation
import Services
import SwiftUI

struct SearchBar: View {
    @Binding var text: String

    var body: some View {
        HStack {
            HStack {
                Image(systemName: "magnifyingglass")

                TextField("Search", text: $text)
                    .foregroundColor(.primary)

                if !text.isEmpty {
                    Button(action: {
                        self.text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                    }
                } else {
                    EmptyView()
                }
            }
            .padding(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .foregroundColor(.secondary)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(10.0)
        }
        .padding(.horizontal)
    }
}

struct SearchContent: Hashable, Identifiable {
    var id: String { return state + country + String(lat ?? 0) + String(long ?? 0) }

    let state: String
    let country: String
    let diff: Int
    let value: Int

    let lat: CLLocationDegrees?
    let long: CLLocationDegrees?

    func coordinate() -> CLLocationCoordinate2D? {
        guard let lat = self.lat, let long = self.long else {
            return nil
        }
        return .init(latitude: lat, longitude: long)
    }
}

struct SearchContentRow: View {
    var content: SearchContent

    var color: Color

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(content.state.isEmpty ? "--" : content.state)
                Text(content.country.isEmpty ? "--" : content.country).font(.caption)
            }
            diffView(content.diff, color: color, fontWeight: .light).font(.callout)
            Spacer()
            Text(String(content.value)).foregroundColor(color)
        }
    }

    private func diffView(_ diff: Int, color: Color, fontWeight: Font.Weight? = nil) -> AnyView {
        guard diff != 0 else { return AnyView(EmptyView()) }
        let imageTitle = diff > 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill"
        return AnyView(
            HStack {
                Image(systemName: imageTitle).foregroundColor(color)
                Text("\(abs(diff))").fontWeight(fontWeight)
            }
        )
    }
}

struct SearchView: View {
    let color: Color

    @Binding var searchContent: [SearchContent]
    @Binding var searchFiltered: Bool
    @State private var searchText = ""

    var body: some View {
            VStack {
                HStack {
                    SearchBar(text: $searchText)
                    Button(action: {
                        self.searchFiltered.toggle()
                    }) {
                        Image(systemName: self.searchFiltered ? "line.horizontal.3.decrease.circle.fill" : "line.horizontal.3.decrease.circle")
                            .foregroundColor(.primary)
                    }.padding(EdgeInsets(top: 2.0, leading: 2.0, bottom: 2.0, trailing: 24.0))
                }
                List {
                    ForEach(searchContent.filter {
                        $0.state.lowercased().contains(searchText.lowercased()) ||
                            $0.country.lowercased().contains(searchText.lowercased()) || searchText == "" }, id: \.self) { content in
                        NavigationLink(destination: MapViewListWraper(location: content.coordinate())) {
                            SearchContentRow(content: content, color: self.color)
                        }
                    }
                }
            }.gesture(DragGesture().onChanged { _ in
                UIApplication.shared.endEditing(true)
            })
    }
}

extension UIApplication {
    func endEditing(_ force: Bool) {
        self.windows
            .filter { $0.isKeyWindow }
            .first?
            .endEditing(force)
    }
}
