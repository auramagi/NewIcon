//
//  Data+.swift
//  
//
//  Created by Mikhail Apurin on 31.05.2022.
//

import CommonCrypto
import Foundation

extension Data {
    func sha256Hash() -> Data {
        var hash = [UInt8](repeating: 0,  count: Int(CC_SHA256_DIGEST_LENGTH))
        withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(count), &hash)
        }
        return Data(hash)
    }
    
    func base64EncodedSHA256Hash() -> String {
        sha256Hash().base64EncodedString()
    }
}
