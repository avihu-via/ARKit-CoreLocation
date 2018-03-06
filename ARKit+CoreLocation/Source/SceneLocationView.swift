//
//  SceneLocationView.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import ARKit
import CoreLocation
import MapKit

@available(iOS 11.0, *)
public protocol SceneLocationViewDelegate: class {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation)
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation)
    
    // After a node's location is initially set based on current location,
    // it is later confirmed once the user moves far enough away from it.
    // This update uses location data collected since the node was placed to give a more accurate location.
    func sceneLocationViewDidConfirmLocationOfNode(_ sceneLocationView: SceneLocationView, node: LocationNode)
    
    func sceneLocationViewDidSetupSceneNode(_ sceneLocationView: SceneLocationView, sceneNode: SCNNode)
    
    func sceneLocationViewDidUpdateLocationAndNodeScale(_ sceneLocationView: SceneLocationView, node: LocationNode)
}

public enum LocationEstimationMethod {
    case coreLocationDataOnly
    case ARAssistedEstimation
}

@available(iOS 11.0, *)
public class SceneLocationView: ARSCNView, ARSCNViewDelegate {
    // The limit to the scene, in terms of what data is considered reasonably accurate.
    // Measured in meters.
    private let sceneLimit: CGFloat = 100.0
    
    public weak var locationDelegate: SceneLocationViewDelegate?
    
    // Do not change while the scene is running.
    public var locationEstimateMethod: LocationEstimationMethod = .ARAssistedEstimation
    
    let locationManager = LocationManager()
    
    public var showAxesNode = false
    var showFeaturePoints = false
    
    private(set) var locationNodes = [LocationNode]()
    
    private var sceneLocationEstimates = [SceneLocationEstimate]()
    
    public private(set) var sceneNode: SCNNode? {
        didSet {
            guard let sceneNode = sceneNode else { return }
            locationNodes.forEach { sceneNode.addChildNode($0) }
            locationDelegate?.sceneLocationViewDidSetupSceneNode(self, sceneNode: sceneNode)
        }
    }
    
    private var updateEstimatesTimer: Timer?
    
    private var didFetchInitialLocation = false
    
    // Only to be overrided if you plan on manually setting True North.
    // When true, sets up the scene to face what the device considers to be True North.
    // This can be inaccurate, hence the option to override it.
    // The functions for altering True North can be used irrespective of this value,
    // but if the scene is oriented to true north, it will update without warning,
    // thus affecting your alterations.
    // The initial value of this property is respected.
    public var orientToTrueNorth = true
    
    // MARK: Setup
    public convenience init() {
        self.init(frame: CGRect.zero, options: nil)
    }
    
    public override init(frame: CGRect, options: [String : Any]? = nil) {
        super.init(frame: frame, options: options)
        finishInitialization()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        finishInitialization()
    }

    private func finishInitialization() {
        locationManager.delegate = self
        delegate = self
        showsStatistics = false

        if showFeaturePoints {
            debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        }
    }
    
