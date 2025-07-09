//
//  ScriptRunner.swift
//  ScriptRunner
//
//  Created by CodingIran on 2025/01/01.
//

import Foundation

// Enforce minimum Swift version for all platforms and build systems.
#if swift(<5.10)
#error("ScriptRunner doesn't support Swift versions below 5.10.")
#endif

/// Current ScriptRunner version Release 0.1.0. Necessary since SPM doesn't use dynamic libraries. Plus this will be more accurate.
public let version = "0.1.0"

#if os(macOS)

@available(macOS 10.15, *)
public enum ScriptError: LocalizedError, Sendable {
    case runBashFailed(Error)
    case outputInvalid
    case initAppleScriptFailed
    case executeAppleScriptFailed(String)

    public var errorDescription: String? {
        switch self {
            case .runBashFailed(let error):
                return "run bash failed: \(error.localizedDescription)"
            case .outputInvalid:
                return "output invalid"
            case .initAppleScriptFailed:
                return "init AppleScript failed"
            case .executeAppleScriptFailed(let reason):
                return "execute AppleScript failed: \(reason)"
        }
    }
}

@available(macOS 10.15, *)
open class ScriptRunner: @unchecked Sendable {
    public init() {}

    /// Run command with bash
    /// - Parameters:
    ///   - path: path to run
    ///   - command: command
    /// - Returns: output string
    @discardableResult
    public func runBash(path: String = "/bin/bash", command: [String]) throws -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = command
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
        } catch {
            throw ScriptError.runBashFailed(error)
        }
        process.waitUntilExit()
        let fileData = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let outputStr = String(data: fileData, encoding: .utf8) else {
            throw ScriptError.outputInvalid
        }
        return outputStr.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Run script with root permission
    /// - Parameter script: script string
    /// Throws: ScriptError
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
