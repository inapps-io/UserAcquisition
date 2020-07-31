//
//  LTV.swift
//  LTV
//
//   
//  Copyright © 2019 dp. All rights reserved.
//

import Foundation
import AdSupport
import StoreKit
import SwiftyStoreKit

public class UserAcquisition: NSObject {

    public enum Urls: String {
        case inapps = "https://api.inapps.io/v2"
        case subr = "https://api.subr.app/v1"
    }
    
    public enum EndPoints: String {
        case receipt = "/receipt"
        case pushToken = "/ios/push_token"
    }
    
    public static let shared = UserAcquisition()
    
    public var conversionInfo = UserAcquisition.Info()
    
    private var APIKey = ""
    private var urlRequest = ""

    public func configure(withAPIKey APIKey: String, urlRequest: Urls = .inapps) {
        self.APIKey = APIKey
        self.urlRequest = urlRequest.rawValue
    }
    
    public func log(pushDeviceToken: String, and originaTransactionID: String, endPointUrl: EndPoints) {
        
        let params: [String: Any] = [
            "api_key": APIKey,
            "push_token": pushDeviceToken,
            "original_transaction_id": originaTransactionID
        ]
        
        requestToServer(params: params, endPoint: .pushToken)
    }
    
    public func logPurchase(of product: SKProduct, endPointUrl: EndPoints) {
        var receipt: String?
        let group = DispatchGroup()
        group.enter()
        SwiftyStoreKit.fetchReceipt(forceRefresh: false) { result in
            switch result {
            case .success(let receiptData):
                receipt = receiptData.base64EncodedString()
            case .error(let error):
                print(error)
                break
            }
            group.leave()
        }
        group.notify(queue: .global()) {
            if let receipt = receipt {
                self.logPurchase(info: self.conversionInfo, product: product, receipt: receipt, endPoint: endPointUrl)
            }
        }
    }

    public func setExtraValue(_ value: Any, forKey key: String) {
        conversionInfo.extra[key] = value
    }

    private func logPurchase(info: Info, product: SKProduct, receipt: String, endPoint: EndPoints) {
        
        var acquisitionSource: String {
            switch info.acquisitionSource {
            case .facebook:
                return "Facebook"
            case .searchAds:
                return "Search Ads"
            case .organic:
                return "Organic"
            case let .custom(source):
                return source
            }
        }
        
        var afi: String? {
            if ASIdentifierManager.shared().isAdvertisingTrackingEnabled {
                return ASIdentifierManager.shared().advertisingIdentifier.uuidString
            } else {
                return nil
            }
        }
        
        let iap: [String: Any] = [
            "product_id": product.productIdentifier,
            "price": product.price.stringValue,
            "currency": product.priceLocale.currencyCode ?? "",
        ]
        
        var extra: [String: Any] = [
            "acquisition_source": acquisitionSource,
            "acquisition_date": Int(info.acquisitionDate.timeIntervalSince1970),
            "ad_campaign": info.adCampaign,
            "ad_group": info.adGroup,
            "ad_creative": info.adCreative,
            "vendor_id": UIDevice.current.identifierForVendor?.uuidString ?? "",
            "appsflyer_id": info.appsFlyerId,
            "appmetrica_device_id": info.appmetricaId,
            "amplitude_device_id": info.amplitudeId,
            "adjust_raw": info.adjustRaw,
            "appsflyer_raw": info.appsFlyerRaw,
            "searchads_raw": info.searchAdsRaw,
            "branch_raw": info.branchRaw
        ]
        
        for (field, value) in info.extra {
            extra[field] = value
        }
        
        let params: [String: Any?] = [
            "bundle_id": Bundle.main.bundleIdentifier ?? "",
            "afi": afi,
            "receipt": receipt,
            "iap": iap,
            "country": product.priceLocale.regionCode ?? "",
            "extra": extra,
            "api_key": APIKey
        ]
        
        requestToServer(params: params, endPoint: endPoint)
    }
    
