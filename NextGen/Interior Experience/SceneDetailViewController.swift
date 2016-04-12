//
//  SceneDetailViewController.swift
//  NextGen
//
//  Created by Alec Ananian on 4/5/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit

class SceneDetailViewController: UIViewController {
    
    let kViewMargin: CGFloat = 30
    let kTitleLabelHeight: CGFloat = 70
    let kCloseButtonWidth: CGFloat = 110
    
    var experience: NGDMExperience!
    
    var titleLabel: UILabel!
    var closeButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.blackColor()
        
        titleLabel = UILabel()
        titleLabel.font = UIFont(name: "Roboto Condensed", size: 25)!
        titleLabel.textColor = UIColor.whiteColor()
        self.view.addSubview(titleLabel)
        
        closeButton = UIButton(type: UIButtonType.Custom)
        closeButton.titleLabel?.font = UIFont(name: "Roboto Condensed", size: 17)!
        closeButton.setTitle(String.localize("label.close"), forState: UIControlState.Normal)
        closeButton.setImage(UIImage(named: "Close"), forState: UIControlState.Normal)
        closeButton.contentEdgeInsets = UIEdgeInsetsMake(0, -35, 0, 0)
        closeButton.titleEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 25)
        closeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 110, 0, 0)
        closeButton.addTarget(self, action: #selector(SceneDetailViewController.close), forControlEvents: UIControlEvents.TouchUpInside)
        self.view.addSubview(closeButton)
        
        if let title = experience.metadata?.title {
            titleLabel.text = title.uppercaseString
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let viewWidth = CGRectGetWidth(self.view.frame)
        titleLabel.frame = CGRectMake(kViewMargin, 0, viewWidth - (2 * kViewMargin), kTitleLabelHeight)
        closeButton.frame = CGRectMake(viewWidth - kCloseButtonWidth - kViewMargin, 0, kCloseButtonWidth, kTitleLabelHeight)
        
        sendPauseNotification()
    }
    
    func sendPauseNotification() {
        NSNotificationCenter.defaultCenter().postNotificationName(VideoPlayerNotification.ShouldPause, object: nil)
    }
    
    // MARK: Actions
    func close() {
        NSNotificationCenter.defaultCenter().postNotificationName(VideoPlayerNotification.ShouldResume, object: nil)
        self.dismissViewControllerAnimated(true, completion: nil)
    }

}
