//
//  ContentView.swift
//  nconvapp
//
//  Created by Ihar Tsimafeichyk on 2/10/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Combine
import Services
import SwiftUI

extension NCovOption {
    var name: String {
        return "\(self)".map {
            $0.isUppercase ? " \($0)" : "\($0)" }.joined().capitalized
    }
    var color: Color {
        switch self {
        case .confirmed:
            return .red
        case .deaths:
            return .gray
        case .recovered:
            return .green
        case .active:
            return .purple
        }
    }
    var uiColor: UIColor {
        switch self {
        case .confirmed:
            return .red
        case .deaths:
            return .gray
        case .recovered:
            return .green
        case .active:
            return .purple
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var viewModel: NCovViewModelImpl

    @State var mapView = false
    @State var appInfoView = false
    @State var timelineConfirmedView = false
    @State var timelineDeathsView = false
    @State var timelineRecoveredView = false
    @State var loadingView = false
    @State var activeView = false

    @State var confirmedTopic = "-"
    @State var deathsTopic = "-"
    @State var deathsRateTopic = ""
    @State var recoveredTopic = "-"
    @State var recoveredRateTopic = ""
    @State var lastUpdate = "-"

    @State var searchContent = [SearchContent]()
    @State var lastStatistic = true

    @ObservedObject var keyboardHandler = KeyboardObserver()

    @State private var rateAnimator: AnyCancellable?

    private var dateFormatter: DateFormatter = {
        return AppDelegate.shared.context.ncovDateFormatter
    }()
    private var updateDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = AppDelegate.shared.context.ncovDateFormatter.dateStyle
        formatter.timeStyle = .short
        return formatter
    }()
    private var rateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        return formatter
    }()
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Group {
                    Spacer()
                    Text("Total Confirmed:").font(.body).foregroundColor(.gray)
                    totalView(text: confirmedTopic,
                              items: viewModel.outputLoadConfirmed.value,
                              view: $timelineConfirmedView,
                              timeSlice: $viewModel.stateTimeSliceConfirmed,
                              option: .confirmed)
                        .background((viewModel.stateOption == .confirmed ? Color(.secondarySystemBackground) : Color.clear).animation(.none))
                        .cornerRadius(8.0)
                        .padding(EdgeInsets(top: 2.0, leading: 0.0, bottom: 8.0, trailing: 0.0))
                        .onTapGesture(count: 2) {
                            self.showRate()
                    }.onTapGesture(count: 1) {
                        self.viewModel.stateOption = .confirmed
                    }

                    HStack(alignment: .top) {
                        VStack(spacing: 0) {
                            Text("Total Deaths:").font(.body).foregroundColor(.gray)
                            totalView(text: deathsTopic,
                                      items: viewModel.outputLoadDeaths.value,
                                      view: $timelineDeathsView,
                                      timeSlice: $viewModel.stateTimeSliceDeaths,
                                      option: .deaths)
                                .background((viewModel.stateOption == .deaths ? Color(.secondarySystemBackground) : Color.clear).animation(.none))
                                .cornerRadius(8.0)
                                .padding(EdgeInsets(top: 2.0, leading: 0.0, bottom: 8.0, trailing: 0.0))
                                .onTapGesture(count: 2) {
                                    self.showRate()
                            }.onTapGesture(count: 1) {
                                self.viewModel.stateOption = .deaths
                            }
                        }
                        VStack(spacing: 0) {
                            Text("Total Recovered:").font(.body).foregroundColor(.gray)
                            totalView(text: recoveredTopic,
                                      items: viewModel.outputLoadRecovered.value,
                                      view: $timelineRecoveredView,
                                      timeSlice: $viewModel.stateTimeSliceRecovered,
                                      option: .recovered)
                                .background((viewModel.stateOption == .recovered ? Color(.secondarySystemBackground) : Color.clear).animation(.none))
                                .cornerRadius(8.0)
                                .padding(EdgeInsets(top: 2.0, leading: 0.0, bottom: 8.0, trailing: 0.0))
                                .onTapGesture(count: 2) {
                                    self.showRate()
                            }.onTapGesture(count: 1) {
                                self.viewModel.stateOption = .recovered
                            }
                        }
                    }
                }.animation(.easeInOut(duration: 0.2))
                Group {
                    Divider()
                    SearchView(color: viewModel.stateOption.color, searchContent: $searchContent, searchFiltered: $viewModel.stateFiltered)
                        .padding([.top], 8.0)
                }.animation(.easeInOut(duration: 0.2))
                Divider()
                HStack {
                    Button(action: {
                        self.mapView = true
                        logInfo("Show map view")
                    }) {
                        Image(systemName: "map")
                        Text("Go to Map").font(.caption)
                    }.sheet(isPresented: $mapView, onDismiss: {
                        self.mapView = false
                    }, content: {
                        MapViewModalWraper(loadingView: self.$loadingView).environmentObject(self.viewModel)
                    }).padding()
                    Button(action: {
                        self.appInfoView = true
                        logInfo("Show App info")
                    }) {
                        Image(systemName: "info.circle")
                        Text("App Info").font(.caption)
                    }.sheet(isPresented: $appInfoView, onDismiss: {
                        self.appInfoView = false
                    }, content: { InformationView() }).padding()
                }.accentColor(.primary)

            }
            .navigationBarTitle("", displayMode: .inline)
            .navigationBarItems(leading: HStack {
                VStack {
                    HStack {
                        Text("Database updated at:").font(.caption)
                        Spacer()
                    }
                    Text(lastUpdate).font(.body)
                }
                LoadingIndicatorView(loading: loadingView).padding()
                }.onTapGesture(count: 2) {
                    //self.viewModel.load()
                }, trailing: HStack {
                    Button(action: {
                        if self.keyboardHandler.isVisible {
                            UIApplication.shared.endEditing(true)
                        } else {
                            self.lastStatistic.toggle()
                        }
                    }) {
                        Image(systemName: "arrowtriangle.up.fill").foregroundColor(.primary)
                    }.padding()
            })
            // Reload button is hidden for now.
