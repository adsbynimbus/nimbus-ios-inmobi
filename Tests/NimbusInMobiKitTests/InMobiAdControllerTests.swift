//
//  InMobiAdControllerTests.swift
//  NimbusInMobiKit
//  Created on 10/21/26
//  Copyright © 2026 Nimbus Advertising Solutions Inc. All rights reserved.
//

import Testing
@testable import NimbusInMobiKit
@testable import NimbusKit
import UIKit
import InMobiSDK

private let placementId: Int64 = 1234567890
private let markup = "test-markup"

@Suite("InMobi AdController tests")
@MainActor
struct InMobiAdControllerTests {

    // MARK: - Banner

    @Test func bannerAdEventsGetFired() throws {
        let (adController, delegate) = makeAdController(.banner)

        let banner = adController.buildBannerAd(placementId: placementId)
        #expect(adController.bannerAd === banner)
        #expect(adController.nativeAd == nil)
        #expect(adController.interstitialAd == nil)

        let inmobi = try #require(banner.delegate, "banner delegate not wired")
        #expect(inmobi === adController)

        inmobi.bannerDidFinishLoading?(banner)
        #expect(delegate.events == [.loaded])

        #expect(adController.adView.subviews.isEmpty)
        adController.start()
        #expect(adController.adView.subviews.first === banner)

        inmobi.bannerAdImpressed?(banner)
        #expect(delegate.events == [.loaded, .impression])

        inmobi.banner?(banner, didInteractWithParams: nil)
        #expect(delegate.events == [.loaded, .impression, .clicked])
        #expect(delegate.lastError == nil)
    }

    @Test func bannerAdGetsDestroyedOnLoadError() throws {
        let (adController, delegate) = makeAdController(.banner)
        let banner = adController.buildBannerAd(placementId: placementId)
        let inmobi = try #require(banner.delegate, "banner delegate not wired")

        let status = makeRequestStatus()
        inmobi.banner?(banner, didFailToLoadWithError: status)

        expectInMobiError(delegate, status: status)
        #expect(delegate.events.last == .destroyed)
    }

    // MARK: - Native

    @Test func nativeAdEventsGetFired() throws {
        let (adController, delegate) = makeAdController(.native)

        let native = adController.buildNativeAd(placementId: placementId)
        #expect(adController.nativeAd === native)
        #expect(adController.bannerAd == nil)
        #expect(adController.interstitialAd == nil)

        let inmobi = try #require(native.delegate, "native delegate not wired")
        #expect(inmobi === adController)

        let nativeView = UIView()
        var providedAd: IMNative?
        InMobiExtension.nativeAdViewProvider = { _, ad in
            providedAd = ad
            return nativeView
        }
        defer { InMobiExtension.nativeAdViewProvider = nil }

        // Loaded before start(): the adapter keeps the IMNative, so it renders once started
        inmobi.nativeDidFinishLoading?(native)
        #expect(delegate.events == [.loaded])
        #expect(adController.adView.subviews.isEmpty)

        adController.start()
        #expect(adController.adView.subviews.first === nativeView)
        #expect(providedAd === native)

        inmobi.nativeAdImpressed?(native)
        #expect(delegate.events == [.loaded, .impression])

        inmobi.native?(native, didInteractWithParams: nil)
        #expect(delegate.events == [.loaded, .impression, .clicked])

        inmobi.nativeDidFinishPlayingMedia?(native)
        #expect(delegate.events == [.loaded, .impression, .clicked, .completed])
        #expect(!delegate.events.contains(.rewardEarned))
        #expect(delegate.lastError == nil)
    }

    @Test func nativeAdGetsDestroyedOnLoadError() throws {
        let (adController, delegate) = makeAdController(.native)
        let native = adController.buildNativeAd(placementId: placementId)
        let inmobi = try #require(native.delegate, "native delegate not wired")

        let status = makeRequestStatus()
        inmobi.native?(native, didFailToLoadWithError: status)

        expectInMobiError(delegate, status: status)
        #expect(delegate.events.last == .destroyed)
    }

    @Test func nativeAdWithoutViewProviderGetsDestroyed() throws {
        let (adController, delegate) = makeAdController(.native)
        let native = adController.buildNativeAd(placementId: placementId)
        let inmobi = try #require(native.delegate, "native delegate not wired")
        InMobiExtension.nativeAdViewProvider = nil

        inmobi.nativeDidFinishLoading?(native)
        adController.start()

        #expect(delegate.lastError != nil)
        #expect(adController.adView.subviews.isEmpty)
        #expect(delegate.events.last == .destroyed)
    }

    // MARK: - Interstitial

