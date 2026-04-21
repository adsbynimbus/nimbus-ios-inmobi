//
//  NimbusInMobiAdController.swift
//  Nimbus
//  Created on 7/31/25
//  Copyright © 2025 Nimbus Advertising Solutions Inc. All rights reserved.
//

import UIKit
import NimbusKit
import InMobiSDK

final class NimbusInMobiAdController: AdController, @MainActor IMBannerDelegate, @MainActor IMInterstitialDelegate, @MainActor IMNativeDelegate {
    // MARK: - Properties
    
    var bannerAd: IMBanner?
    var interstitialAd: IMInterstitial?
    var nativeAd: IMNative?
    
    override class func setup(
        response: NimbusResponse,
        container: UIView,
        adPresentingViewController: UIViewController?
    ) -> AdController {
        let adController = Self.init(
            response: response,
            isBlocking: false,
            isRewarded: false,
            container: container,
            adPresentingViewController: adPresentingViewController
        )
        
        return adController
    }
    
    override class func setupBlocking(
        response: NimbusResponse,
        isRewarded: Bool,
        adPresentingViewController: UIViewController,
    ) -> AdController {
        let adController = Self.init(
            response: response,
            isBlocking: true,
            isRewarded: isRewarded,
            container: nil,
            adPresentingViewController: adPresentingViewController
        )
        
        return adController
    }
    
    override func load() {
        guard let strPlacementId = response.bid.ext?.omp?.buyerPlacementId, let placementId = Int64(strPlacementId) else {
            sendNimbusError(.inmobi(reason: .invalidState, stage: .render, detail: "Placement id is missing or invalid"))
            return
        }
        
        guard let markupData = response.bid.adm.data(using: .utf8) else {
            sendNimbusError(.inmobi(stage: .render, detail: "Couldn't convert InMobi markup String to Data"))
            return
        }
        
        switch adRenderType {
        case .banner:
            let adSize = response.bid.size
            
            let bannerAd = IMBanner(
                frame: CGRect(x: 0, y: 0, width: adSize.width, height: adSize.height),
                placementId: placementId,
                delegate: self
            )
            bannerAd.extras = InMobiRequestBridge.extras
            bannerAd.load(markupData)
            bannerAd.shouldAutoRefresh(false)
            self.bannerAd = bannerAd
        case .native:
            nativeAd = IMNative(placementId: placementId, delegate: self)
            nativeAd?.extras = InMobiRequestBridge.extras
            nativeAd?.load(markupData)
        case .interstitial, .rewarded:
            interstitialAd = IMInterstitial(placementId: placementId, delegate: self)
            interstitialAd?.extras = InMobiRequestBridge.extras
            interstitialAd?.load(markupData)
        @unknown default:
            sendNimbusError(.inmobi(reason: .unsupported, stage: .render, detail: "Unsupported adRenderType: \(adRenderType.rawValue)"))
        }
    }
    
    @MainActor
    func presentIfNeeded() {
        guard started, adState == .ready else { return }
        
        adState = .resumed
        
        if let bannerAd {
            adView.addSubview(bannerAd)
        } else if let nativeAd, let nativeAdProvider = InMobiExtension.nativeAdViewProvider {
            let nativeView = nativeAdProvider(adView, nativeAd)
            nativeView.translatesAutoresizingMaskIntoConstraints = false
            
            adView.addSubview(nativeView)
            
            NSLayoutConstraint.activate([
                nativeView.leadingAnchor.constraint(equalTo: adView.leadingAnchor),
                nativeView.trailingAnchor.constraint(equalTo: adView.trailingAnchor),
                nativeView.topAnchor.constraint(equalTo: adView.topAnchor),
                nativeView.bottomAnchor.constraint(equalTo: adView.bottomAnchor)
            ])
        } else if let interstitialAd, let adPresentingViewController {
            interstitialAd.show(from: adPresentingViewController)
        } else {
            sendNimbusError(.inmobi(reason: .invalidState, stage: .render, detail: "Ad \(adRenderType) is invalid and could not be presented."))
        }
    }
    
    override func onStart() {
        Task { @MainActor in
            presentIfNeeded()
        }
    }
    
    override func onDestroy() {
        bannerAd = nil
        interstitialAd = nil
        nativeAd = nil
    }
    
    private func setReady() {
        Task { @MainActor in
            adState = .ready
            sendNimbusEvent(.loaded)
            presentIfNeeded()
        }
    }
    
    // MARK: - Banner Delegate
    
    func bannerDidFinishLoading(_ banner: InMobiSDK.IMBanner) {
        setReady()
    }
    
    func bannerAdImpressed(_ banner: InMobiSDK.IMBanner) {
        sendNimbusEvent(.impression)
    }
    
    func banner(_ banner: IMBanner, didInteractWithParams params: [String : Any]?) {
        sendNimbusEvent(.clicked)
    }
    
    func banner(_ banner: InMobiSDK.IMBanner, didFailToReceiveWithError error: InMobiSDK.IMRequestStatus) {
        sendNimbusError(.inmobi(stage: .render, detail: error.localizedDescription))
    }

    func banner(_ banner: InMobiSDK.IMBanner, didFailToLoadWithError error: InMobiSDK.IMRequestStatus) {
        sendNimbusError(.inmobi(stage: .render, detail: error.localizedDescription))
    }
    
    // MARK: - Native Delegate
    
    func nativeDidFinishLoading(_ native: IMNative) {
        setReady()
    }
    
    func nativeAdImpressed(_ native: IMNative) {
        sendNimbusEvent(.impression)
    }
    
    func native(_ native: IMNative, didInteractWithParams params: [String : Any]?) {
        sendNimbusEvent(.clicked)
    }
    
    func native(_ native: IMNative, didFailToLoadWithError error: IMRequestStatus) {
        sendNimbusError(.inmobi(stage: .render, detail: error.localizedDescription))
    }

    // MARK: - Interstitial/Rewarded Delegate
    
    func interstitialDidFinishLoading(_ interstitial: IMInterstitial) {
        setReady()
    }
    
    func interstitialAdImpressed(_ interstitial: IMInterstitial) {
        sendNimbusEvent(.impression)
    }
    
    func interstitial(_ interstitial: IMInterstitial, didInteractWithParams params: [String : Any]?) {
        sendNimbusEvent(.clicked)
    }
    
    func interstitial(_ interstitial: IMInterstitial, rewardActionCompletedWithRewards rewards: [String : Any]) {
        sendNimbusEvent(.completed)
    }
    
    func interstitialDidDismiss(_ interstitial: IMInterstitial) {
        destroy()
    }
    
    func interstitial(_ interstitial: IMInterstitial, didFailToReceiveWithError error: any Error) {
        sendNimbusError(.inmobi(stage: .render, detail: error.localizedDescription))
    }
    
    func interstitial(_ interstitial: IMInterstitial, didFailToPresentWithError error: IMRequestStatus) {
        sendNimbusError(.inmobi(stage: .render, detail: error.localizedDescription))
    }
}

// Internal: Do NOT implement delegate conformance as separate extensions as the methods won't not be found in runtime when built as a static library
