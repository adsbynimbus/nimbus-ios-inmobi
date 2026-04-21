# NimbusInMobiKit

A Nimbus SDK extension for **InMobi bidding and rendering**. It enriches Nimbus ad requests with InMobi demand and handles ad rendering through the InMobi SDK when it wins the auction.

## Versioning
 
NimbusInMobiKit **major versions are kept in sync** with the InMobi SDK. For example, NimbusInMobiKit `10.x.x` depends on InMobi SDK `10.x.x`.
 
Minor and patch versions are independent — a NimbusInMobiKit patch release does not necessarily correspond to an InMobi SDK patch release, and vice versa.
 
| NimbusInMobiKit | InMobi SDK |
|---|---|
| 10.x.x | 10.x.x |

## Installation

### Swift Package Manager

#### Xcode Project

1. In Xcode, go to **File → Add Package Dependencies…**
2. Enter the repository URL:
   ```
   https://github.com/adsbynimbus/nimbus-ios-inmobi
   ```
3. Set the dependency rule to **Up to Next Major Version** and enter `10.0.0` as the minimum.
4. Click **Add Package** and select the **NimbusInMobiKit** library when prompted.

#### Package.swift

If you're managing dependencies through a `Package.swift` file, add the following:

```swift
dependencies: [
    .package(url: "https://github.com/adsbynimbus/nimbus-ios-inmobi", from: "10.0.0")
]
```

Then add the product to your target:

```swift
.product(name: "NimbusInMobiKit", package: "nimbus-ios-inmobi")
```

### CocoaPods

Add the following to your `Podfile`:

```ruby
pod 'NimbusInMobiKit'
```

Then run:

```sh
pod install
```

## Usage
 
Navigate to where you call `Nimbus.initialize` and register the `InMobiExtension`:
 
```swift
import NimbusInMobiKit
 
Nimbus.initialize(publisher: "<publisher>", apiKey: "<apiKey>") {
    InMobiExtension(accountId: "<accountId>")
}
```

If you provide an account ID, Nimbus will automatically initialize the InMobi SDK.

That's it — InMobi is now enabled in all upcoming requests.

## Documentation

- [Nimbus iOS SDK Documentation](https://docs.adsbynimbus.com/docs/sdk/ios) — integration guides, configuration, and API reference.
- [DocC API Reference](https://iosdocs.adsbynimbus.com) — auto-generated documentation for the latest release.

## Sample App

See NimbusInMobiKit in action in our public [sample app repository](https://github.com/adsbynimbus/nimbus-ios-sample), which demonstrates end-to-end integration including setup, bid requests, and ad rendering.
