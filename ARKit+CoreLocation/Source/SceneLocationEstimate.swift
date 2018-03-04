//
//  SceneLocationEstimate.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 03/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

struct SceneLocationEstimate {
    let realWorldLocation: CLLocation
    let virtualPosition: SCNVector3
    
    func distance(to position: SCNVector3) -> CGFloat {
        return virtualPosition.asPoint.distance(to: position.asPoint)
    }
}
