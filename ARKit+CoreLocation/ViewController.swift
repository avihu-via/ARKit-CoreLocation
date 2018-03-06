//
//  ViewController.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit
import SceneKit 
import MapKit
import CocoaLumberjack

@available(iOS 11.0, *)
class ViewController: UIViewController, MKMapViewDelegate, SceneLocationViewDelegate {
    private let frameTime = 1.0 / 60.0
    
    let sceneLocationView = SceneLocationView()
    
    let mapView = MKMapView()
    var userAnnotation: MKPointAnnotation?
    var locationEstimateAnnotation: MKPointAnnotation?
    
    var updateUserLocationTimer: Timer?
    
    ///Whether to show a map view
    ///The initial value is respected
    var showMapView: Bool = false
    
    var centerMapOnUserLocation: Bool = true
    
    ///Whether to display some debugging data
    ///This currently displays the coordinate of the best location estimate
    ///The initial value is respected
    var displayDebugging = false
    
    var infoLabel = UILabel()
    
    var updateInfoLabelTimer: Timer?
    
    var adjustNorthByTappingSidesOfScreen = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        infoLabel.font = UIFont.systemFont(ofSize: 10)
        infoLabel.textAlignment = .left
        infoLabel.textColor = UIColor.white
        infoLabel.numberOfLines = 0
        sceneLocationView.addSubview(infoLabel)
        
