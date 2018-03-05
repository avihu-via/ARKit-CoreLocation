//
//  SCNVecto3+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 23/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import SceneKit

extension SCNVector3 {
    
    // Doesn't include the y axis, matches functionality of CLLocation 'distance' function.
    func distance(to vector: SCNVector3) -> Float {
        return sqrt(pow(vector.x - x, 2) + pow(vector.z - z, 2))
    }
    
    var asPoint: CGPoint {
        return CGPoint(x: CGFloat(x), y: CGFloat(0 - z))
    }
}