    public func run() {
		let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        configuration.worldAlignment = orientToTrueNorth ? .gravityAndHeading : .gravity
        
        session.run(configuration)
        
        updateEstimatesTimer?.invalidate()
        updateEstimatesTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(SceneLocationView.updateLocationData), userInfo: nil, repeats: true)
    }
    
    public func pause() {
        session.pause()
        updateEstimatesTimer?.invalidate()
        updateEstimatesTimer = nil
    }
    
    @objc private func updateLocationData() {
        removeIrrelevantEstimations()
        confirmLocationOfDistantLocationNodes()
        updatePositionAndScaleOfLocationNodes()
    }
    
    // MARK: True North
    // iOS can be inaccurate when setting true north
    // The scene is oriented to true north, and will update its heading when it gets a more accurate reading
    // You can disable this through setting the
    // These functions provide manual overriding of the scene heading,
    //  if you have a more precise idea of where True North is
    // The goal is for the True North orientation problems to be resolved
    // At which point these functions would no longer be useful
    
    // Moves the scene heading clockwise by 1 degree
    // Intended for correctional purposes
    public func moveSceneHeadingClockwise() {
        sceneNode?.eulerAngles.y -= Float(1).degreesToRadians
    }
    
    // Moves the scene heading anti-clockwise by 1 degree
    // Intended for correctional purposes
    public func moveSceneHeadingAntiClockwise() {
        sceneNode?.eulerAngles.y += Float(1).degreesToRadians
    }
    
    // Resets the scene heading to 0
    func resetSceneHeading() {
        sceneNode?.eulerAngles.y = 0
    }
    
    //MARK: Scene Location Estimates
    
    public var currentScenePosition: SCNVector3? {
        guard let pointOfView = pointOfView else { return nil }
        return scene.rootNode.convertPosition(pointOfView.position, to: sceneNode)
    }
    
    public func currentEulerAngles() -> SCNVector3? {
        return pointOfView?.eulerAngles
    }
    
    // Adds a scene location estimate based on current time, camera position and location from location manager
    fileprivate func addSceneLocationEstimate(location: CLLocation) {
        guard let currentScenePosition = currentScenePosition else { return }
        
        sceneLocationEstimates.append(SceneLocationEstimate(realWorldLocation: location, virtualPosition: currentScenePosition))
        locationDelegate?.sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: self, position: currentScenePosition, location: location)
    }
    
    private func removeIrrelevantEstimations() {
        guard let currentScenePosition = currentScenePosition else { return }
        sceneLocationEstimates = sceneLocationEstimates.filter { $0.distance(to: currentScenePosition) <= sceneLimit }
    }
    
    // The best estimation of location that has been taken
    // This takes into account horizontal accuracy, and the time at which the estimation was taken
    // favouring the most accurate, and then the most recent result.
    // This doesn't indicate where the user currently is.
    var bestLocationEstimate: SceneLocationEstimate? {
        let sortedLocationEstimates = sceneLocationEstimates.sorted {
            if $0.realWorldLocation.horizontalAccuracy == $1.realWorldLocation.horizontalAccuracy {
                return $0.realWorldLocation.timestamp > $1.realWorldLocation.timestamp
            }
            return $0.realWorldLocation.horizontalAccuracy < $1.realWorldLocation.horizontalAccuracy
        }
        
        return sortedLocationEstimates.first
    }
    
    public var currentLocation: CLLocation? {
        if locationEstimateMethod == .coreLocationDataOnly {
            return locationManager.currentLocation
        }
        
        guard let bestEstimate = bestLocationEstimate, let position = currentScenePosition else { return nil }
        
        return bestEstimate.translatedLocation(to: position)
    }
    
    //MARK: Location Nodes
    
    public func tagCurrentLocation(with node: LocationNode) {
        guard let currentPosition = currentScenePosition, let currentLocation = currentLocation, let sceneNode = self.sceneNode else { return }
        
        node.location = currentLocation
        node.confirmedLocation = locationEstimateMethod == .coreLocationDataOnly
        node.position = currentPosition
        
        locationNodes.append(node)
        sceneNode.addChildNode(node)
    }
    
    // location not being nil, and locationConfirmed being true are required
    // Upon being added, a node's position will be modified and should not be changed externally.
    // location will not be modified, but taken as accurate.
    public func add(confirmedLocationNode node: LocationNode) {
        guard node.location != nil && node.confirmedLocation == true else { return }
        
        updatePositionAndScale(of: node, initialSetup: true, animated: false)
        locationNodes.append(node)
        sceneNode?.addChildNode(node)
    }
    
    public func remove(node: LocationNode) {
        if let index = locationNodes.index(of: node) {
            locationNodes.remove(at: index)
        }
        
        node.removeFromParentNode()
    }
    
    private func confirmLocationOfDistantLocationNodes() {
        guard let currentPosition = currentScenePosition else { return }
        
        locationNodes.filter { !$0.confirmedLocation }
                     .filter { !$0.position.isWithin(distanceOf: sceneLimit, from: currentPosition) }
                     .forEach { confirmLocation(of: $0) }
    }
    
    func location(of node: LocationNode) -> CLLocation {
        if node.confirmedLocation || locationEstimateMethod == .coreLocationDataOnly {
            return node.location!
        }
        
        if let bestLocationEstimate = bestLocationEstimate, node.location == nil || bestLocationEstimate.realWorldLocation.horizontalAccuracy < node.location!.horizontalAccuracy {
            return bestLocationEstimate.translatedLocation(to: node.position)
        } else {
            return node.location!
        }
    }
    
    private func confirmLocation(of node: LocationNode) {
        node.location = location(of: node)
        node.confirmedLocation = true
        locationDelegate?.sceneLocationViewDidConfirmLocationOfNode(self, node: node)
    }
    
    func updatePositionAndScaleOfLocationNodes() {
        for locationNode in locationNodes {
            if locationNode.continuallyUpdatePositionAndScale {
                updatePositionAndScale(of: locationNode, animated: true)
            }
        }
    }
    
    public func updatePositionAndScale(of node: LocationNode, initialSetup: Bool = false, animated: Bool = false, duration: TimeInterval = 0.1) {
        guard let currentPosition = currentScenePosition, let currentLocation = currentLocation else { return }
        
        SCNTransaction.begin()
        
        if animated {
            SCNTransaction.animationDuration = duration
        } else {
            SCNTransaction.animationDuration = 0
        }
        
        let locationNodeLocation = location(of: node)
        
        //Position is set to a position coordinated via the current position
        let locationTranslation = currentLocation.translation(toLocation: locationNodeLocation)
        let adjustedDistance: CLLocationDistance
        let distance = locationNodeLocation.distance(from: currentLocation)
        
        if node.confirmedLocation && (distance > 100 || node.continuallyAdjustNodePositionWhenWithinRange || initialSetup) {
            if distance > 100 {
                //If the item is too far away, bring it closer and scale it down
                let scale = 100 / Float(distance)
                
                adjustedDistance = distance * Double(scale)
                
                let adjustedTranslation = SCNVector3(
                    x: Float(locationTranslation.longitudeTranslation) * scale,
                    y: Float(locationTranslation.altitudeTranslation) * scale,
                    z: Float(locationTranslation.latitudeTranslation) * scale)
                
                let position = SCNVector3(
                    x: currentPosition.x + adjustedTranslation.x,
                    y: currentPosition.y + adjustedTranslation.y,
                    z: currentPosition.z - adjustedTranslation.z)
                
                node.position = position
                
                node.scale = SCNVector3(x: scale, y: scale, z: scale)
            } else {
                adjustedDistance = distance
                let position = SCNVector3(
                    x: currentPosition.x + Float(locationTranslation.longitudeTranslation),
                    y: currentPosition.y + Float(locationTranslation.altitudeTranslation),
                    z: currentPosition.z - Float(locationTranslation.latitudeTranslation))
                
                node.position = position
                node.scale = SCNVector3(x: 1, y: 1, z: 1)
            }
        } else {
            //Calculates distance based on the distance within the scene, as the location isn't yet confirmed
            adjustedDistance = Double(currentPosition.distance(to: node.position))
            
            node.scale = SCNVector3(x: 1, y: 1, z: 1)
        }
        
        if let annotationNode = node as? ImageAnnotatedLocationNode {
            //The scale of a node with a billboard constraint applied is ignored
            //The annotation subnode itself, as a subnode, has the scale applied to it
            let appliedScale = node.scale
            node.scale = SCNVector3(x: 1, y: 1, z: 1)
            
            var scale: Float
            
            if annotationNode.scaleRelativeToDistance {
                scale = appliedScale.y
                annotationNode.annotationNode.scale = appliedScale
            } else {
                //Scale it to be an appropriate size so that it can be seen
                scale = Float(adjustedDistance) * 0.181
                
                if distance > 3000 {
                    scale = scale * 0.75
                }
                
                annotationNode.annotationNode.scale = SCNVector3(x: scale, y: scale, z: scale)
            }
            
            annotationNode.pivot = SCNMatrix4MakeTranslation(0, -1.1 * scale, 0)
        }
        
        SCNTransaction.commit()
        
        locationDelegate?.sceneLocationViewDidUpdateLocationAndNodeScale(self, node: node)
    }
    
    //MARK: ARSCNViewDelegate
    
    public func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        if sceneNode == nil {
            sceneNode = SCNNode()
            scene.rootNode.addChildNode(sceneNode!)
            
            if showAxesNode {
                let axesNode = SCNNode.axesNode(quiverLength: 0.1, quiverThickness: 0.5)
                sceneNode?.addChildNode(axesNode)
            }
        }
        
        if !didFetchInitialLocation {
            //Current frame and current location are required for this to be successful
            if session.currentFrame != nil,
                let currentLocation = self.locationManager.currentLocation {
                didFetchInitialLocation = true
                
                self.addSceneLocationEstimate(location: currentLocation)
            }
        }
    }
    
    public func sessionWasInterrupted(_ session: ARSession) {
        print("session was interrupted")
    }
    
    public func sessionInterruptionEnded(_ session: ARSession) {
        print("session interruption ended")
    }
    
    public func session(_ session: ARSession, didFailWithError error: Error) {
        print("session did fail with error: \(error)")
    }
    
    public func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        print("Tracking state chagned to '\(camera.trackingState)'")
    }
}

//MARK: LocationManager

@available(iOS 11.0, *)
extension SceneLocationView: LocationManagerDelegate {
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager, location: CLLocation) {
        addSceneLocationEstimate(location: location)
    }
    
    func locationManagerDidUpdateHeading(_ locationManager: LocationManager, heading: CLLocationDirection, accuracy: CLLocationAccuracy) {}
}
