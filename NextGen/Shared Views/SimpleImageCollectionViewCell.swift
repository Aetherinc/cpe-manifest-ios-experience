//
//  SimpleImageCollectionViewCell.swift
//

import UIKit

class SimpleImageCollectionViewCell: UICollectionViewCell {
    
    static let BaseReuseIdentifier = "SimpleImageCollectionViewCellReuseIdentifier"
    
    @IBOutlet weak private var imageView: UIImageView!
    @IBOutlet weak private var playButton: UIButton?
    
    private var setImageSessionDataTask: NSURLSessionDataTask?
    
    var showsSelectedBorder = false
    
    var imageURL: NSURL? {
        set {
            if let task = setImageSessionDataTask {
                task.cancel()
                setImageSessionDataTask = nil
            }
            
            if let url = newValue {
                imageView.af_setImageWithURL(url)
            } else {
                imageView.af_cancelImageRequest()
                imageView.image = nil
            }
        }
        
        get {
            return nil
        }
    }
    
    var playButtonVisible: Bool {
        set {
            playButton?.hidden = !newValue
        }
        
        get {
            return playButton != nil && !playButton!.hidden
        }
    }
    
    override var selected: Bool {
        didSet {
            if self.selected && showsSelectedBorder {
                self.layer.borderWidth = 2
                self.layer.borderColor = UIColor.whiteColor().CGColor
            } else {
                self.layer.borderWidth = 0
                self.layer.borderColor = nil
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        self.selected = false
        
        imageURL = nil
        playButtonVisible = false
    }

}
