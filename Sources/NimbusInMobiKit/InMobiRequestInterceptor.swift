//
//  InMobiRequestInterceptor.swift
//  Nimbus
//  Created on 7/31/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import Foundation
import NimbusKit

final class InMobiRequestInterceptor {
    
    /// Bridge that communicates with InMobi SDK
    private let bridge: InMobiRequestBridgeType
    
    init(bridge: InMobiRequestBridgeType = InMobiRequestBridge()) {
        self.bridge = bridge
    }
}

extension InMobiRequestInterceptor: NimbusRequest.Interceptor {
    public func modifyRequest(request: NimbusRequest) async throws -> [NimbusRequest.Delta] {
        let bidToken = try bridge.bidToken
        try Task.checkCancellation()
        
        return [.init(target: .user, key: "inmobi_buyeruid", value: bidToken)]
    }
}
