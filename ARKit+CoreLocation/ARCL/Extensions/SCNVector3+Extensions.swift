//
//  SCNVecto3+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 23/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import SceneKit

extension SCNVector3 {
    var asPoint: CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(0 - z))
    }
    
    // Doesn't include the y axis, matches functionality of CLLocation 'distance' function.
    func planarDistance(to vector: SCNVector3) -> Float {
        return sqrt(pow(vector.x - x, 2) + pow(vector.z - z, 2))
    }
    
    func isWithin(distanceOf distance: CGFloat, from vector: SCNVector3) -> Bool {
        return asPoint.distance(to: vector.asPoint) <= distance
    }
}
