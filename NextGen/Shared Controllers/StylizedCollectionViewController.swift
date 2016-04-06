//
//  StylizedCollectionViewController.swift
//  NextGen
//
//  Created by Alec Ananian on 3/19/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit

class StylizedCollectionViewController: UICollectionViewController {
    
    // MARK: View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.addTitleStyling()
        
        let backgroundImageView = UIImageView(image: UIImage(named: "MOSExtrasBackground"))
        backgroundImageView.contentMode = UIViewContentMode.ScaleAspectFill
        self.collectionView!.backgroundView = backgroundImageView
    }
    
}
