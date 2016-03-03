//
//  SettingsCell.swift
//  NextGen
//
//  Created by Sedinam Gadzekpo on 2/11/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit
import DLRadioButton

class SettingsCell: UITableViewCell{
    
    
    @IBOutlet weak var cellSetting: UILabel!
    @IBOutlet weak var currentSetting: UILabel!

    @IBOutlet weak var subtitle: UILabel!
    @IBOutlet weak var radioBtn: RadioButton!

    
    
   
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        if (selected){
            

            self.radioBtn.selected = true
               
            
        } else {

            self.radioBtn.selected = false

            
        }


    }

 }
