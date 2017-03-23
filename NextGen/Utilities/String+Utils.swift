//
//  String+Utils.swift
//

import Foundation
import UIKit

extension String {
    
    func removeAll(_ characters: [Character]) -> String {
        return String(self.characters.filter({ !characters.contains($0) }))
    }
    
    func htmlDecodedString() -> String {
        if let encodedData = self.data(using: String.Encoding.utf8) {
            let attributedOptions : [String: AnyObject] = [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType as AnyObject, NSCharacterEncodingDocumentAttribute: String.Encoding.utf8 as AnyObject]
            do {
                let attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
                return attributedString.string
            } catch {
                print("Error decoding HTML string: \(error)")
                return self
            }
        }
        
        return self
    }
    
    static func localize(_ key: String) -> String {
        return NSLocalizedString(key, tableName: "NextGen", bundle: Bundle.main, value: "", comment: "")
    }
    
    static func localize(_ key: String, variables: [String: String?]) -> String {
        var localizedString = String.localize(key)
        for (variableName, variableValue) in variables {
            localizedString = localizedString.replacingOccurrences(of: "%{" + variableName + "}", with: (variableValue ?? ""))
        }
        
        return localizedString
    }
    
    static func localizePlural(_ singularKey: String, pluralKey: String, count: Int) -> String {
        return localize(count == 1 ? singularKey : pluralKey, variables: ["count": String(count)])
    }
    
    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
    subscript (i: Int) -> String {
        return String(self[i] as Character)
    }
    
    subscript (r: Range<Int>) -> String {
        let start = characters.index(startIndex, offsetBy: r.lowerBound)
        let end = index(start, offsetBy: r.upperBound - r.lowerBound)
        return self[start ..< end]
    }
    
}