//                }, trailing: Button(action: {
//                    self.load()
//                    logInfo("Reload data")
//                }) {
//                    Image("arrow.counterclockwise.circle")
//                        .resizable()
//                        .frame(width: 20, height: 20, alignment: .center)
//                }.accentColor(.primary))
        }.onReceive(viewModel.$stateOption) {
            self.setupSearchContentForOption($0)
        }.onReceive(viewModel.$stateFiltered) { _ in
            self.setupSearchContentForOption(self.viewModel.stateOption)
        }.onReceive(viewModel.$stateTimeSliceConfirmed) { timeSlice in
            guard self.viewModel.stateOption == .confirmed else { return }
            self.setupSearchContent(self.viewModel.outputLoadConfirmed.value, timeSlice: timeSlice)
        }.onReceive(viewModel.$stateTimeSliceDeaths) { timeSlice in
            guard self.viewModel.stateOption == .deaths else { return }
            self.setupSearchContent(self.viewModel.outputLoadDeaths.value, timeSlice: timeSlice)
        }.onReceive(viewModel.$stateTimeSliceRecovered) { timeSlice in
            guard self.viewModel.stateOption == .recovered else { return }
            self.setupSearchContent(self.viewModel.outputLoadRecovered.value, timeSlice: timeSlice)
        }.onReceive(viewModel.outputLoading.publisher) { loading in
            self.loadingView = loading
            guard !loading else { return }
            self.lastUpdate = self.updateDateFormatter.string(from: self.viewModel.outputActiveCases.value.last?.points.last?.date ?? Date())
            let rate = self.rate()
            self.deathsRateTopic = rate.deaths
            self.recoveredRateTopic = rate.recovered
            self.showRate(force: true)
        }.onReceive(viewModel.outputLoadConfirmed.publisher.replaceError(with: [])) { items in
            self.confirmedTopic = self.total(items)
            guard self.viewModel.stateOption == .confirmed else { return }
            self.setupSearchContent(items, timeSlice: self.viewModel.stateTimeSliceConfirmed)
        }.onReceive(viewModel.outputLoadDeaths.publisher.replaceError(with: [])) { items in
            self.deathsTopic = self.total(items)
            guard self.viewModel.stateOption == .deaths else { return }
            self.setupSearchContent(items, timeSlice: self.viewModel.stateTimeSliceDeaths)
        }.onReceive(viewModel.outputLoadRecovered.publisher.replaceError(with: [])) { items in
            self.recoveredTopic = self.total(items)
            guard self.viewModel.stateOption == .recovered else { return }
            self.setupSearchContent(items, timeSlice: self.viewModel.stateTimeSliceRecovered)
        }
    }
}

