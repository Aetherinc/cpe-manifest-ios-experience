//
//  EnhancedTitlesCollectionViewController.swift
//  NextGen
//
//  Created by Sedinam Gadzekpo on 5/24/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit
import MBProgressHUD
import NextGenDataManager

class EnhancedTitlesCollectionViewCell: UICollectionViewCell {
    
    static let ReuseIdentifier = "EnhancedTitlesCollectionViewCellReuseIdentifier"
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        imageView.image = nil
        titleLabel.text = nil
    }
}

class EnhancedTitlesCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout {
    
    private struct Constants {
        static let CollectionViewItemSpacing: CGFloat = 12
        static let CollectionViewLineSpacing: CGFloat = 12
        static let CollectionViewPadding: CGFloat = 15
        static let CollectionViewItemAspectRatio: CGFloat = 135 / 240
    }
    
    override func viewDidLoad() {
        collectionView?.registerNib(UINib(nibName: String(EnhancedTitlesCollectionViewCell), bundle: nil), forCellWithReuseIdentifier: EnhancedTitlesCollectionViewCell.ReuseIdentifier)
    }
    
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Landscape
    }
    
    // MARK: UICollectionViewDataSource
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return NextGenDataLoader.ManifestData.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(EnhancedTitlesCollectionViewCell.ReuseIdentifier, forIndexPath: indexPath) as! EnhancedTitlesCollectionViewCell
        
        cell.titleLabel.text = NextGenDataLoader.ManifestData[indexPath.row]["title"]
        if let imageName = NextGenDataLoader.ManifestData[indexPath.row]["image"] {
            cell.imageView.image = UIImage(named: imageName)
        }
        
        return cell
    }
    
    // MARK: UICollectionViewDelegate
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        MBProgressHUD.showHUDAddedTo(self.view, animated: true)
        NextGenDataLoader.loadTitle(indexPath.row)
        
        let homeViewController = UIStoryboard.getNextGenViewController(HomeViewController)
        self.presentViewController(homeViewController, animated: true, completion: nil)
    }
    
    // MARK: UICollectionViewFlowLayoutDelegate
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let itemWidth: CGFloat = (CGRectGetWidth(collectionView.frame) / 4) - (Constants.CollectionViewItemSpacing * 2)
        return CGSizeMake(itemWidth, itemWidth / Constants.CollectionViewItemAspectRatio)
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return Constants.CollectionViewLineSpacing
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return Constants.CollectionViewItemSpacing
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(Constants.CollectionViewPadding, Constants.CollectionViewPadding, Constants.CollectionViewPadding, Constants.CollectionViewPadding)
    }
    
}
