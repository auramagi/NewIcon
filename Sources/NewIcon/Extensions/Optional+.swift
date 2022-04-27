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
