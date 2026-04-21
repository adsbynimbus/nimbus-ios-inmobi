//
//  InMobiExtension.swift
//  Nimbus
//  Created on 10/1/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import NimbusKit
import InMobiSDK
import UIKit

/// Nimbus extension for InMobi.
///
/// Enables InMobi rendering when included in `Nimbus.initialize(...)`.
/// Supports dynamic enable/disable at runtime.
///
/// ### Notes:
///   - Instantiate within the `Nimbus.initialize` block; the extension is installed and enabled automatically.
///   - Disable rendering with `InMobiExtension.disable()`.
///   - Re-enable rendering with `InMobiExtension.enable()`.
public struct InMobiExtension: NimbusRequestExtension, NimbusRenderExtension {
    @_documentation(visibility: internal)
    public var interceptor: any NimbusRequest.Interceptor
    
    @_documentation(visibility: internal)
    public var enabled = true
    
    @_documentation(visibility: internal)
    public var network: String { "inmobisdk" }
    
    @_documentation(visibility: internal)
    public var controllerType: AdController.Type { NimbusInMobiAdController.self }
    
    /// Creates an InMobi extension.
    ///
    /// - Parameter accountId: The InMobi Account ID. If provided, Nimbus initializes the InMobi SDK automatically.
    ///
    /// ##### Usage
    /// ```swift
    /// Nimbus.initialize(publisher: "<publisher>", apiKey: "<apiKey>") {
    ///     InMobiExtension(accountId: "<accountId>") // Enables InMobi rendering
    /// }
    /// ```
    public init(accountId: String? = nil) {
        self.interceptor = NimbusInMobiRequestInterceptor()
        
        guard let accountId else {
            Nimbus.Log.lifecycle.debug("Skipping InMobi SDK initialization, accountId was not provided")
            return
        }
        
        IMSdk.initWithAccountID(accountId) { error in
            if let error {
                Nimbus.Log.lifecycle.error("InMobi SDK initialization failed: \(error.localizedDescription)")
            } else {
                Nimbus.Log.lifecycle.debug("InMobi SDK initialization completed")
            }
        }
    }
    
    @_documentation(visibility: internal)
    public func coppaDidChange(coppa: Bool) {
        InMobiRequestBridge.set(coppa: coppa)
    }
}

public extension InMobiExtension {
    /**
     The UIView returned from this method should have all of the data set from the native ad
     on children views such as the call to action, image data, title, etc.
     The view returned from this method should NOT be attached to the container passed in as
     it will be attached at a later time during the rendering process.
     
     DO NOT set nativeAd.delegate! Nimbus uses it to fires events (impression, click) as NimbusEvent. You may
     set AdController.delegate and listen to didReceiveNimbusEvent() and didReceiveNimbusError() instead.
     
     - Parameters:
       - container: The container the layout will be attached to
       - nativeAd: InMobi native ad
     
     - Returns: Your custom UIView. DO NOT attach the view to the hierarchy yourself.
         */
    @MainActor
    @preconcurrency
    static var nativeAdViewProvider: ((_ container: UIView, _ nativeAd: IMNative) -> UIView)?
}
