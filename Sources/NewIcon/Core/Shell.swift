//
//  Shell.swift
//  
//
//  Created by Mikhail Apurin on 08.05.2022.
//

import Foundation

enum Shell {
    static var subprocesses: [UUID: Process] = [:]
    
    @discardableResult
    static func execute(
        _ command: String,
        output: Any,
        error: Any? = nil,
        currentDirectory: URL? = nil,
        environment: [String: String] = [:],
        terminationHandler: @escaping (Process) -> Void = { _ in }
    ) throws -> Process {
        let uuid = UUID()
        let shellPath = ProcessInfo().environment["SHELL"]
        let process = Process()
        
        subprocesses[uuid] = process
        
        process.qualityOfService = .userInitiated
        if let currentDirectory = currentDirectory {
            process.currentDirectoryURL = currentDirectory
        }
        process.environment = ProcessInfo().environment
            .merging(environment, uniquingKeysWith: { (old, new) in new })
        process.launchPath = shellPath!
        process.arguments = ["-c", "\(command)"]
        process.terminationHandler = { process in
            DispatchQueue.main.async {
                subprocesses.removeValue(forKey: uuid)
                terminationHandler(process)
            }
        }
        
        process.standardOutput = output
        process.standardError = error
        
        try process.run()
        
        return process
    }
    
    @discardableResult
    static func executeSync(
        _ command: String,
        currentDirectory: URL? = nil,
        environment: [String: String] = [:]
    ) throws -> String? {
        let outputPipe = Pipe()
        try execute(command, output: outputPipe, currentDirectory: currentDirectory, environment: environment)
        return try outputPipe.fileHandleForReading
            .readToEnd()
            .flatMap { String(data: $0, encoding: .utf8) }
        
    }
    
    static func execute(
        _ command: String,
        currentDirectory: URL? = nil,
        environment: [String: String] = [:]
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            let outputPipe = Pipe()
            outputPipe.fileHandleForReading.readabilityHandler = { file in
                let data = file.availableData
                guard let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .newlines) else { return }
                continuation.yield(output)
            }
            
            var error: String?
            let errorPipe = Pipe()
            errorPipe.fileHandleForReading.readabilityHandler = { file in
                let data = file.availableData
                guard let output = String(data: data, encoding: .utf8) else { return }
                error = (error ?? "").appending(output)
            }
            
            do {
                try execute(command, output: outputPipe, error: errorPipe, currentDirectory: currentDirectory, environment: environment) { _ in
                    continuation.finish(throwing: error)
                }
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
    
    static func executeWithStandardOutput(
        _ command: String,
        currentDirectory: URL? = nil,
        environment: [String: String] = [:]
    ) async throws {
        try await withUnsafeThrowingContinuation { (continuation: UnsafeContinuation<Void, Error>) in
            do {
                try execute(
                    command,
                    output: FileHandle.standardOutput,
                    error: FileHandle.standardError,
                    currentDirectory: currentDirectory,
                    environment: environment,
                    terminationHandler: { _ in continuation.resume() }
                )
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