extension ContentView {
    public static func totalPoints(_ items: [NCovDataItem]) -> Int {
        return items.reduce(0) { (sum, item) -> Int in
            let value = (item.points.last?.value ?? 0)
            return sum + value
        }
    }
}

private extension ContentView {

    private func showRate(force: Bool = false) {
        guard !deathsRateTopic.isEmpty, !recoveredRateTopic.isEmpty, (rateAnimator == nil || force) else { return }
        rateAnimator?.cancel()
        rateAnimator = Publishers.Merge(
            Just((deathsRateTopic, recoveredRateTopic)).delay(for: force ? 1.0 : 0.2, scheduler: RunLoop.main),
            Just((deathsTopic, recoveredTopic)).delay(for: 3.0, scheduler: RunLoop.main)
        ).sink(receiveCompletion: { _ in
            self.rateAnimator = nil
        }, receiveValue: { value in
            self.deathsTopic = value.0
            self.recoveredTopic = value.1
        })
    }

    private func rate() -> (deaths: String, recovered: String) {
        let total = ContentView.totalPoints(viewModel.outputLoadConfirmed.value)
        let totalDeaths = ContentView.totalPoints(viewModel.outputLoadDeaths.value)
        let totalRecovered = ContentView.totalPoints(viewModel.outputLoadRecovered.value)
        let emptyRate = ("", "")
        guard total > 0, total >= (totalDeaths + totalRecovered) else {
            return emptyRate
        }
        let deathsRateValue = Float(totalDeaths) / Float(total)
        let recoveredRateValue = Float(totalRecovered) / Float(total)
        guard let deathsRate = rateFormatter.string(from: NSNumber(value: deathsRateValue)),
            let recoveredRate = rateFormatter.string(from: NSNumber(value: recoveredRateValue)) else {
            return emptyRate
        }
        return (deathsRate, recoveredRate)
    }

    private func setupSearchContentForOption(_ option: NCovOption) {
        switch option {
        case .confirmed:
            self.setupSearchContent(self.viewModel.outputLoadConfirmed.value, timeSlice: self.viewModel.stateTimeSliceConfirmed)
        case .deaths:
            self.setupSearchContent(self.viewModel.outputLoadDeaths.value, timeSlice: self.viewModel.stateTimeSliceDeaths)
        case .recovered:
            self.setupSearchContent(self.viewModel.outputLoadRecovered.value, timeSlice: self.viewModel.stateTimeSliceRecovered)
        default:
            break
        }
    }

    private func setupSearchContent(_ items: [NCovDataItem], timeSlice: Date?) {
        searchContent = items.map { convert($0, timeSlice: timeSlice) }
            .filter { !($0.state.isEmpty && $0.country.isEmpty) && $0.value > 0 && (!viewModel.stateFiltered || $0.diff != 0) }
            .sorted(by: { $0.value > $1.value })
    }

