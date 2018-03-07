//
//  LocationNode.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import SceneKit
import CoreLocation

// A location node can be added to a scene using a coordinate.
// Its scale and position should not be adjusted, as these are used for scene layout purposes
// To adjust the scale and position of items within a node, you can add them to a child node and adjust them there
open class LocationNode: SCNNode {
    // Location can be changed and confirmed later by SceneLocationView.
    public var location: CLLocation!
    
    // Whether the location of the node has been confirmed.
    // This is automatically set to true when you create a node using a location.
    // Otherwise, this is false, and becomes true once the user moves 100m away from the node,
    // except when the locationEstimateMethod is set to use Core Location data only,
    // as then it becomes true immediately.
    public var confirmedLocation = false
    
    // Whether a node's position should be adjusted on an ongoing basis
    // based on its' given location.
    // This only occurs when a node's location is within 100m of the user.
    // Adjustment doesn't apply to nodes without a confirmed location.
    // When this is set to false, the result is a smoother appearance.
    // When this is set to true, this means a node may appear to jump around
    // as the user's location estimates update,
    // but the position is generally more accurate.
    // Defaults to true.
    public var continuallyAdjustNodePositionWhenWithinRange = true
    
    // Whether a node's position and scale should be updated automatically on a continual basis.
    // This should only be set to false if you plan to manually update position and scale
    // at regular intervals. You can do this with `SceneLocationView`'s `updatePositionOfLocationNode`.
    public var continuallyUpdatePositionAndScale = true
    
    public init(location: CLLocation?) {
        self.location = location
        confirmedLocation = location != nil
        super.init()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// Images will be displayed at half the scale they are given. For every 2pt it will display
// 1pt on the screen. So a 100pt x 100pt will be displayed as 50pt x 50pt.
open class ImageAnnotatedLocationNode: LocationNode {
    public let image: UIImage
    
    // Subnodes and adjustments should be applied to this subnode
    // Required to allow scaling at the same time as having a 2D 'billboard' appearance
    public let annotationNode: SCNNode
    
    // Whether the node should be scaled relative to its distance from the camera
    // Default value (false) scales it to visually appear at the same size no matter the distance
    // Setting to true causes annotation nodes to scale like a regular node
    // Scaling relative to distance may be useful with local navigation-based uses
    // For landmarks in the distance, the default is correct
    public var scaleRelativeToDistance = false
    
    public init(location: CLLocation?, image: UIImage) {
        self.image = image
        
        let plane = SCNPlane(width: image.size.width / 200, height: image.size.height / 200)
        plane.firstMaterial!.diffuse.contents = image
        plane.firstMaterial!.lightingModel = .constant
        
        annotationNode = SCNNode()
        annotationNode.geometry = plane
        
        super.init(location: location)
        
        let billboardConstraint = SCNBillboardConstraint()
        billboardConstraint.freeAxes = SCNBillboardAxis.Y
        constraints = [billboardConstraint]
        
        addChildNode(annotationNode)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