    private func requestToServer(params: [String: Any?], endPoint: EndPoints) {
        
        var request = URLRequest(url: URL(string: urlRequest + endPoint.rawValue)!)
        request.httpMethod = "POST"
        request.httpBody = try! JSONSerialization.data(withJSONObject: params)
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        URLSession.shared.dataTask(with: request) { data, resp, error in
            guard let data = data, let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
                return
            }
            print(json)
        }.resume()
    }
}

extension UserAcquisition {
    public var isConversionUser: Bool {
        if case .organic = UserAcquisition.shared.conversionInfo.acquisitionSource {
            return false
        } else {
            return true
        }
    }
}

extension UserAcquisition {
    public struct Info {
        enum AcquisitionSource {
            case organic, facebook, searchAds, custom(String)
        }
        var userId: String?
        var acquisitionSource: AcquisitionSource = .organic
        var acquisitionDate = Date()
        var adCampaign = ""
        var adGroup = ""
        var adCreative = ""
        public var appsFlyerId = ""
        public var appmetricaId = ""
        public var amplitudeId = ""
        var adjustRaw = ""
        var appsFlyerRaw = ""
        var searchAdsRaw = ""
        var branchRaw = ""
        var extra = [String: Any]()

        public mutating func setAppsFlyerData(_ appsFlyerData: [String: Any]) {
            if let jsonData = try? JSONSerialization.data(withJSONObject: appsFlyerData, options: .prettyPrinted) {
                self.appsFlyerRaw = String(data: jsonData, encoding: .utf8) ?? ""
            }
            
            let status = appsFlyerData["af_status"] as? String ?? ""
            let source = appsFlyerData["media_source"] as? String ?? ""
            let campaign = appsFlyerData["campaign"] as? String ?? ""
            let campaignId = appsFlyerData["campaign_id"] as? String ?? ""
            let adSet = appsFlyerData["adset"] as? String ?? ""
            let adSetId = appsFlyerData["adset_id"] as? String ?? ""
            let ad = appsFlyerData["ad"] as? String ?? ""
            let adId = appsFlyerData["ad_id"] as? String ?? ""
            print(appsFlyerData)
            var acquisitionSource: UserAcquisition.Info.AcquisitionSource {
                switch status {
                case "Non-organic":
                    switch source {
                    case "Facebook Ads":
                        return .facebook
                    default:
                        return .custom(source)
                    }
                case "Organic":
                    return .organic
                default:
                    return .custom("Undefined")
                }
            }
            var acquisitionDate: Date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-DD mm:HH:ss.SSS"
                return formatter.date(from: appsFlyerData["install_time"] as? String ?? "") ?? Date()
            }
            func merged(_ str1: String, _ str2: String) -> String {
                if str2 == "" {
                    return str1
                } else {
                    return "\(str1) (\(str2))"
                }
            }
            self.acquisitionSource = acquisitionSource
            self.acquisitionDate = acquisitionDate
            self.adCampaign = merged(campaign, campaignId)
            self.adGroup = merged(adSet, adSetId)
            self.adCreative = merged(ad, adId)
        }
        
        public mutating func setAdjustData(_ adjustData: [String: Any]) {
            if let jsonData = try? JSONSerialization.data(withJSONObject: adjustData, options: .prettyPrinted) {
                self.adjustRaw = String(data: jsonData, encoding: .utf8) ?? ""
            }
        }
        
        public mutating func setSearchAds(_ searchAdsData: [String: NSObject]){
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: searchAdsData, options: .prettyPrinted){
                self.searchAdsRaw = String(data: jsonData, encoding: .utf8) ?? ""
            }
        }
        
        public mutating func setBranch(_ branchData: [String: Any]){
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: branchData, options: .prettyPrinted){
                self.branchRaw = String(data: jsonData, encoding: .utf8) ?? ""
            }
        }
    }
}
