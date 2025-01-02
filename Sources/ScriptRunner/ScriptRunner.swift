//
//  ScriptRunner.swift
//  ScriptRunner
//
//  Created by CodingIran on 2025/01/01.
//

import Foundation

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.5)
#error("ScriptRunner doesn't support Swift versions below 5.5.")
#endif

/// Current ScriptRunner version Release 0.0.1. Necessary since SPM doesn't use dynamic libraries. Plus this will be more accurate.
public let version = "0.0.1"

#if os(macOS)

public enum ScriptError: LocalizedError {
    case initAppleScriptFailed
    case executeAppleScriptFailed(String)

    public var errorDescription: String? {
        switch self {
        case .initAppleScriptFailed:
            return "init AppleScript failed"
        case .executeAppleScriptFailed(let reason):
            return "execute AppleScript failed: \(reason)"
        }
    }
}

open class ScriptRunner {
    public init() {}

    @discardableResult
    public func runBash(path: String = "/bin/bash", command: [String]) -> String? {
        let process = Process()
        process.launchPath = path
        process.arguments = command
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        process.waitUntilExit()
        let fileData = pipe.fileHandleForReading.readDataToEndOfFile()
        return String(data: fileData, encoding: String.Encoding.utf8)?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }

    public func runScriptWithRootPermission(script: String) throws {
        let tmpPath = FileManager.default.temporaryDirectory.appendingPathComponent(NSUUID().uuidString).appendingPathExtension("sh")
        try script.write(to: tmpPath, atomically: true, encoding: .utf8)
        let appleScriptStr = "do shell script \"bash \(tmpPath.path) \" with administrator privileges"
        guard let appleScript = NSAppleScript(source: appleScriptStr) else {
            throw ScriptError.initAppleScriptFailed
        }
        var dict: NSDictionary?
        _ = appleScript.executeAndReturnError(&dict)
        if let dict {
            throw ScriptError.executeAppleScriptFailed(dict.description)
        }
        try FileManager.default.removeItem(at: tmpPath)
    }
}

#endif
