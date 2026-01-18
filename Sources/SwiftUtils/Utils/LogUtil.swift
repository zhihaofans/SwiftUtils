//
//  LogUtil.swift
//  SwiftUtils
//
//  Created by zzh on 2026/1/18.
//
import Foundation
import Logging

public enum LogUtil {
    private static var logger: Logger {
        SwiftUtils.logger
    }

    public static func d(_ message: String, metadata: Logger.Metadata? = nil) {
        debug(message, metadata: metadata)
    }

    public static func i(_ message: String, metadata: Logger.Metadata? = nil) {
        info(message, metadata: metadata)
    }

    public static func e(_ message: String, metadata: Logger.Metadata? = nil) {
        error(message, metadata: metadata)
    }

    public static func debug(_ message: String, metadata: Logger.Metadata? = nil) {
        logger.debug("\(message)", metadata: metadata ?? [:])
    }

    public static func info(_ message: String, metadata: Logger.Metadata? = nil) {
        logger.info("\(message)", metadata: metadata ?? [:])
    }

    public static func warning(_ message: String, metadata: Logger.Metadata? = nil) {
        logger.warning("\(message)", metadata: metadata ?? [:])
    }

    public static func error(_ message: String, metadata: Logger.Metadata? = nil) {
        logger.error("\(message)", metadata: metadata ?? [:])
    }
}
