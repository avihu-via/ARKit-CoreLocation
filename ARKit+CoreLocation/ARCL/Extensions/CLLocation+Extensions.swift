//
//  CLLocation+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation

// Translation in meters between 2 locations
public struct LocationTranslation {
    public var latitude: Double
    public var longitude: Double
    public var altitude: Double
}

public extension CLLocation {
    public convenience init(coordinate: CLLocationCoordinate2D, altitude: CLLocationDistance) {
        self.init(coordinate: coordinate, altitude: altitude, horizontalAccuracy: 0, verticalAccuracy: 0, timestamp: Date())
    }
    
    public convenience init(latitude: CLLocationDegrees, longitude: CLLocationDegrees, altitude: CLLocationDistance) {
        self.init(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude), altitude: altitude)
    }
    
    // Translates distance in meters between two locations.
    // Returns the result as the distance in latitude and distance in longitude.
    public func translation(toLocation location: CLLocation) -> LocationTranslation {
        let inbetweenLocation = CLLocation(latitude: coordinate.latitude, longitude: location.coordinate.longitude)
        
        var latitudeDelta = location.distance(from: inbetweenLocation)
        if location.coordinate.latitude < inbetweenLocation.coordinate.latitude {
            latitudeDelta = -latitudeDelta
        }
        
        var longitudeDelta = distance(from: inbetweenLocation)
        if coordinate.longitude > inbetweenLocation.coordinate.longitude {
            longitudeDelta = -longitudeDelta
        }
        
        return LocationTranslation(latitude: latitudeDelta, longitude: longitudeDelta, altitude: location.altitude - altitude)
    }
    
    public func translatedLocation(using translation: LocationTranslation) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: self.coordinate.coordinate(withBearingDegrees: 0, distanceMeters: translation.latitude).latitude,
                longitude: self.coordinate.coordinate(withBearingDegrees: 90, distanceMeters: translation.longitude).longitude),
            altitude: self.altitude + translation.altitude,
            horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.verticalAccuracy, timestamp: self.timestamp)
    }
}
