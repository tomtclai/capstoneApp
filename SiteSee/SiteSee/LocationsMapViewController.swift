//
//  LocationsMapViewController.swift
//  SiteSee
//
//  Created by Tom Lai on 1/18/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class LocationsMapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    var annotation: VTAnnotation!
    var locationManager = CLLocationManager()
    var geocoder = CLGeocoder()
    
    @IBOutlet weak var locationButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("Fetch failed: \(error)")
        }
        locationManager.delegate = self
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotations(fetchedResultsController.fetchedObjects as! [MKAnnotation])
        
    }
    
    @IBAction func locationTapped(sender: UIBarButtonItem) {
        startTrackingLocation()
    }
    
    func startTrackingLocation() {
        switch CLLocationManager.authorizationStatus() {
        case .NotDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .Denied:
            presentViewController(UIAlertController(title: "Location Service is disabled", message: "Please enable location services for SiteSee from Settings > Privacy", preferredStyle: UIAlertControllerStyle.Alert), animated: true, completion: nil)
            
        case .Restricted:
            locationButton.enabled = false
        case .AuthorizedAlways, .AuthorizedWhenInUse:
            switch mapView.userTrackingMode {
            case .Follow, .FollowWithHeading:
                mapView.setUserTrackingMode(.None, animated: true)
            case .None:
                mapView.setUserTrackingMode(.Follow, animated: true)
            }
            
        }
    }
    @IBAction func segmentedControlTapped(sender: UISegmentedControl) {
        let Map = 0
        let Hybrid = 1
        let Satellite = 2
        switch(sender.selectedSegmentIndex){
        case Map:
            mapView.mapType = .Standard
        case Hybrid:
            mapView.mapType = .Hybrid
        case Satellite:
            mapView.mapType = .Satellite
        default:
            print("Wrong Index in segmented control")
        }
    }
    
    @IBAction func addButtonTapped(sender: UIBarButtonItem) {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: mapView.centerCoordinate.latitude, longitude: mapView.centerCoordinate.longitude)) { (placemarks, error) -> Void in
            if let placemark = placemarks?.first {
                var locationNames = self.locationNames(placemark, altitude:self.mapView.camera.altitude)
                var annotationDictionary : [String:AnyObject]
                annotationDictionary = [
                    VTAnnotation.Keys.Longitude : NSNumber(double: self.mapView.centerCoordinate.longitude),
                    VTAnnotation.Keys.Latitude : NSNumber(double: self.mapView.centerCoordinate.latitude),
                    VTAnnotation.Keys.Title : locationNames[0],
                    VTAnnotation.Keys.Page : NSNumber(integer: 1)
                ]
                if locationNames.count > 1 {
                    annotationDictionary[VTAnnotation.Keys.Subtitle] = locationNames[1]
                }
                dispatch_async(dispatch_get_main_queue()){
                    let _ = VTAnnotation(dictionary: annotationDictionary, context: self.sharedContext)
                    CoreDataStackManager.sharedInstance().saveContext()
                }
            }
        }

    }
    
    // MARK: - state restoration
    let mapViewLat = "MapViewLat"
    let mapViewLong = "MapViewLong"
    let mapViewSpanLatDelta = "MapViewSpanLatDelta"
    let mapViewSpanLongDelta = "MapViewSpanLongDelta"
    override func encodeRestorableStateWithCoder(coder: NSCoder) {
        super.encodeRestorableStateWithCoder(coder)
        coder.encodeDouble(mapView.region.center.latitude, forKey: mapViewLat)
        coder.encodeDouble(mapView.region.center.longitude, forKey: mapViewLong)
        coder.encodeDouble(mapView.region.span.latitudeDelta, forKey: mapViewSpanLatDelta)
        coder.encodeDouble(mapView.region.span.longitudeDelta, forKey: mapViewSpanLongDelta)
    }
    
    override func decodeRestorableStateWithCoder(coder: NSCoder) {
        super.decodeRestorableStateWithCoder(coder)
        
        var center = CLLocationCoordinate2D()
        var span = MKCoordinateSpan()
        
        center.latitude = coder.decodeDoubleForKey(mapViewLat)
        center.longitude = coder.decodeDoubleForKey(mapViewLong)
        
        span.latitudeDelta = coder.decodeDoubleForKey(mapViewSpanLatDelta)
        span.longitudeDelta = coder.decodeDoubleForKey(mapViewSpanLongDelta)
        
        let region = MKCoordinateRegion(center: center, span: span)
        
        mapView.setRegion(region, animated: true)
    }
    
    // MARK: Segue
    let siteTableViewControllerSegueID = "SiteTableViewController"
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == siteTableViewControllerSegueID {
            guard let pavc = segue.destinationViewController as? SiteTableViewController else {
                print("unexpected destionation viewcontroller")
                return
            }
            pavc.annotation = annotation
            
        }
    }
    
    var sharedContext: NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }
    lazy var fetchedResultsController: NSFetchedResultsController = {
        let request = NSFetchRequest(entityName: "VTAnnotation")
        request.sortDescriptors = [NSSortDescriptor(key: "latitude", ascending: true), NSSortDescriptor(key: "longitude", ascending: true)]
        return NSFetchedResultsController(fetchRequest: request, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    func locationNames(placemark: CLPlacemark, altitude: CLLocationDistance) -> [String] {
        var names = [String]()
        
        
        if altitude < 100000 {
            if let subLocality = placemark.subLocality {
                names.append(subLocality)
            }
        }
        
        if altitude < 300000 {
            if let locality = placemark.locality {
                names.append(locality)
            }
        }
        
        if altitude < 1000000 {
            if let administrativeArea = placemark.administrativeArea {
                names.append(administrativeArea)
            }
        }

        if let country = placemark.country {
            names.append(country)
        }
        if let ocean = placemark.ocean {
            names.append(ocean)
        }

        return names
    }
    func reverseGeocodeLocation(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance, completionHandler: (name: String) -> Void) {
        geocoder.reverseGeocodeLocation(CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) { (placemarks, error) -> Void in
            if error == nil {
                guard let placemarks = placemarks else {
                    return
                }
                guard let placemark = placemarks.first else {
                    return
                }
            
                let name = self.locationNames(placemark, altitude: altitude).first!
                completionHandler(name: name)
                
            }
        }
    }
    
}

// MARK: UIViewControllerRestoration
extension LocationsMapViewController : UIViewControllerRestoration {
    static func viewControllerWithRestorationIdentifierPath(identifierComponents: [AnyObject], coder: NSCoder) -> UIViewController? {
        return UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("LocationsMapViewController")
    }
}

// MARK: MKMapViewDelegate
extension LocationsMapViewController : MKMapViewDelegate {
    func mapView(mapView: MKMapView, didChangeUserTrackingMode mode: MKUserTrackingMode, animated: Bool) {
        if mode == .None {
            locationButton.image = UIImage(named: "GPS")
        } else {
            locationButton.image = UIImage(named: "GPS-Filled")
        }
    }
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        reverseGeocodeLocation(mapView.centerCoordinate, altitude: mapView.camera.altitude) { (name) -> Void in
            self.navigationItem.title = name
        }
    }
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if let annotation = view.annotation as? VTAnnotation {
            self.annotation = annotation
            performSegueWithIdentifier(siteTableViewControllerSegueID, sender: self)
        }
    }
}

// MARK: NSFetchedResultsControllerDelegate
extension LocationsMapViewController : NSFetchedResultsControllerDelegate {
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        let pin = anObject as! VTAnnotation
        switch type {
        case .Insert:
            mapView.addAnnotation(pin)
        case .Delete:
            mapView.removeAnnotation(pin)
        case .Update:
            mapView.removeAnnotation(pin)
            mapView.addAnnotation(pin)
        default:
            return
        }
    }
    
}

extension LocationsMapViewController : CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        startTrackingLocation()
    }
}
