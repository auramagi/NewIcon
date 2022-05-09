//
//  Optional+.swift
//  
//
//  Created by Mikhail Apurin on 28.04.2022.
//

import Foundation

extension Optional {
    func unwrapOrThrow(_ error: @autoclosure () -> Error) throws -> Wrapped {
        switch self {
        case let .some(wrapped):
            return wrapped
            
        case .none:
            throw error()
        }
    }
}

extension Optional where Wrapped == Error {
    mutating func catching(keepingFirst: Bool = true, _ block: () throws -> Void) {
        do {
            try block()
        } catch {
            guard !keepingFirst || self == nil else { return }
            self = error
        }
    }
    
    func throwIfPresent() throws {
        guard let error = self else { return }
        throw error
    }
}
