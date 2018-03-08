//
//  ViewController.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit
import CoreData
import SceneKit
import MapKit
import CocoaLumberjack
import ARKit

struct LocationPathPoint {
    let pathPoint: PathPoint
    let locationNode: LocationNode
}

@available(iOS 11.0, *)
class ViewController: UIViewController {
    private let infoLabelRefreshInterval = 0.1
    
    @IBOutlet private weak var sceneLocationView: SceneLocationView!
    @IBOutlet private weak var infoLabel: UILabel!
    @IBOutlet private weak var resetButtonContainer: UIVisualEffectView!
    
    @IBOutlet private var smallDebugInfoLabelConstraint: NSLayoutConstraint!
    @IBOutlet private var fullWidthDebugContainerConstraint: NSLayoutConstraint!
    @IBOutlet private var addPinVerticalSpacingFromDebugInfoConstraint: NSLayoutConstraint!
    @IBOutlet private var addPinSpaceFromBottomConstraint: NSLayoutConstraint!
    
    private var locationPathPoints: [LocationPathPoint] = []
    
    private var pathNode: PathNode?
    
    var updateInfoLabelTimer: Timer?
    
    var adjustNorthByTappingSidesOfScreen = false
    var showARDebugInfo = false {
        didSet {
//            resetButtonContainer.isHidden = !showARDebugInfo
            UIView.animate(withDuration: 0.15) { [weak self] in
                self?.updateARDebugInfoUI()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSceneLocationView()
        configureUpdateTimers()
        presentMockPathPoints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DDLogDebug("run")
        sceneLocationView.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DDLogDebug("pause")
        sceneLocationView.pause()
    }
    
    @objc func updateARDebugInfoLabel() {
        guard showARDebugInfo else { return }
        
        if let position = sceneLocationView.currentScenePosition {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }
        
        if let eulerAngles = sceneLocationView.currentEulerAngles() {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }
        
        if let heading = sceneLocationView.locationManager.heading, let accuracy = sceneLocationView.locationManager.headingAccuracy {
            infoLabel.text!.append("Heading: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
        }
        
        if let currentLocation = sceneLocationView.currentLocation {
            infoLabel.text!.append(contentsOf: "Lat: \(currentLocation.coordinate.latitude), Lng: \(currentLocation.coordinate.longitude), Alt: \(currentLocation.altitude) | Accuracy: H: \(currentLocation.horizontalAccuracy), V: \(currentLocation.verticalAccuracy)\n")
        }
        
        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("Time: \(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first, touch.view != nil else { return }
        
        let location = touch.location(in: view)
        if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
            print("left side of the screen")
            sceneLocationView.moveSceneHeadingAntiClockwise()
        } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
            print("right side of the screen")
            sceneLocationView.moveSceneHeadingClockwise()
        }
    }
}

// MARK: - Actions

private extension ViewController {
    @IBAction func resetPathTapped() {
        removeAllPathPoints()
    }
    
    @IBAction private func toggleARDebugInfo() {
        showARDebugInfo = !showARDebugInfo
    }
    
    @IBAction func addCurrentLocationTapped() {
        addCurrentLocation()
    }
}

// MARK: - Private Methods

private extension ViewController {
    private func presentMockPathPoints() {
        sceneLocationView.locationManager.pathLocationPoints.forEach { point in
            let pointLocation = CLLocation(latitude: point.coordinate.latitude, longitude: point.coordinate.longitude, altitude: point.altitude)
            let pointNode = ImageAnnotatedLocationNode(location: pointLocation, image: UIImage(named: "pin")!)
            sceneLocationView.add(confirmedLocationNode: pointNode)
        }
    }
    
    private func fetchStoredPathPoints() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return }
        let pathPointsFetchRequest = NSFetchRequest<PathPoint>(entityName: "PathPoint")
        do {
            let pathPoints = try context.fetch(pathPointsFetchRequest)
            locationPathPoints = locationPathPoints(from: pathPoints)
            print("Fetched \(pathPoints.count) path points.")
            if let firstPoint = pathPoints.first { print(firstPoint) }
        } catch let error as NSError {
            print("Could not fetch path points. \(error), \(error.userInfo)")
        }
    }
    
