//
//  TheTakeProduct.swift
//

import Foundation
import CoreGraphics
import NextGenDataManager

class TheTakeProduct: NSObject, ProductItem {
    
    private struct Constants {
        static let ProductURLPrefix = "http://www.thetake.com/product/"
        
        struct Keys {
            static let ProductId = "productId"
            static let ProductName = "productName"
            static let ProductBrand = "productBrand"
            static let ProductPrice = "productPrice"
            static let ProductImages = "productImages"
            static let ProductImage = "productImage"
            static let ProductImageThumbnail = "500pxLink"
            static let CropImages = "cropImages"
            static let CropImage = "cropImage"
            static let CropImageThumbnail = "500pxCropLink"
            static let KeyFrameImage = "keyFrameImage"
            static let KeyFrameImageThumbnail = "500pxKeyFrameLink"
            static let ExactMatch = "verified"
            static let PurchaseLink = "purchaseLink"
            static let BullseyeCropX = "keyCropProductX"
            static let BullseyeCropY = "keyCropProductY"
            static let BullseyeKeyFrameX = "keyFrameProductX"
            static let BullseyeKeyFrameY = "keyFrameProductY"
        }
    }
    
    var externalID: String
    var name: String
    var brand: String?
    
    var price: Double?
    var displayPrice: String? {
        if let price = price {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.currencyCode = "USD"
            return formatter.string(from: NSNumber(value: price))
        }
        
        return nil
    }
    
    var productImageURL: URL?
    var sceneImageURL: URL?
    var hasExactMatchData = false
    var isExactMatch = false
    var externalURL: URL?
    var bullseyePoint = CGPoint.zero
    var shareText: String {
        var shareText = name
        if let externalURLString = externalURL?.absoluteString {
            shareText += " - " + externalURLString
        }
        
        return shareText
    }
    
    init(data: NSDictionary) {
        externalID = data[Constants.Keys.ProductId] as? String ?? NSUUID().uuidString
        name = data[Constants.Keys.ProductName] as? String ?? ""
        brand = data[Constants.Keys.ProductBrand] as? String
        if let priceString = data[Constants.Keys.ProductPrice] as? String {
            price = Double(priceString)
        }
        
        if let imagesData = data[Constants.Keys.ProductImages] as? [String: String] ?? data[Constants.Keys.ProductImage] as? [String: String], let imageString = imagesData[Constants.Keys.ProductImageThumbnail] {
            productImageURL = URL(string: imageString)
        }
        
        if let imagesData = data[Constants.Keys.KeyFrameImage] as? [String: String], let imageString = imagesData[Constants.Keys.KeyFrameImageThumbnail] {
            sceneImageURL = URL(string: imageString)
            
            if let x = data[Constants.Keys.BullseyeKeyFrameX] as? Double, let y = data[Constants.Keys.BullseyeKeyFrameY] as? Double {
                bullseyePoint = CGPoint(x: x, y: y)
            }
        } else if let imagesData = data[Constants.Keys.KeyFrameImage] as? [String: String] ?? data[Constants.Keys.CropImages] as? [String: String] ?? data[Constants.Keys.CropImage] as? [String: String], let imageString = imagesData[Constants.Keys.CropImageThumbnail] {
            sceneImageURL = URL(string: imageString)
            
            if let x = data[Constants.Keys.BullseyeCropX] as? Double, let y = data[Constants.Keys.BullseyeCropY] as? Double {
                bullseyePoint = CGPoint(x: x, y: y)
            }
        }
        
        if let verified = data[Constants.Keys.ExactMatch] as? Bool {
            isExactMatch = verified
            hasExactMatchData = true
        }
        
        if let purchaseLink = data[Constants.Keys.PurchaseLink] as? String , purchaseLink.characters.count > 0 {
            externalURL = URL(string: purchaseLink)
        } else {
            externalURL = URL(string: Constants.ProductURLPrefix + externalID)
        }
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let otherProduct = object as? TheTakeProduct {
            return (otherProduct.externalID == externalID)
        }
        
        return false
    }
    
}