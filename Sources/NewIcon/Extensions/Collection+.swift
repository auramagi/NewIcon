//
//  Collection+.swift
//  
//
//  Created by Mikhail Apurin on 08.05.2022.
//

import Foundation

extension Collection where Element: Hashable {
    func toSet() -> Set<Element> {
        Set(self)
    }
}
