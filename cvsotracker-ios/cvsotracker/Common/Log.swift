//
//  Log.swift
//  nconvapp
//
//  Created by Ihar Tsimafeichyk on 2/10/20.
//  Copyright © 2020 Ihar Tsimafeichyk. All rights reserved.
//

import CocoaLumberjack
import Foundation
import Services

public final class Log: Services.Logger {
    static let shared = Log()

    public func debug(_ message: @autoclosure () -> String) {
        logDebug(message())
    }

    public func info(_ message: @autoclosure () -> String) {
        logInfo(message())
    }

    public func warning(_ message: @autoclosure () -> String) {
        logWarning(message())
    }

    public func verbose(_ message: @autoclosure () -> String) {
        logVerbose(message())
    }

    public func error(_ message: @autoclosure () -> String) {
        logError(message())
    }
}

public func logDebug(_ message: @autoclosure () -> String,
                     context: Int = 0,
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line,
                     tag: AnyObject? = nil,
                     asynchronous async: Bool = false) {

    _DDLogMessage(DevLoggerImplementation.formatMessage(level: .debug, message()),
                  level: .debug,
                  flag: .debug,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async,
                  ddlog: DDLog.sharedInstance)
}

public func logInfo(_ message: @autoclosure () -> String,
                    context: Int = 0,
                    file: StaticString = #file,
                    function: StaticString = #function,
                    line: UInt = #line,
                    tag: AnyObject? = nil,
                    asynchronous async: Bool = false) {
    _DDLogMessage(DevLoggerImplementation.formatMessage(level: .info, message()),
                  level: .info,
                  flag: .info,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async,
                  ddlog: DDLog.sharedInstance)
}

public func logWarning(_ message: @autoclosure () -> String,
                       context: Int = 0,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line,
                       tag: AnyObject? = nil,
                       asynchronous async: Bool = false) {

    _DDLogMessage(DevLoggerImplementation.formatMessage(level: .warning, message()),
                  level: .warning,
                  flag: .warning,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async,
                  ddlog: DDLog.sharedInstance)
}

public func logVerbose(_ message: @autoclosure () -> String,
                       context: Int = 0,
                       file: StaticString = #file,
                       function: StaticString = #function,
                       line: UInt = #line,
                       tag: AnyObject? = nil,
                       asynchronous async: Bool = false) {
    _DDLogMessage(DevLoggerImplementation.formatMessage(level: .verbose, message()),
                  level: .verbose,
                  flag: .verbose,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async,
                  ddlog: DDLog.sharedInstance)
}

public func logError(_ message: @autoclosure () -> String,
                     context: Int = 0,
                     file: StaticString = #file,
                     function: StaticString = #function,
                     line: UInt = #line,
                     tag: AnyObject? = nil,
                     asynchronous async: Bool = false) {
    _DDLogMessage(DevLoggerImplementation.formatMessage(level: .error, message()),
                  level: .error,
                  flag: .error,
                  context: context,
                  file: file,
                  function: function,
                  line: line,
                  tag: tag,
                  asynchronous: async,
                  ddlog: DDLog.sharedInstance)
}

@discardableResult
func measure<A>(name: String = "", _ block: () -> A) -> A {
    let startTime = CACurrentMediaTime()
    let result = block()
    let timeElapsed = CACurrentMediaTime() - startTime
    logInfo("[TIME] \(name) - \(timeElapsed)")
    return result
}

@discardableResult
func measure<A>(name: String = "", _ block: () throws -> A) throws -> A {
    let startTime = CACurrentMediaTime()
    let result = try block()
    let timeElapsed = CACurrentMediaTime() - startTime
    logInfo("[TIME] \(name) - \(timeElapsed)")
    return result
}
