//
//  NimbusInMobiRequestInterceptor.swift
//  Nimbus
//  Created on 7/31/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import Foundation
import NimbusKit

final class NimbusInMobiRequestInterceptor {
    
    /// Bridge that communicates with InMobi SDK
    private let bridge: InMobiRequestBridgeType
    
    init(bridge: InMobiRequestBridgeType = InMobiRequestBridge()) {
        self.bridge = bridge
    }
}

extension NimbusInMobiRequestInterceptor: NimbusRequest.Interceptor {
    public func modifyRequest(request: NimbusRequest) async throws -> [NimbusRequest.Delta] {
        let bidToken = try await bridge.bidToken
        try Task.checkCancellation()
        
        return [.init(target: .user, key: "inmobi_buyeruid", value: bidToken)]
    }
}
