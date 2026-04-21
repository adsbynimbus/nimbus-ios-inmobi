//
//  InMobiRequestBridge.swift
//  Nimbus
//  Created on 7/31/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import InMobiSDK
import NimbusKit

protocol InMobiRequestBridgeType: Sendable {
    /// Not sure if IMSdk is thread safe
    @MainActor var bidToken: String { get throws }
}

final class InMobiRequestBridge: InMobiRequestBridgeType {
    public init() {}
    
    @MainActor static let extras: [String: Any] = [
        "tp": "c_nimbus",
        "tp-ver": Nimbus.version
    ]
    
    /// Not sure if IMSdk is thread safe
    @MainActor
    public var bidToken: String {
        get throws {
            guard let token = IMSdk.getTokenWithExtras(Self.extras, andKeywords: nil) else {
                throw NimbusError.inmobi(stage: .request, detail: "Couldn't fetch bid token")
            }
            
            return token
        }
    }
    
    @MainActor
    @inlinable
    public static func set(coppa: Bool) {
        IMSdk.setIsAgeRestricted(coppa)
    }
}
