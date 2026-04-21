//
//  NimbusInMobiInterceptorTests.swift
//  Nimbus
//  Created on 8/4/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

@testable import NimbusInMobiKit
@testable import NimbusKit
import InMobiSDK
import Testing

@Suite("InMobi request interceptor tests")
struct NimbusInMobiInterceptorTests {
    
    let interceptor = NimbusInMobiRequestInterceptor(bridge: MockInMobiRequestBridge())
    
    @Test func bidTokenAndRenderInfoGetsSet() async throws {
        let info = try await NimbusRequest(from: Nimbus.bannerAd(position: "test", size: .banner).adRequest!.request)
        let deltas = try await interceptor.modifyRequest(request: info)
        
        #expect(deltas.count == 1)
        #expect(deltas[0].target == .user)
        #expect(deltas[0].key == "inmobi_buyeruid")
        #expect(deltas[0].value as? String == "unitTestBuyerUID")
    }
    
    @Test func inmobiBidTokenGetsInsertedIntoRequest() async throws {
        var request = try await Nimbus.rewardedAd(position: "test").adRequest!.request
        request.interceptors = [interceptor]
        
        try await request.modifyRequestWithExtras(
            configuration: Nimbus.configuration,
            vendorId: "",
            appVersion: "1.0.0"
        )
        
        #expect(request.user?.ext?.extras["inmobi_buyeruid"] as? String == "unitTestBuyerUID")
    }
    
    @MainActor
    private func createNimbusAd(network: String) -> NimbusResponse {
        NimbusResponse(id: "", bid: .init(mtype: .static, adm: "", price: 0, ext: .init(omp: .init(buyer: network, buyerPlacementId: nil))))
    }
}

final class MockInMobiRequestBridge: InMobiRequestBridgeType {
    static var extras: [String : Any] = [:]
    
    var bidToken: String {
        "unitTestBuyerUID"
    }
}
