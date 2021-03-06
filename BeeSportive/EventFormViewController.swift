//
//  EventFormViewController.swift
//  BeeSportive
//
//  Created by Efe Helvaci on 3.09.2016.
//  Copyright © 2016 BeeSportive. All rights reserved.
//

import UIKit
import CoreLocation
import Firebase
import FTIndicator
import MapKit
import Eureka
import SDCAlertView

class EventFormViewController: FormViewController, CLLocationManagerDelegate {

    let locationManager = CLLocationManager()
    var createEventAlert : AlertController!
    var timesToLocateAccurate = 10
    var location : CLLocation? {
        didSet{
            self.form.rowBy(tag: "LocationPin")?.baseValue = location
            self.form.rowBy(tag: "LocationPin")?.reload()
            
            timesToLocateAccurate = timesToLocateAccurate - 1
            
            if timesToLocateAccurate <= 0 {
                locationManager.stopUpdatingLocation()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.layoutIfNeeded()
        
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        
        let backButton = UIBarButtonItem()
        backButton.title = ""
        navigationItem.backBarButtonItem = backButton
        
        createEventAlert = AlertController(title: "Are you sure?", message: "You won't be able to change or delete event afterwards. Check everything before creating event.")
        createEventAlert.add(AlertAction(title: "Cancel", style: .destructive, handler: {_ in
            self.createEventAlert.dismiss()
        }))
        createEventAlert.add(AlertAction(title: "Create", style: .preferred, handler: { _ in
            if self.checkIfAttributesRight() {
                self.createEvent()
            }
        }))
        
        LabelRow.defaultCellUpdate = { cell, row in cell.detailTextLabel?.textColor = .orange  }
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(named: "Back"), style: .plain, target: self, action: #selector(back))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(areYouSureAlert))
        
        form =

        form +++ Section("MAIN DETAILS")
                <<< TextRow(){ row in
                    row.placeholder = "Event name (Max. 60 characters)"
                    row.tag = "Name"
                }
                <<< TextAreaRow() {
                    $0.placeholder = "Description (Max. 800 characters)"
                    $0.textAreaHeight = .dynamic(initialTextViewHeight: 80)
                    $0.tag = "Description"
                }

            +++ Section("When & Where & What")
                <<< DateRow(){
                    $0.title = "Date"
                    $0.value = Date()
                    $0.tag = "Date"
                }
                <<< TimeInlineRow(){
                        $0.title = "Time"
                        $0.value = Date()
                        $0.tag = "Time"
                    }
                <<< LocationRow(){
                        $0.value = CLLocation(latitude: 41.015137, longitude: 28.979530)
                        $0.title = "Location Pin"
                    
                        $0.tag = "LocationPin"
                    }
                <<< TextRow(){ row in
                        row.title = "Location name"
                        row.placeholder = "Ex. Central Park"
                        row.tag = "LocationName"
                    }
                <<< AlertRow<String>() {
                        $0.title = "Level"
                        $0.options = levels
                        $0.value = "Not chosen"
                        $0.tag = "Level"
                        }
                <<< AlertRow<String>() {
                        $0.title = "Branch"
                        $0.selectorTitle = "Branchs"
                        $0.options = branchs
                        $0.value = "Not chosen"
                        $0.tag = "Branch"
                        }
                <<< IntRow() {
                        $0.title = "Max. Attendees"
                        $0.placeholder = "1 ~ 100"
                        $0.tag = "MaxJoin"
                    }
            +++ Section()
            <<< ButtonRow("Add Event") { row in
                row.title = row.tag
            }.onCellSelection({ [weak self] (cell, row) in
                self?.areYouSureAlert()
            })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let locValue:CLLocationCoordinate2D = manager.location!.coordinate
        
        self.location = CLLocation(latitude: locValue.latitude, longitude: locValue.longitude)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Error while updating location " + error.localizedDescription)
    }
    
    func back() {
        dismiss(animated: true, completion: nil)
    }
    
    func createEvent() {
        
        if let name = self.form.rowBy(tag: "Name")?.baseValue as? String,
            let description = self.form.rowBy(tag: "Description")?.baseValue as? String,
            let date = self.form.rowBy(tag: "Date")?.baseValue as? Date,
            let time = self.form.rowBy(tag: "Time")?.baseValue as? Date,
            let locationPin = self.form.rowBy(tag: "LocationPin")?.baseValue as? CLLocation,
            let locationName = self.form.rowBy(tag: "LocationName")?.baseValue as? String,
            let level = self.form.rowBy(tag: "Level")?.baseValue as? String,
            let branch = self.form.rowBy(tag: "Branch")?.baseValue as? String,
            let maxJoin = self.form.rowBy(tag: "MaxJoin")?.baseValue as? Int
        {
            FTIndicator.showProgressWithmessage("Adding your event!", userInteractionEnable: false)
            
            var locationAddress = ""
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(locationPin, completionHandler: { (placemark, error) in
                if error != nil {
                    print("Error getting location address")
                } else {
                    let placemrk = placemark?.last
                    locationAddress = (placemrk?.addressDictionary!["FormattedAddressLines"] as! [String]).joined(separator: " ")
                }
                
                let dateFormatter = DateFormatter()
                
                dateFormatter.dateFormat = "dd.M.yyyy"
                let fullDate = dateFormatter.string(from: date)
                
                dateFormatter.dateFormat = "HH:mm"
                let hour = dateFormatter.string(from: time)
                
                let uuid = UUID().uuidString
                
                let newEvent = [
                    "id" : uuid,
                    "creatorID" : (FIRAuth.auth()?.currentUser?.uid)!,
                    "name" : name,
                    "branch" : branch,
                    "location" : locationName,
                    "locationLat" : String(locationPin.coordinate.latitude),
                    "locationLon" : String(locationPin.coordinate.longitude),
                    "address" : locationAddress,
                    "fullDate" : fullDate,
                    "time" : hour,
                    "maxJoinNumber" : String(maxJoin),
                    "level" : level,
                    "description" : description
                ] as [String : Any]
                
                REF_EVENTS.child(uuid).setValue(newEvent)
                REF_USERS.child((FIRAuth.auth()?.currentUser?.uid)!).child("eventsCreated").childByAutoId().setValue(uuid)
                
                FTIndicator.showNotification(with: UIImage(named: "Success"), title: "Yay!", message: "Event successfully created!")
                FTIndicator.dismissProgress()
                self.view.isUserInteractionEnabled = true
                self.dismiss(animated: true, completion: { _ in

                        self.form.rowBy(tag: "Name")?.baseValue = ""
                        self.form.rowBy(tag: "Name")?.reload()
                        
                        self.form.rowBy(tag: "Description")?.baseValue = ""
                        self.form.rowBy(tag: "Description")?.reload()
                        
                        self.form.rowBy(tag: "LocationName")?.baseValue = ""
                        self.form.rowBy(tag: "LocationName")?.reload()
                        
                        self.form.rowBy(tag: "MaxJoin")?.baseValue = 10
                        self.form.rowBy(tag: "MaxJoin")?.reload()
                    
                        self.form.rowBy(tag: "Level")?.baseValue = "Not chosen"
                        self.form.rowBy(tag: "Level")?.reload()
                    
                        self.form.rowBy(tag: "Branch")?.baseValue = "Not chosen"
                        self.form.rowBy(tag: "Branch")?.reload()
                    
                        self.form.rowBy(tag: "Date")?.baseValue = Date()
                        self.form.rowBy(tag: "Date")?.reload()
                })
            })
        } else {
            FTIndicator.showInfo(withMessage: "You must fill all the areas!")
        }
    }
    
    func checkIfAttributesRight() -> Bool {
        if let name = self.form.rowBy(tag: "Name")?.baseValue as? String,
            let description = self.form.rowBy(tag: "Description")?.baseValue as? String,
            var date = self.form.rowBy(tag: "Date")?.baseValue as? Date,
            let locationName = self.form.rowBy(tag: "LocationName")?.baseValue as? String,
            let level = self.form.rowBy(tag: "Level")?.baseValue as? String,
            let branch = self.form.rowBy(tag: "Branch")?.baseValue as? String,
            let maxJoin = self.form.rowBy(tag: "MaxJoin")?.baseValue as? Int
        {
            let currentDate = Date()
            
            date = date.addHours(hoursToAdd: 1) as Date
            if date.isLessThanDate(dateToCompare: currentDate){
                FTIndicator.showInfo(withMessage: "Cannot create event to past time.")
                return false
            }
            
            if maxJoin > 100 {
                FTIndicator.showInfo(withMessage: "Cannot create event for more than 100 people.")
                return false
            } else if maxJoin < 1 {
                FTIndicator.showInfo(withMessage: "Cannot create event for less than 1 person")
                return false
            }
            
            if currentDate.addDays(daysToAdd: 90) < date {
                FTIndicator.showInfo(withMessage: "Cannot create event for >3 months later.")
                return false
            }
            
            if description.characters.count < 10 {
                FTIndicator.showInfo(withMessage: "Event description too short (Minimum 10 characters)")
                return false
            } else if description.characters.count > 800 {
                FTIndicator.showInfo(withMessage: "Event description too long (Maximum 800 characters)")
                return false
            }
            
            if name.characters.count < 8 {
                FTIndicator.showInfo(withMessage: "Event name too short (Minimum 8 characters)")
                return false
            } else if name.characters.count > 60 {
                FTIndicator.showInfo(withMessage: "Event name too long (Maximum 60 characters)")
                return false
            }
            
            if locationName.characters.count < 4 {
                FTIndicator.showInfo(withMessage: "Location name too short (Minimum 4 characters)")
                return false
            } else if locationName.characters.count > 30 {
                FTIndicator.showInfo(withMessage: "Event name too long (Maximum 30 characters)")
                return false
            }
            
            if !branchs.contains(branch) {
                FTIndicator.showInfo(withMessage: "Unknown branch!")
                return false
            }
            
            if !levels.contains(level) {
                FTIndicator.showInfo(withMessage: "Unknown level!")
                return false
            }
            
            return true
        } else {
            FTIndicator.showInfo(withMessage: "You must fill all the areas!")
            return false
        }
    }
    
    func areYouSureAlert() {
        if checkIfAttributesRight() {
            self.createEventAlert.present()
        }
    }
}
