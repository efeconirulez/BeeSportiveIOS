//
//  ChatVC.swift
//  BeeSportive
//
//  Created by Doruk Gezici on 30/08/2016.
//  Copyright © 2016 BeeSportive. All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController

class ChatVC: JSQMessagesViewController {
    
    var channelID: String!
    var messages = [JSQMessage]()
    let dateFormatter = DateFormatter()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyScrollsToMostRecentMessage = true
        self.senderId = FIRAuth.auth()?.currentUser?.uid
        self.senderDisplayName = FIRAuth.auth()?.currentUser?.displayName
        
        // Getting messages and users one by one
        REF_CHANNELS.child(channelID).child("messages").observe(.childAdded, with: { snapshot in
            guard let data = snapshot.value as? Dictionary<String, String> else { return }
            
            let senderID = data["senderId"]!
            self.dateFormatter.dateFormat = "HH.mm - dd.M.yy"
            var messageDate = self.dateFormatter.date(from: data["date"]!)
            
            if messageDate == nil {
                messageDate = Date()
            }
            
            REF_USERS.child(senderID).child("displayName").observeSingleEvent(of: .value, with: { (snapshot) in
                let displayName = snapshot.value as! String
                self.addMessage(data["message"]!, senderId: senderID, senderDisplayName: displayName, date: messageDate!)
            })
        })
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        let tabBarCont = tabBarController as! TabBarController
        tabBarCont.menuButton.isHidden = true
        tabBarCont.tabBar.isHidden = true
        
    }
    
    // MARK: - Collection View Delegate Methods:
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            cell.textView!.textColor = UIColor.white
        } else {
            cell.textView!.textColor = UIColor.black
        }
        return cell
    }
    
    // MARK: - JSQMessages Methods
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let factory = JSQMessagesBubbleImageFactory()
        let outgoingBubbleImage = factory?.outgoingMessagesBubbleImage(with: primaryButtonColor)
        let incomingBubbleImage = factory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        let message = messages[indexPath.item]
        
        if message.senderId == senderId {
            return outgoingBubbleImage
        } else {
            return incomingBubbleImage
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        
        let name = messages[indexPath.row].senderDisplayName
        let components = name?.components(separatedBy: " ")
        var initials = ""
        for component in components! {
            initials += String(component.characters.first!).capitalized
        }
        let factory = JSQMessagesAvatarImageFactory.self
        return factory.avatarImage(withUserInitials: initials, backgroundColor: UIColor.gray, textColor: UIColor.white, font: UIFont.systemFont(ofSize: 12), diameter: 30)
        
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        
        dateFormatter.dateFormat = "HH.mm - dd.M.yy"
        
        let formattedDate = dateFormatter.string(from: Date())
        
        let dict: Dictionary<String, String> = [
            "message":text,
            "senderId":senderId,
            "date":formattedDate
        ]
        REF_CHANNELS.child(channelID).child("messages").childByAutoId().setValue(dict)
        REF_CHANNELS.child(channelID).child("lastMessage").setValue(dict)
        finishSendingMessage(animated: true)
        
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapAvatarImageView avatarImageView: UIImageView!, at indexPath: IndexPath!) {
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat {
        return 20
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        return NSAttributedString(string: messages[indexPath.row].senderDisplayName)
    }
    
    // MARK: - JSQMessages Data Creation Methods
    func buildLocationItem() -> JSQLocationMediaItem {
        
        let ferryBuildingInSF = CLLocation(latitude: 37.795313, longitude: -122.393757)
        let locationItem = JSQLocationMediaItem()
        locationItem.setLocation(ferryBuildingInSF) {
            self.collectionView!.reloadData()
        }
        return locationItem
        
    }
    
    func addMedia(_ media:JSQMediaItem) {
        
        let message = JSQMessage(senderId: senderId, displayName: senderDisplayName, media: media)
        self.messages.append(message!)
        self.finishSendingMessage(animated: true)
        
    }
    
    func addMessage(_ text: String, senderId: String, senderDisplayName: String, date: Date) {
        
        let message = JSQMessage(senderId: senderId, senderDisplayName: senderDisplayName, date: date, text: text)
        messages.append(message!)
        self.collectionView.reloadData()
        finishReceivingMessage(animated: true)
        
    }
    
}
