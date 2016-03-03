//
//  FilmCollectionViewCell.swift
//  NextGen
//
//  Created by Alec Ananian on 1/14/16.
//  Copyright © 2016 Warner Bros. Entertainment, Inc. All rights reserved.
//

import UIKit

class FilmCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    
    var film: Film? = nil {
        didSet {
            if film?.posterImageURL != nil {
                imageView.setImageWithURL(film!.posterImageURL!)
            } else {
                imageView.image = nil
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        film = nil
    }
    
}