        updateInfoLabelTimer = Timer.scheduledTimer(timeInterval: frameTime, target: self, selector:  #selector(updateInfoLabel), userInfo: nil, repeats: true)
        
        //Set to true to display an arrow which points north.
        //Checkout the comments in the property description and on the readme on this.
//        sceneLocationView.orientToTrueNorth = false
        
//        sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        sceneLocationView.showAxesNode = true
        sceneLocationView.locationDelegate = self
        sceneLocationView.showFeaturePoints = displayDebugging
        
        //Currently set to Canary Wharf
        let parkHayarkonLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 32.1007717, longitude: 34.8118973), altitude: 17)
        let pinLocationNode = ImageAnnotatedLocationNode(location: parkHayarkonLocation, image: UIImage(named: "pin")!)
        sceneLocationView.add(confirmedLocationNode: pinLocationNode)
        
        view.addSubview(sceneLocationView)
        
        if showMapView {
            mapView.delegate = self
            mapView.showsUserLocation = true
            mapView.alpha = 0.8
            view.addSubview(mapView)
            updateUserLocationTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(updateUserLocationAsync), userInfo: nil, repeats: true)
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DDLogDebug("run")
        sceneLocationView.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        DDLogDebug("pause")
        // Pause the view's session
        sceneLocationView.pause()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        sceneLocationView.frame = CGRect(x: 0, y: 0, width: view.frame.size.width, height: view.frame.size.height)
        infoLabel.frame = CGRect(x: 6, y: 0, width: view.frame.size.width - 12, height: 14 * 4)
        
        if showMapView {
            infoLabel.frame.origin.y = (view.frame.size.height / 2) - infoLabel.frame.size.height
        } else {
            infoLabel.frame.origin.y = view.frame.size.height - infoLabel.frame.size.height
        }
        
        mapView.frame = CGRect(x: 0, y: view.frame.size.height / 2, width: view.frame.size.width, height: view.frame.size.height / 2)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    @objc private func updateUserLocationAsync() {
        DispatchQueue.main.async { self.updateUserLocation() }
    }
    
    private func updateUserLocation() {
        guard let currentLocation = sceneLocationView.currentLocation else { return }
        
        if let bestEstimate = sceneLocationView.bestLocationEstimate,
            let position = sceneLocationView.currentScenePosition {
            DDLogDebug("")
            DDLogDebug("Fetch current location")
            DDLogDebug("best location estimate, position: \(bestEstimate.virtualPosition), location: \(bestEstimate.realWorldLocation.coordinate), accuracy: \(bestEstimate.realWorldLocation.horizontalAccuracy), date: \(bestEstimate.realWorldLocation.timestamp)")
            DDLogDebug("current position: \(position)")
            
            let translation = bestEstimate.translatedLocation(to: position)
            
            DDLogDebug("translation: \(translation)")
            DDLogDebug("translated location: \(currentLocation)")
            DDLogDebug("")
        }
        
        if userAnnotation == nil {
            userAnnotation = MKPointAnnotation()
            mapView.addAnnotation(self.userAnnotation!)
        }
        
        UIView.animate(withDuration: 0.5, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
            self.userAnnotation?.coordinate = currentLocation.coordinate
        }, completion: nil)
        
        if centerMapOnUserLocation {
            UIView.animate(withDuration: 0.45, delay: 0, options: UIViewAnimationOptions.allowUserInteraction, animations: {
                self.mapView.setCenter(self.userAnnotation!.coordinate, animated: false)
            }, completion: { _ in
                self.mapView.region.span = MKCoordinateSpan(latitudeDelta: 0.0005, longitudeDelta: 0.0005)
            })
        }
        
        if displayDebugging {
            if let bestLocationEstimate = sceneLocationView.bestLocationEstimate {
                if locationEstimateAnnotation == nil {
                    locationEstimateAnnotation = MKPointAnnotation()
                    mapView.addAnnotation(self.locationEstimateAnnotation!)
                }
                
                locationEstimateAnnotation!.coordinate = bestLocationEstimate.realWorldLocation.coordinate
            } else {
                if locationEstimateAnnotation != nil {
                    mapView.removeAnnotation(locationEstimateAnnotation!)
                    locationEstimateAnnotation = nil
                }
            }
        }
    }
    
    @objc func updateInfoLabel() {
        if let position = sceneLocationView.currentScenePosition {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }
        
        if let eulerAngles = sceneLocationView.currentEulerAngles() {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }
        
        if let heading = sceneLocationView.locationManager.heading,
            let accuracy = sceneLocationView.locationManager.headingAccuracy {
            infoLabel.text!.append("Heading: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
        }
        
        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first, touch.view != nil else { return }
        
        if mapView == touch.view! || mapView.flatSubviews().contains(touch.view!) {
            centerMapOnUserLocation = false
        } else {
            let location = touch.location(in: view)
            if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
                print("left side of the screen")
                sceneLocationView.moveSceneHeadingAntiClockwise()
            } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
                print("right side of the screen")
                sceneLocationView.moveSceneHeadingClockwise()
            } else {
                let image = UIImage(named: "pin")!
                let annotationNode = ImageAnnotatedLocationNode(location: nil, image: image)
                annotationNode.scaleRelativeToDistance = true
                sceneLocationView.tagCurrentLocation(with: annotationNode)
            }
        }
    }
    
    //MARK: MKMapViewDelegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let pointAnnotation = annotation as? MKPointAnnotation else { return nil }
        let marker = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: nil)
        marker.displayPriority = .required
        
        if pointAnnotation == self.userAnnotation {
            marker.glyphImage = UIImage(named: "user")
        } else {
            marker.markerTintColor = UIColor(hue: 0.267, saturation: 0.67, brightness: 0.77, alpha: 1.0)
            marker.glyphImage = UIImage(named: "compass")
        }
        
        return marker
    }
    
    //MARK: SceneLocationViewDelegate
    
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        DDLogDebug("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        DDLogDebug("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(_ sceneLocationView: SceneLocationView, node: LocationNode) {}
    
    func sceneLocationViewDidSetupSceneNode(_ sceneLocationView: SceneLocationView, sceneNode: SCNNode) {}
    
    func sceneLocationViewDidUpdateLocationAndNodeScale(_ sceneLocationView: SceneLocationView, node: LocationNode) {}
}

extension DispatchQueue {
    func asyncAfter(timeInterval: TimeInterval, execute block: @escaping () -> Void) {
        self.asyncAfter(deadline: DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: block)
    }
}

extension UIView {
    func flatSubviews() -> [UIView] {
        var flatSubviews = subviews
        subviews.forEach { flatSubviews.append(contentsOf: $0.flatSubviews()) }
        return flatSubviews
    }
}
