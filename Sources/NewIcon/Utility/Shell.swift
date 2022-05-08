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
        path: String,
        command: String,
        pipe: Pipe,
        currentDirectory: URL? = nil,
        environment: [String: String] = [:],
        terminationHandler: @escaping (Process?) -> Void = { _ in }
    ) -> Process {
        let uuid = UUID()
        let shellPath = ProcessInfo().environment["SHELL"]
        let process = Process()
        subprocesses[uuid] = process
        
        if let currentDirectory = currentDirectory {
            process.currentDirectoryURL = currentDirectory
        }
        process.environment = ProcessInfo().environment
            .merging(environment, uniquingKeysWith: { (old, new) in new })
        process.launchPath = shellPath!
        process.arguments = ["-c", "\(path) \(command)"]
        process.terminationHandler = { process in
            DispatchQueue.main.async {
                subprocesses.removeValue(forKey: uuid)
                terminationHandler(process)
            }
        }
        process.standardOutput = pipe
        
        process.launch()
        
        return process
    }
    
    static func execute(
        path: String,
        command: String,
        currentDirectory: URL? = nil,
        environment: [String: String] = [:]
    ) throws -> String? {
        let pipe = Pipe()
        Shell.execute(path: path, command: command, pipe: pipe, currentDirectory: currentDirectory, environment: environment)
        return try pipe.fileHandleForReading
            .readToEnd()
            .flatMap { String(data: $0, encoding: .utf8) }
        
    }
}
