# UserAcquisition

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

UserAcquisition is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'UserAcquisition', :git => "https://github.com/inapps-io/UserAcquisition.git"
```

## Usage
In didFinishLaunchingWithOptions method:
```swift
UserAcquisition.shared.configure(withAPIKey: "APIKey")
or
UserAcquisition.shared.configure(withAPIKey: "APIKey", urlRequest: "Here select URL from Enum or enter your")

Enum URLs:
    enum Urls: String {
        case inapps = "https://api.inapps.io/v2"
        case subr = "https://api.subr.app/v1"
    }
```
After successful purchase:
```swift
UserAcquisition.shared.logPurchase(of: product, endPointUrl: "Here select end point from Enum or enter your")

Enum End point:
    enum EndPoints: String {
        case receipt = "/receipt"
        case pushToken = "/ios/push_token"
    }
```
After receiving PushDeviceToken:
```swift
UserAcquisition.shared.log(pushDeviceToken: "PushDeviceToken", and originaTransactionID: "OriginalTransactionID", endPointUrl: "Here select end point from Enum or enter your")

Enum End point:
    enum EndPoints: String {
        case receipt = "/receipt"
        case pushToken = "/ios/push_token"
    }
```
Add AppsFlyer:
```swift
import AppsFlyerLib

extension AppDelegate: AppsFlyerTrackerDelegate {
    func onConversionDataReceived(_ installData: [AnyHashable : Any]!) {
        if let data = installData as? [String: Any] {
            UserAcquisition.shared.conversionInfo.setAppsFlyerData(data)
            UserAcquisition.shared.conversionInfo.appsFlyerId = AppsFlyerTracker.shared().getAppsFlyerUID() ?? ""
        }
    }
}
```
Add Adjust:
```swift
import Adjust

extension AppDelegate: AdjustDelegate {
    func adjustAttributionChanged(_ attribution: ADJAttribution?) {
        if let data = attribution?.dictionary() {
            UserAcquisition.shared.conversionInfo.setAdjustData(data)
        }
    }
}
```
Add YandexMetrica:
```swift
import YandexMobileMetrica

YMMYandexMetrica.requestAppMetricaDeviceID(withCompletionQueue: .main) { [unowned self] id, error in
    UserAcquisition.shared.conversionInfo.appmetricaId = id ?? ""
}
```

## Author

Mikhail Verenich

Support:
hi@inapps.io

## License

UserAcquisition is available under the MIT license. See the LICENSE file for more info.
