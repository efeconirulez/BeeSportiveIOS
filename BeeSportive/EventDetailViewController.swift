//
//  EventDetailViewController.swift
//  BeeSportive
//
//  Created by Efe Helvaci on 30.08.2016.
//  Copyright © 2016 BeeSportive. All rights reserved.
//

import UIKit
import Firebase

class EventDetailViewController: UIViewController {
    
    @IBOutlet var descriptionLabelHeightConstraint: NSLayoutConstraint!
    @IBOutlet var eventNameLabel: UILabel!
    @IBOutlet var eventDescriptionLabel: UILabel!
    @IBOutlet var eventBrancImage: UIImageView!
    @IBOutlet var eventAddressLabel: UILabel!
    @IBOutlet var eventDateLabel: UILabel!
    
    internal var event : Event?
    let font = UIFont(name: "Helvetica", size: 15.0)

    override func viewDidLoad() {
        super.viewDidLoad()

        setPageOutlets()
        
        // If visitor is creator or not
        if event?.creatorID == FIRAuth.auth()?.currentUser?.uid {
            
        } else {
            
        }
    }

    func setPageOutlets () {
        eventNameLabel.text = event!.name
        descriptionLabelHeightConstraint.constant = heightForView(event!.description, font: font!, width: UIScreen.mainScreen().bounds.size.width-40)
        eventDescriptionLabel.text = event!.description
        eventBrancImage.image = UIImage(named: event!.branch)
        eventAddressLabel.text = event!.location
        eventDateLabel.text = event!.day + "/" + event!.month + "/" + event!.year + "  " + event!.time
    }
    
    func heightForView(text:String, font:UIFont, width:CGFloat) -> CGFloat{
        let label:UILabel = UILabel(frame: CGRectMake(0, 0, width, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = font
        label.text = text
        
        label.sizeToFit()
        return label.frame.height
    }
}
