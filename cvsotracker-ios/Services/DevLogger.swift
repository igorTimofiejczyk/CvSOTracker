//
//  DevLogger.swift
//  Services
//
//  Created by Ihar Tsimafeichyk on 2/10/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import CocoaLumberjack
import Foundation
import UIKit

public protocol DevLoggerServiceHolder {
    var devLoggerService: DevLoggerService { get }
}

public protocol DevLoggerService {
    static func formatMessage(level: DDLogLevel, _ message: @autoclosure () -> String) -> String
}

public protocol Logger {
    func debug(_ message: @autoclosure () -> String)
    func info(_ message: @autoclosure () -> String)
    func warning(_ message: @autoclosure () -> String)
    func verbose(_ message: @autoclosure () -> String)
    func error(_ message: @autoclosure () -> String)
}

public extension DevLoggerService {
    static func formatMessage(level: DDLogLevel, _ message: @autoclosure () -> String) -> String {
        let msg = message()
            .replacingOccurrences(of: "\r", with: "\r*", options: .caseInsensitive, range: nil)
            .replacingOccurrences(of: "\r ", with: "\r* ", options: .caseInsensitive, range: nil)
        let lvlString: String
        switch level {
        case .debug:
            lvlString = "[DEBUG]"
        case .info:
            lvlString = "[INFO]"
        case .warning:
            lvlString = "[WARNING]"
        case .error:
            lvlString = "[ERROR]"
        case .all:
            lvlString = "[ALL]"
        case .verbose:
            lvlString = "[VERBOSE]"
        case .off:
            lvlString = "[OFF]"
        @unknown default:
            fatalError()
        }
        return lvlString + " " + msg
    }
}

// MARK: - ApplicationService

public final class DevLoggerImplementation: DevLoggerService, ApplicationDelegateService {
    public init() {}

    public func registerApplication(_: UIApplication, didFinishLaunchingWithOptions _: [AnyHashable: Any]?) -> Bool {
        guard DDLog.allLoggers.isEmpty else {
            return true
        }

        // Prepare file logger
        let fileLogger = DDFileLogger()
        fileLogger.maximumFileSize = 5 * 1024 * 1024 // 5 Megabytes
        fileLogger.rollingFrequency = 3 * 24 * 60 * 60 // 3 days

        // Force the current log file to be rolled
        fileLogger.rollLogFile(withCompletion: nil)
        DDLog.add(fileLogger)

        DDLog.add(DDOSLogger.sharedInstance)

        return true
    }

    public func applicationWillTerminate(_: UIApplication) {
        DDLog.removeAllLoggers()
    }
}
