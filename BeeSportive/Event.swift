//
//  Event.swift
//  BeeSportive
//
//  Created by Efe Helvaci on 16.08.2016.
//  Copyright © 2016 BeeSportive. All rights reserved.
//

import Foundation
import Firebase

class Event {
    let id : String
    let creatorID : String
    let name : String
    let branch : String
    let level : String
    let location : String
    let locationLat : String
    let locationLon : String
    let maxJoinNumber : String
    let description : String
    let month : String
    let time : String
    let day : String
    let year : String
    var participants : Dictionary<String, AnyObject>? = nil
    var requesters : Dictionary<String, AnyObject>? = nil
    var creator : User? = nil
    var address : String? = nil
    
    init(creatorID: String, creatorImageURL: String, creatorName: String, name: String, branch: String, level: String, location: String, locationLat: String, locationLon : String, maxJoinNumber: String, description : String, time: String, month: String, day: String, year: String, id: String){
        self.creatorID = creatorID
        self.name = name
        self.branch = branch
        self.level = level
        self.location = location
        self.locationLat = locationLat
        self.locationLon = locationLon
        self.maxJoinNumber = maxJoinNumber
        self.description = description
        self.time = time
        self.day = day
        self.month = month
        self.year = year
        self.id = id
    }
    
    init(snapshot: FIRDataSnapshot) {
        let data = snapshot.value as! Dictionary<String, AnyObject>
        
        self.id = data["id"] as! String
        self.creatorID = data["creatorID"] as! String
        self.name = data["name"] as! String
        self.branch = data["branch"] as! String
        self.level = data["level"] as! String
        self.location = data["location"] as! String
        self.locationLat = data["locationLat"] as! String
        self.locationLon = data["locationLon"] as! String
        self.maxJoinNumber = data["maxJoinNumber"] as! String
        self.description = data["description"] as! String
        self.time = data["time"] as! String
        self.month = data["month"] as! String
        self.day = data["day"] as! String
        self.year = data["year"] as! String
        
        if let addrss = data["address"] as? String {
            self.address = addrss
        }
        
        if let prtcpnts = data["participants"] as? Dictionary<String, AnyObject> {
            self.participants = prtcpnts
        }
        
        if let rqstrs = data["requested"] as? Dictionary<String, AnyObject> {
            self.requesters = rqstrs
        }
        
        REF_USERS.child(creatorID).observeSingleEvent(of: .value, with: { snapshot2 in
            if snapshot2.exists() {
                self.creator = User(snapshot: snapshot2)
            }
        })
    }
}
