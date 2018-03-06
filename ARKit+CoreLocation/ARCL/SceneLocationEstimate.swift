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
    
    // Compares the location's position to another position, to determine the translation between them
    func locationTranslation(to position: SCNVector3) -> LocationTranslation {
        return LocationTranslation(
            latitudeTranslation: Double(self.virtualPosition.z - position.z),
            longitudeTranslation: Double(position.x - self.virtualPosition.x),
            altitudeTranslation: Double(position.y - self.virtualPosition.y))
    }
    
    // Translates the location by comparing with a given position
    func translatedLocation(to position: SCNVector3) -> CLLocation {
        let translation = self.locationTranslation(to: position)
        let translatedLocation = self.realWorldLocation.translatedLocation(using: translation)
        
        return translatedLocation
    }
}
