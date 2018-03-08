//
//  LocationManager.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation

// Mock Location Service Protocol

protocol LocationManagerProvider {
    var desiredAccuracy: CLLocationAccuracy { get set }
    var distanceFilter: CLLocationDistance { get set }
    var headingFilter: CLLocationDegrees { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var delegate: CLLocationManagerDelegate? { get set }
    var location: CLLocation? { get }
    
    static func authorizationStatus() -> CLAuthorizationStatus
    
    func startUpdatingHeading()
    func startUpdatingLocation()
    func requestWhenInUseAuthorization()
}

extension CLLocationManager: LocationManagerProvider {}

// Mock Location Service

enum MockLocationSet {
    case viaTLVOfficeToAzrieli
    
    var startLocation: CLLocation {
        switch self {
        case .viaTLVOfficeToAzrieli: return CLLocation()
        }
    }
    
    var pathLocationPoints: [CLLocation] {
        switch self {
        case .viaTLVOfficeToAzrieli: return []
        }
    }
}

enum LocationSource {
    case live
    case mock(MockLocationSet)
}

private class MockCLLocationManager: LocationManagerProvider {
    var mockLocationSet: MockLocationSet = .viaTLVOfficeToAzrieli
    
    var desiredAccuracy = kCLLocationAccuracyBest
    var distanceFilter = kCLDistanceFilterNone
    var headingFilter = kCLHeadingFilterNone
    var pausesLocationUpdatesAutomatically = true
    var location: CLLocation? { return mockLocationSet.startLocation }
    var delegate: CLLocationManagerDelegate?
    
    static func authorizationStatus() -> CLAuthorizationStatus {
        return .authorizedWhenInUse
    }
    
    func startUpdatingHeading() {}
    
    func startUpdatingLocation() {}
    
    func requestWhenInUseAuthorization() {}
}

protocol LocationManagerDelegate: class {
    func locationManagerDidUpdateLocation(_ locationManager: LocationManager, location: CLLocation)
    func locationManagerDidUpdateHeading(_ locationManager: LocationManager, heading: CLLocationDirection, accuracy: CLLocationDirection)
}

// Handles retrieving the location and heading from CoreLocation
// Does not contain anything related to ARKit or advanced location
class LocationManager: NSObject {
    weak var delegate: LocationManagerDelegate?
    
    var currentLocation: CLLocation?
    var heading: CLLocationDirection?
    var headingAccuracy: CLLocationDegrees?
    
    var source: LocationSource = .live
    private var locationManager: LocationManagerProvider = CLLocationManager()
    
    override init() {
        super.init()
        setupLiveLocationManager()
    }
    
    func requestAuthorization() {
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedAlways ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.authorizedWhenInUse {
            return
        }
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.denied ||
            CLLocationManager.authorizationStatus() == CLAuthorizationStatus.restricted {
            return
        }
        
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupLiveLocationManager() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.headingFilter = kCLHeadingFilterNone
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.delegate = self
        locationManager.startUpdatingHeading()
        locationManager.startUpdatingLocation()
        locationManager.requestWhenInUseAuthorization()
        currentLocation = locationManager.location
    }
}
    
    //MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {}
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.forEach { self.delegate?.locationManagerDidUpdateLocation(self, location: $0) }
        currentLocation = manager.location
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.headingAccuracy >= 0 ? newHeading.trueHeading : newHeading.magneticHeading
        headingAccuracy = newHeading.headingAccuracy
        delegate?.locationManagerDidUpdateHeading(self, heading: heading!, accuracy: newHeading.headingAccuracy)
    }
    
    func locationManagerShouldDisplayHeadingCalibration(_ manager: CLLocationManager) -> Bool {
        return true
    }
}
