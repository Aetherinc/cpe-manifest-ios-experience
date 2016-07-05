//
//  MenuSectionCell.swift
//

import UIKit
import QuartzCore

class MenuSectionCell: UITableViewCell {
    
    static let NibName = "MenuSectionCell"
    static let ReuseIdentifier = "MenuSectionCellReuseIdentifier"
    
    @IBOutlet weak var primaryLabel: UILabel!
    @IBOutlet weak var secondaryLabel: UILabel?
    @IBOutlet weak var dropDownImageView: UIImageView!
    
    var menuSection: MenuSection? {
        didSet {
            primaryLabel.text = menuSection?.title
            dropDownImageView.hidden = (menuSection == nil || !menuSection!.expandable)
        }
    }
    
    var selectedItem: MenuItem? {
        didSet {
            secondaryLabel?.text = selectedItem?.title
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        menuSection = nil
        selectedItem = nil
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let section = menuSection {
            dropDownImageView.transform = CGAffineTransformMakeRotation(section.expanded ? CGFloat(-M_PI) : 0.0)
        }
        
        updateCellStyle()
    }
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        updateCellStyle()
    }
    
    func updateCellStyle() {
        primaryLabel.textColor = self.selected ? UIColor.themePrimaryColor() : UIColor.whiteColor()
    }
    
    func toggleDropDownIcon() {
        if let section = menuSection {
            let rotate = CABasicAnimation(keyPath: "transform.rotation.z")
            rotate.fromValue = section.expanded ? 0.0 : CGFloat(-M_PI)
            rotate.toValue = section.expanded ? CGFloat(-M_PI) : 0.0
            rotate.duration = 0.25
            rotate.autoreverses = true
            rotate.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            dropDownImageView.layer.addAnimation(rotate, forKey: nil)
        }
    }
    
}