// The Swift Programming Language
// https://docs.swift.org/swift-book

import Foundation
import Logging

/// SwiftUtils 命名空间入口
public let SU = SwiftUtils.self
public enum SwiftUtils {
    private static let defaultID = "github.zhihaofans.swiftutils"

    private static var loggerLabel: String = Bundle.main.bundleIdentifier ?? defaultID

    private static var _logger: Logger = {
        var logger = Logger(label: loggerLabel)
        #if DEBUG
        logger.logLevel = .debug
        #else
        logger.logLevel = .info
        #endif
        return logger
    }()

    static var logger: Logger {
        get { _logger }
        set { _logger = newValue }
    }

    public static func configureLogger(label: String? = nil, logLevel: Logger.Level? = nil) {
        if let label {
            loggerLabel = label
        }
        var newLogger = Logger(label: loggerLabel)
        if let logLevel {
            newLogger.logLevel = logLevel
        }
        logger = newLogger
    }

    public static let log = LogUtil.self
}
