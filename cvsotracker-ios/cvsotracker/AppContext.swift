//
//  AppContext.swift
//  nconvapp
//
//  Created by Ihar Tsimafeichyk on 2/10/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import Foundation
import Services

typealias AppContextProtocol =
    NCovDataServiceHolder &
    AlertServiceHolder &
    DevLoggerServiceHolder &
    MailServiceHolder

struct AppContext: AppContextProtocol {
    var ncovDateFormatter: DateFormatter
    var ncovConfirmedDataService: NCovDataService
    var ncovDeathsDataService: NCovDataService
    var ncovRecoveredDataService: NCovDataService

    let alertService: AlertService
    let devLoggerService: DevLoggerService
    let mailService: MailService

    var applicationDelegateServices: [ApplicationDelegateService]

    static func context() -> AppContext {
        let devLoggerService = DevLoggerImplementation()

        let mailService: MailService = MailServiceImplementation(logger: Log.shared) { error in
            AppDelegate.shared.context.alertService.showErrorMessage(error)
        }

        let alertService = AlertServiceImplementation(dependencies:
            AlertServiceImplementation.Dependencies(mailService: mailService, logger: Log.shared))

        //let ncovDataServices = setupCVSNcovDataSources()
        let ncovDataServices = setupJSONNcovDataSources()

        let context = AppContext(
            ncovDateFormatter: ncovDataServices.dateFormatter,
            ncovConfirmedDataService: ncovDataServices.confirmed,
            ncovDeathsDataService: ncovDataServices.deaths,
            ncovRecoveredDataService: ncovDataServices.recovered,
            alertService: alertService,
            devLoggerService: devLoggerService,
            mailService: mailService,
            applicationDelegateServices: [
                devLoggerService
            ]
        )

        return context
    }
}

private extension AppContext {

    static func setupCVSNcovDataSources() -> (dateFormatter: DateFormatter, confirmed: NCovDataService, deaths: NCovDataService, recovered: NCovDataService) {
        let urlSession = URLSession(configuration: .default)
        //let ncovDataSource = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/time_series"
        let ncovDataSource = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/archived_data/time_series"
        let ncovConfirmedDataService = NCovDataServiceImpl(
            source: .csv(ncovDataSource + "/time_series_2019-ncov-Confirmed.csv"),
            session: urlSession,
            logger: Log.shared
        )
        let ncovDeathsDataService = NCovDataServiceImpl(
            source: .csv(ncovDataSource + "/time_series_2019-ncov-Deaths.csv"),
            session: urlSession,
            logger: Log.shared
        )
        let ncovRecoveredDataService = NCovDataServiceImpl(
            source: .csv(ncovDataSource + "/time_series_2019-ncov-Recovered.csv"),
            session: urlSession,
            logger: Log.shared
        )
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return (formatter, ncovConfirmedDataService, ncovDeathsDataService, ncovRecoveredDataService)
    }

    static func setupJSONNcovDataSources() -> (dateFormatter: DateFormatter, confirmed: NCovDataService, deaths: NCovDataService, recovered: NCovDataService) {
        let urlSession = URLSession(configuration: .default)
        let ncovDataSource = "https://coronavirus-tracker-api.herokuapp.com/"

        let ncovConfirmedDataService = NCovDataServiceImpl(
            source: .json(ncovDataSource + "confirmed"),
            session: urlSession,
            logger: Log.shared
        )
        let ncovDeathsDataService = NCovDataServiceImpl(
            source: .json(ncovDataSource + "deaths"),
            session: urlSession,
            logger: Log.shared
        )
        let ncovRecoveredDataService = NCovDataServiceImpl(
            source: .json(ncovDataSource + "recovered"),
            session: urlSession,
            logger: Log.shared
        )
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return (formatter, ncovConfirmedDataService, ncovDeathsDataService, ncovRecoveredDataService)
    }
}
