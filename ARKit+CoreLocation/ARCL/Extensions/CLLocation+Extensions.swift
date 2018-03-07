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
    public var latitudeTranslation: Double
    public var longitudeTranslation: Double
    public var altitudeTranslation: Double
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
        let inbetweenLocation = CLLocation(latitude: self.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let distanceLatitude = location.distance(from: inbetweenLocation)
        
        let latitudeTranslation: Double
        
        if location.coordinate.latitude > inbetweenLocation.coordinate.latitude {
            latitudeTranslation = distanceLatitude
        } else {
            latitudeTranslation = 0 - distanceLatitude
        }
        
        let distanceLongitude = distance(from: inbetweenLocation)
        
        let longitudeTranslation: Double
        
        if coordinate.longitude > inbetweenLocation.coordinate.longitude {
            longitudeTranslation = 0 - distanceLongitude
        } else {
            longitudeTranslation = distanceLongitude
        }
        
        let altitudeTranslation = location.altitude - altitude
        
        return LocationTranslation(latitudeTranslation: latitudeTranslation, longitudeTranslation: longitudeTranslation, altitudeTranslation: altitudeTranslation)
    }
    
    public func translatedLocation(using translation: LocationTranslation) -> CLLocation {
        return CLLocation(
            coordinate: CLLocationCoordinate2D(
                latitude: self.coordinate.coordinate(withBearingDegrees: 0, distanceMeters: translation.latitudeTranslation).latitude,
                longitude: self.coordinate.coordinate(withBearingDegrees: 90, distanceMeters: translation.longitudeTranslation).longitude),
            altitude: self.altitude + translation.altitudeTranslation,
            horizontalAccuracy: self.horizontalAccuracy, verticalAccuracy: self.verticalAccuracy, timestamp: self.timestamp)
    }
}