    @Test func interstitialAdEventsGetFired() throws {
        let (adController, delegate) = makeAdController(.interstitial)

        let interstitial = adController.buildInterstitialAd(placementId: placementId)
        #expect(adController.interstitialAd === interstitial)
        #expect(adController.bannerAd == nil)
        #expect(adController.nativeAd == nil)

        let inmobi = try #require(interstitial.delegate, "interstitial delegate not wired")
        #expect(inmobi === adController)

        // Not started: show(from:) would hit the real SDK with nothing loaded
        inmobi.interstitialDidFinishLoading?(interstitial)
        #expect(delegate.events == [.loaded])

        inmobi.interstitialAdImpressed?(interstitial)
        #expect(delegate.events == [.loaded, .impression])

        inmobi.interstitial?(interstitial, didInteractWithParams: nil)
        #expect(delegate.events == [.loaded, .impression, .clicked])
        #expect(delegate.lastError == nil)

        inmobi.interstitialDidDismiss?(interstitial)
        #expect(delegate.lastError == nil)
        #expect(!delegate.events.contains(.rewardEarned))
        #expect(delegate.events.last == .destroyed)
    }

    @Test func interstitialAdGetsDestroyedOnLoadError() throws {
        let (adController, delegate) = makeAdController(.interstitial)
        let interstitial = adController.buildInterstitialAd(placementId: placementId)
        let inmobi = try #require(interstitial.delegate, "interstitial delegate not wired")

        let status = makeRequestStatus()
        inmobi.interstitial?(interstitial, didFailToLoadWithError: status)

        expectInMobiError(delegate, status: status)
        #expect(delegate.events.last == .destroyed)
    }

    /// Not part of IMInterstitialDelegate per InMobi's docs, so it can't be fired through the delegate;
    /// kept as a safety net in case the SDK calls it, so verify it still maps to an error.
    @Test func interstitialAdGetsDestroyedOnReceiveError() {
        let (adController, delegate) = makeAdController(.interstitial)
        let interstitial = adController.buildInterstitialAd(placementId: placementId)

        let error = NSError(domain: "com.inmobi.test", code: 1, userInfo: [NSLocalizedDescriptionKey: "InMobi test error"])
        adController.interstitial(interstitial, didFailToReceiveWithError: error)

        #expect(delegate.lastError != nil)
        #expect(delegate.lastError!.domain == NimbusError.Domain(rawValue: "inmobi"))
        #expect(delegate.lastError!.detail == "InMobi test error")
        #expect(delegate.events.last == .destroyed)
    }

    /// Same safety-net callback as above, on the banner side.
    @Test func bannerAdGetsDestroyedOnReceiveError() {
        let (adController, delegate) = makeAdController(.banner)
        let banner = adController.buildBannerAd(placementId: placementId)

        let status = makeRequestStatus()
        adController.banner(banner, didFailToReceiveWithError: status)

        expectInMobiError(delegate, status: status)
        #expect(delegate.events.last == .destroyed)
    }

    @Test func rewardedAdGetsDestroyedOnLoadError() throws {
        let (adController, delegate) = makeAdController(.rewarded)
        let rewarded = adController.buildInterstitialAd(placementId: placementId)
        let inmobi = try #require(rewarded.delegate, "rewarded delegate not wired")

        let status = makeRequestStatus()
        inmobi.interstitial?(rewarded, didFailToLoadWithError: status)

        expectInMobiError(delegate, status: status)
        #expect(!delegate.events.contains(.rewardEarned))
        #expect(delegate.events.last == .destroyed)
    }

    @Test func interstitialAdGetsDestroyedOnPresentError() throws {
        let (adController, delegate) = makeAdController(.interstitial)
        let interstitial = adController.buildInterstitialAd(placementId: placementId)
        let inmobi = try #require(interstitial.delegate, "interstitial delegate not wired")

        inmobi.interstitialDidFinishLoading?(interstitial)

        let status = makeRequestStatus()
        inmobi.interstitial?(interstitial, didFailToPresentWithError: status)

        expectInMobiError(delegate, status: status)
        #expect(delegate.events.last == .destroyed)
    }

    // MARK: - Rewarded

    @Test func rewardedAdEventsGetFired() throws {
        let (adController, delegate) = makeAdController(.rewarded)

        let rewarded = adController.buildInterstitialAd(placementId: placementId)
        #expect(adController.interstitialAd === rewarded)
        #expect(adController.bannerAd == nil)
        #expect(adController.nativeAd == nil)

        let inmobi = try #require(rewarded.delegate, "rewarded delegate not wired")
        #expect(inmobi === adController)

        inmobi.interstitialDidFinishLoading?(rewarded)
        #expect(delegate.events == [.loaded])

        inmobi.interstitialAdImpressed?(rewarded)
        #expect(delegate.events == [.loaded, .impression])

        inmobi.interstitial?(rewarded, didInteractWithParams: nil)
        #expect(delegate.events == [.loaded, .impression, .clicked])

        inmobi.interstitial?(rewarded, rewardActionCompletedWithRewards: ["coins": 10])
        #expect(delegate.events == [.loaded, .impression, .clicked, .rewardEarned])
        #expect(delegate.lastError == nil)

        inmobi.interstitialDidDismiss?(rewarded)
        #expect(delegate.lastError == nil)
        #expect(delegate.events.last == .destroyed)
    }