    private func locationPathPoints(from pathPoints: [PathPoint]) -> [LocationPathPoint] {
        var points: [LocationPathPoint] = []
        pathPoints.forEach { point in
            let pointLocation = CLLocation(latitude: point.latitude, longitude: point.longitude, altitude: point.altitude)
            let pointNode = ImageAnnotatedLocationNode(location: pointLocation, image: UIImage(named: "pin")!)
            sceneLocationView.add(confirmedLocationNode: pointNode)
            points.append(LocationPathPoint(pathPoint: point, locationNode: pointNode))
        }
        return points
    }
    
    private func removeAllPathPoints() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return }
        do {
            let locationNodes = locationPathPoints.map { $0.locationNode }
            locationPathPoints.forEach { context.delete($0.pathPoint) }
            try context.save()
            locationNodes.forEach { sceneLocationView.remove(node: $0) }
            locationPathPoints = []
            print("All points removed")
        } catch let error as NSError {
            print("Could not delete all points. \(error), \(error.userInfo)")
        }
    }
    
    private func addCurrentLocation() {
        guard let context = (UIApplication.shared.delegate as? AppDelegate)?.persistentContainer.viewContext else { return }
        
        let image = UIImage(named: "pin")!
        let annotationNode = ImageAnnotatedLocationNode(location: nil, image: image)
        annotationNode.scaleRelativeToDistance = true
        sceneLocationView.tagCurrentLocation(with: annotationNode)
        
        let newPoint = PathPoint(context: context)
        newPoint.latitude = annotationNode.location.coordinate.latitude
        newPoint.longitude = annotationNode.location.coordinate.longitude
        newPoint.altitude = annotationNode.location.altitude
        
        do {
            try context.save()
            locationPathPoints.append(LocationPathPoint(pathPoint: newPoint, locationNode: annotationNode))
        } catch let error as NSError {
            print("Had problem saving new point: \(error), \(error.userInfo)")
        }
    }
    
    private func configureSceneLocationView() {
        //Set to true to display an arrow which points north.
        //Checkout the comments in the property description and on the readme on this.
        //        sceneLocationView.orientToTrueNorth = false
        
        //        sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        sceneLocationView.showAxesNode = true
        sceneLocationView.locationDelegate = self
        sceneLocationView.showFeaturePoints = showARDebugInfo
    }
    
    private func configureUpdateTimers() {
        updateInfoLabelTimer = Timer.scheduledTimer(timeInterval: infoLabelRefreshInterval, target: self, selector:  #selector(updateARDebugInfoLabel), userInfo: nil, repeats: true)
    }
    
    private func updateARDebugInfoUI() {
        sceneLocationView.debugOptions = showARDebugInfo ? [ARSCNDebugOptions.showFeaturePoints] : []
        smallDebugInfoLabelConstraint.isActive = !showARDebugInfo
        fullWidthDebugContainerConstraint.isActive = showARDebugInfo
        addPinVerticalSpacingFromDebugInfoConstraint.isActive = showARDebugInfo
        addPinSpaceFromBottomConstraint.isActive = !showARDebugInfo
//        resetButtonContainer.alpha = showARDebugInfo ? 1 : 0
        if !showARDebugInfo { infoLabel.text = "Debug" }
        view.layoutIfNeeded()
    }
}
    
// MARK: - SceneLocationViewDelegate

extension ViewController: SceneLocationViewDelegate {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        DDLogDebug("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        DDLogDebug("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(_ sceneLocationView: SceneLocationView, node: LocationNode) {}
    
    func sceneLocationViewDidSetupSceneNode(_ sceneLocationView: SceneLocationView, sceneNode: SCNNode) {}
    
    func sceneLocationViewDidUpdateLocationAndNodeScale(_ sceneLocationView: SceneLocationView, node: LocationNode) {
        guard pathNode == nil && (sceneLocationView.locationNodes.filter { !($0.confirmedLocation) }.count == 0) else { return }
        pathNode = PathNode.from(pointsSet: sceneLocationView.locationNodes.map { $0.position })
        sceneLocationView.sceneNode?.addChildNode(pathNode!)
    }
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
