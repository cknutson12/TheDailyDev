//
//  DebugLogger.swift
//  TheDailyDev
//
//  Created for production logging control
//

import Foundation

/// A debug logging utility that only prints in DEBUG builds
/// In production (RELEASE builds), all debug logs are suppressed
struct DebugLogger {
    /// Print a debug message (only in DEBUG builds)
    static func log(_ message: String) {
        #if DEBUG
        print(message)
        #endif
    }
    
    /// Print a debug message with a prefix (only in DEBUG builds)
    static func log(_ prefix: String, _ message: String) {
        #if DEBUG
        print("\(prefix) \(message)")
        #endif
    }
    
    /// Always print (for critical errors that should be logged in production)
    static func error(_ message: String) {
        print("❌ ERROR: \(message)")
    }
    
    /// Always print (for important info that should be logged in production)
    static func info(_ message: String) {
        #if DEBUG
        print("ℹ️ \(message)")
        #else
        // In production, use os_log or a logging service instead of print
        // For now, we'll suppress non-critical info in production
        #endif
    }
}