    @Test func rewardedAdGetsDestroyedOnPresentError() throws {
        let (adController, delegate) = makeAdController(.rewarded)
        let rewarded = adController.buildInterstitialAd(placementId: placementId)
        let inmobi = try #require(rewarded.delegate, "rewarded delegate not wired")

        inmobi.interstitialDidFinishLoading?(rewarded)

        let status = makeRequestStatus()
        inmobi.interstitial?(rewarded, didFailToPresentWithError: status)

        expectInMobiError(delegate, status: status)
        #expect(!delegate.events.contains(.rewardEarned))
        #expect(delegate.events.last == .destroyed)
    }

    // MARK: - Load validation

    @Test func loadFailsWithNonNumericPlacementId() {
        let adController = InMobiAdController(
            response: .init(id: "", bid: .init(mtype: .static, adm: markup, price: 0, ext: .init(omp: .init(buyer: "inmobisdk", buyerPlacementId: "not-a-number")))),
            isBlocking: false,
            isRewarded: false,
            container: container,
            adPresentingViewController: presenter
        )
        let delegate = MockDelegate()
        adController.delegate = delegate

        adController.load()

        #expect(adController.bannerAd == nil)
        #expect(delegate.lastError?.detail == "Placement id is missing or invalid")
        #expect(delegate.events.last == .destroyed)
    }

    /// Guards the helper below: if building a valid IMRequestStatus breaks, fail here
    /// instead of trapping inside the adapter in every error test.
    @Test func requestStatusHelperBuildsValidError() {
        let status = makeRequestStatus()
        #expect(status.domain == "com.inmobi.test")
        #expect(status.code == 1)
        #expect(status.localizedDescription == "InMobi test error")
    }

    // MARK: - Helpers

    /// Fresh per test: Swift Testing creates a new suite instance for every @Test.
    private let container = UIView()

    /// AdController holds adPresentingViewController weakly, so it must outlive the test body.
    private let presenter = UIViewController()

    enum Format { case banner, native, interstitial, rewarded }

    private func makeAdController(_ format: Format) -> (InMobiAdController, MockDelegate) {
        let response: NimbusResponse = switch format {
        case .banner, .interstitial:
            .init(id: "", bid: .init(mtype: .static, adm: markup, price: 0, ext: .init(omp: .init(buyer: "inmobisdk", buyerPlacementId: String(placementId)))))
        case .native:
            .init(id: "", bid: .init(mtype: .native, adm: markup, price: 0, ext: .init(omp: .init(buyer: "inmobisdk", buyerPlacementId: String(placementId)))))
        case .rewarded:
            .init(id: "", bid: .init(mtype: .video, adm: markup, price: 0, ext: .init(omp: .init(buyer: "inmobisdk", buyerPlacementId: String(placementId)))))
        }

        let adController = InMobiAdController(
            response: response,
            isBlocking: format == .interstitial || format == .rewarded,
            isRewarded: format == .rewarded,
            container: container,
            adPresentingViewController: presenter
        )
        let delegate = MockDelegate()
        adController.delegate = delegate
        return (adController, delegate)
    }

    /// IMRequestStatus is a Swift NSError subclass that only implements init(); NSError's other
    /// initializers trap as "unimplemented initializer". `-[NSError init]` leaves the domain nil,
    /// which traps when the adapter reads `localizedDescription`, so fill NSError's backing ivars
    /// (_domain, _code, _userInfo) through KVC after init().
    private func makeRequestStatus() -> IMRequestStatus {
        let status = IMRequestStatus()
        status.setValue("com.inmobi.test", forKey: "domain")
        status.setValue(1, forKey: "code")
        status.setValue([NSLocalizedDescriptionKey: "InMobi test error"], forKey: "userInfo")
        return status
    }

    private func expectInMobiError(
        _ delegate: MockDelegate,
        status: IMRequestStatus,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        let error = delegate.lastError
        #expect(error != nil, sourceLocation: sourceLocation)
        #expect(error!.domain == NimbusError.Domain(rawValue: "inmobi"), sourceLocation: sourceLocation)
        #expect(error!.detail == status.localizedDescription, sourceLocation: sourceLocation)
    }
}

// MARK: - Mocks

class MockDelegate: AdController.Delegate {
    var events: [AdEvent] = []
    var lastError: NimbusError?

    func didReceiveNimbusEvent(event: NimbusKit.AdEvent) {
        events.append(event)
    }

    func didReceiveNimbusError(error: NimbusKit.NimbusError) {
        lastError = error
    }
}
