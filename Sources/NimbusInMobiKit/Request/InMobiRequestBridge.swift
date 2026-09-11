//
//  InMobiRequestBridge.swift
//  Nimbus
//  Created on 7/31/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import InMobiSDK
import NimbusKit

protocol InMobiRequestBridgeType: Sendable {
    var bidToken: String { get throws }
}

final class InMobiRequestBridge: InMobiRequestBridgeType {
    init() {}
    
    static let extras: [String: String] = [
        "tp": "c_nimbus",
        "tp-ver": Nimbus.version
    ]
    
    var bidToken: String {
        get throws {
            guard let token = IMSdk.getTokenWithExtras(Self.extras, andKeywords: nil) else {
                throw NimbusError.inmobi(stage: .request, detail: "Couldn't fetch bid token")
            }
            
            return token
        }
    }
    
    @inlinable
    static func set(coppa: Bool) {
        IMSdk.setIsAgeRestricted(coppa)
    }
}
