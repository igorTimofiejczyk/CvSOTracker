//
//  TimelineView.swift
//  cvsotracker
//
//  Created by Marek Stoma on 2/15/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Services
import SwiftUI

struct TimelineView: View {
    @Environment(\.presentationMode) var presentationMode

    let dateFormatter: DateFormatter

    let timelineContent: [NCovDataItem.DatePoint]
    let maxValue: Int

    let option: NCovOption

    @Binding var timeSlice: Date?

    var diffDateFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.month, .day, .hour]
        formatter.unitsStyle = .short
        formatter.maximumUnitCount = 1
        return formatter
    }()

    var body: some View {
        NavigationView {
            List {
                ForEach(timelineContent, id: \.date) { data in
                    TimelineViewRow(title: self.dateFormatter.string(from: data.date),
                                    value: data.value,
                                    maxValue: self.maxValue,
                                    option: self.option,
                                    selected: self.timeSlice?.compare(data.date) == .orderedSame)
                        .onTapGesture {
                            if self.timelineContent.first?.date != data.date {
                                self.timeSlice = data.date
                            }
                    }
                }
            }.navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: VStack {
                HStack {
                    Text("Total timeline")
                    Spacer()
                }
                Text(self.title()).font(.caption).fontWeight(.light)
            }, trailing: CloseButton(presentationMode: presentationMode))
        }
    }

    func title() -> String {
        guard let firstDate = timelineContent.first?.date, let lastDate = timeSlice else {
            return ""
        }
        return "Time slice for last \(diffDateFormatter.string(from: lastDate, to: firstDate) ?? "--") started from \(self.dateFormatter.string(from: firstDate))"
    }
}

struct TimelineViewRow: View {
    let title: String
    let value: Int
    let maxValue: Int
    let option: NCovOption
    let selected: Bool

    @State var scale = CGFloat(0.0)

    var body: some View {
        HStack {
            Image(systemName: "arrowtriangle.up.fill").foregroundColor(selected ? option.color : .clear)
            HStack {
                Text(title).fontWeight(.light)
                Spacer()
                Text(self.value > 0 ? "\(self.value)" : "").fontWeight(.thin)
            }.background(
                GeometryReader { metrics in
                    if self.value > 0 {
                        if self.maxValue > 0 {
                            self.option.color
                                .opacity(0.5)
                                .frame(width: self.scale).onAppear {
                                    return withAnimation(.spring(response: 1.1, dampingFraction: 0.75, blendDuration: 0.0)) {
                                        self.scale = metrics.size.width * (CGFloat(self.value) / CGFloat(self.maxValue))
                                    }
                            }
                        }
                    }
                }
            )
        }
    }
}

struct TimelineViewRow_Preview: PreviewProvider {
    static var previews: some View {
        TimelineViewRow(title: "Test", value: 3, maxValue: 10, option: .confirmed, selected: false)
    }
}
