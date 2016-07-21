//
//  RiderViewController.swift
//  ParseStarterProject-Swift
//
//  Created by Guilherme Viteri on 15/07/2016.
//  Copyright © 2016 Parse. All rights reserved.
//

import UIKit
import Parse
import MapKit

@available(iOS 8.0, *)
class RiderViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var locationManager:CLLocationManager!
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    
    var riderRequestActive = false
    var driverOnTheWay = false
    
    @IBOutlet var map: MKMapView!
    @IBOutlet var callUberButton: UIButton!
    
    @IBAction func callUber(sender: AnyObject) {
        
        if riderRequestActive == false {
            
            let riderRequest = PFObject(className:"riderRequest")
            riderRequest["username"] = PFUser.currentUser()?.username
            riderRequest["location"] = PFGeoPoint(latitude:latitude, longitude:longitude)
            
            riderRequest.saveInBackgroundWithBlock {
                (success: Bool, error: NSError?) -> Void in
                if (success) {
                    // The object has been saved.
                    self.callUberButton.setTitle("Cancel Uber", forState: UIControlState.Normal)
                    
                    
                    
                } else {
                    // There was a problem, check error.description
                    
                    let alert = UIAlertController(title: "Could not call Uber", message: "Please try again", preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
                    self.presentViewController(alert, animated: true, completion: nil)
                    
                }
            }
            
            riderRequestActive = true
            
        } else {
            
            riderRequestActive = false
            
            self.callUberButton.setTitle("Call an Uber", forState: UIControlState.Normal)
            
            let query = PFQuery(className:"riderRequest")
            query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
            
            query.findObjectsInBackgroundWithBlock {
                (objects: [PFObject]?, error: NSError?) -> Void in
                
                if error == nil {
                    print("Successfully retrieved \(objects!.count) scores.")
                    
                    // Do something with the found objects
                    if let objects = objects {
                        for object in objects {
                            object.deleteInBackground()
                        }
                    }
                } else {
                    
                    print("Error: \(error!) \(error!.userInfo)")
                }
            }
            
        }
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        //map.showsUserLocation = true
    }
    
    @IBOutlet var callUber: UIButton!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "logoutRider" {
            PFUser.logOut()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocationCoordinate2D = manager.location!.coordinate
        
        self.latitude = location.latitude
        self.longitude = location.longitude
        
        let query = PFQuery(className:"riderRequest")
        query.whereKey("username", equalTo: PFUser.currentUser()!.username!)
        query.findObjectsInBackgroundWithBlock {
            (objects: [PFObject]?, error: NSError?) -> Void in
            
            if error == nil {
                //print("Successfully retrieved \(objects!.count) scores.")
                
                // Do something with the found objects
                if let objects = objects {
                    
                    for object in objects {
                        
                        if let driverUsername = object["driverResponded"] {
                            //self.callUberButton.setTitle("Driver is on the way", forState: UIControlState.Normal)
                            
                            let query = PFQuery(className:"driverLocation")
                            query.whereKey("username", equalTo:driverUsername)
                            query.findObjectsInBackgroundWithBlock {
                                (objects: [PFObject]?, error: NSError?) -> Void in
                                
                                if error == nil {
                                    //print("Successfully retrieved \(objects!.count) scores.")
                                    
                                    // Do something with the found objects
                                    if let objects = objects {
                                        
                                        for object in objects {
                                            
                                            if let driverLocation = object["driverLocation"] as? PFGeoPoint {
                                                let driveCLLocation = CLLocation(latitude: driverLocation.latitude, longitude: driverLocation.longitude)
                                                
                                                let userCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                                                
                                                let distanceMeters = userCLLocation.distanceFromLocation(driveCLLocation)
                                                let distanceKM = distanceMeters / 1000
                                                let roundedTwoDigit = Double(round(distanceKM * 10) / 10)
                                                
                                                
                                                self.callUberButton.setTitle("Driver is \(roundedTwoDigit)km away", forState: UIControlState.Normal)
                                                
                                                
                                                self.driverOnTheWay = true
                                                
                                                let center = CLLocationCoordinate2D(latitude:location.latitude, longitude: location.longitude)
                                                
                                                let latDelta = abs(driverLocation.latitude - location.latitude) * 2 + 0.009
                                                
                                                let longDelta = abs(driverLocation.longitude - location.longitude) * 2 + 0.009
                                                
                                                let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: longDelta))
                                                
                                                self.map.setRegion(region, animated: true)
                                                
                                                self.map.removeAnnotations(self.map.annotations)
                                                
                                                var pinLocation: CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                                                var objectAnnotation = MKPointAnnotation()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Current Location"
                                                self.map.addAnnotation(objectAnnotation)
                                                
                                                pinLocation = CLLocationCoordinate2DMake(driverLocation.latitude, driverLocation.longitude)
                                                objectAnnotation = MKPointAnnotation()
                                                objectAnnotation.coordinate = pinLocation
                                                objectAnnotation.title = "Driver Location"
                                                self.map.addAnnotation(objectAnnotation)
                                                
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        //print("locations = \(location.latitude) \(location.longitude)")
        if driverOnTheWay == false{
            let center = CLLocationCoordinate2D(latitude:location.latitude, longitude: location.longitude)
            let region = MKCoordinateRegion(center: center, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
            
            self.map.setRegion(region, animated: true)
            
            self.map.removeAnnotations(map.annotations)
            
            let pinLocation : CLLocationCoordinate2D = CLLocationCoordinate2DMake(location.latitude, location.longitude)
            let objectAnnotation = MKPointAnnotation()
            objectAnnotation.coordinate = pinLocation
            objectAnnotation.title = "Current Location"
            self.map.addAnnotation(objectAnnotation)
        }
        
    }
}