    private func timelineView(_ items: [NCovDataItem], timeSlice: Binding<Date?>, option: NCovOption) -> TimelineView {
        let rawData = items.reduce(into: [Date: Int]()) { (result, item) in
            item.points.forEach { result[$0.date] = (result[$0.date] ?? 0) + $0.value }
        }
        let timeline = rawData.map { NCovDataItem.DatePoint(date: $0.key, value: $0.value) }.sorted(by: { (d1, d2) in
            switch d1.date.compare(d2.date) {
            case .orderedDescending:
                return true
            default:
                return false
            }
        })
        let maxValue = timeline.reduce(0) { max($0, $1.value) }
        return TimelineView(dateFormatter: dateFormatter, timelineContent: timeline, maxValue: maxValue, option: option, timeSlice: timeSlice)
    }
    func total(_ items: [NCovDataItem]) -> String {
        return String(ContentView.totalPoints(items))
    }
    private func lastTotalPoints(_ items: [NCovDataItem], timeSlice: Date?) -> (diff: Int, lastDate: Date?, lastPreviousDate: Date?)? {
        guard !items.isEmpty else { return nil }
        let lastDate = items.first?.points.last?.date
        let total = ContentView.totalPoints(items)
        let previousItems = items.map { item -> NCovDataItem in
            var newItem = item
            newItem.removePoints(after: timeSlice)
            return newItem
        }
        let lastPreviousDate = previousItems.first?.points.last?.date
        let previousTotal = ContentView.totalPoints(previousItems)
        let diff = total - previousTotal
        return (diff: diff, lastDate: lastDate, lastPreviousDate: lastPreviousDate)
    }
    private func convert(_ item: NCovDataItem, timeSlice: Date?) -> SearchContent {
        let diff = lastTotalPoints([item], timeSlice: timeSlice)?.diff
        let item = SearchContent(state: item.state,
                                 country: item.country,
                                 diff: diff ?? 0,
                                 value: item.points.last?.value ?? 0,
                                 lat: item.geoPosition?.latitude,
                                 long: item.geoPosition?.longitude)
        return item
    }
    private func totalView(text: String, items: [NCovDataItem], view: Binding<Bool>, timeSlice: Binding<Date?>, option: NCovOption) -> AnyView {
        return AnyView(
            VStack {
                Text(text)
                    .font(.largeTitle)
                    .foregroundColor(option.color)
                    .fontWeight(.bold)
                    .padding(0)
                    .animation(.none)
                if !self.keyboardHandler.isVisible {
                    if self.lastStatistic {
                        lastTotalView(items, view: view, timeSlice: timeSlice, option: option)
                            .padding(0)
                            .transition(.scale)
                    }
                }
            }.padding(EdgeInsets(top: 0.0, leading: 8.0, bottom: 4.0, trailing: 8.0))
        )
    }
    private func lastTotalView(_ items: [NCovDataItem], view: Binding<Bool>, timeSlice: Binding<Date?>, option: NCovOption) -> AnyView {
        guard let data = lastTotalPoints(items, timeSlice: timeSlice.wrappedValue) else { return AnyView(EmptyView()) }
        return AnyView(
            VStack {
                dateView(data.lastDate, color: .gray, font: .footnote, fontWeight: .thin)
                diffView(data.diff, color: option.color, fontWeight: .light).onTapGesture {
                    view.wrappedValue = true
                }.sheet(isPresented: view, onDismiss: {
                    view.wrappedValue = false
                }, content: {
                    self.timelineView(items, timeSlice: timeSlice, option: option)
                })
                dateView(data.lastPreviousDate, color: .gray, font: .footnote, fontWeight: .thin)
            }.font(.callout)
        )
    }
    private func dateView(_ date: Date?, color: Color?, font: Font? = nil, fontWeight: Font.Weight? = nil) -> AnyView {
        guard let date = date else { return AnyView(EmptyView()) }
        return AnyView(
            Text(self.dateFormatter.string(from: date))
                .foregroundColor(color)
                .font(font)
                .fontWeight(fontWeight)
        )
    }
    private func diffView(_ diff: Int, color: Color, fontWeight: Font.Weight? = nil) -> AnyView {
        let imageTitle = diff >= 0 ? "arrowtriangle.up.fill" : "arrowtriangle.down.fill"
        return AnyView(
            HStack {
                Image(systemName: imageTitle).foregroundColor(color)
                Text("\(abs(diff))").fontWeight(fontWeight)
            }
        )
    }
}
