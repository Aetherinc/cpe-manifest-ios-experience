//
//  SharingViewController.swift
//  NextGen
//
//  Created by Sedinam Gadzekpo on 3/1/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit



class SharingViewController: UIViewController{
    
        override func viewDidLoad() {
        
        super.viewDidLoad()
    
       NSNotificationCenter.defaultCenter().postNotificationName(kVideoPlayerShouldPause, object: nil)
      
                        }
    

    
    @IBAction func close(sender: AnyObject) {
        
        NSNotificationCenter.defaultCenter().postNotificationName(kVideoPlayerShouldResume, object: nil)
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
}