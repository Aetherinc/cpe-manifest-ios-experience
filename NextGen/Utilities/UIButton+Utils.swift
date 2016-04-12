//
//  UIButton+Utils.swift
//  NextGen
//
//  Created by Alec Ananian on 2/5/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit

extension UIButton {
    
    static func buttonWithImage(image: UIImage!) -> UIButton {
        let button = UIButton(type: .Custom)
        button.setImage(image, forState: .Normal)
        return button
    }
    
}