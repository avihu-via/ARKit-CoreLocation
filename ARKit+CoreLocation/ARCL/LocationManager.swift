//
//  LocationManager.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import Foundation
import CoreLocation

// CLHeading Mock

protocol CLHeadingCompatible {
    var magneticHeading: CLLocationDirection { get }
    var trueHeading: CLLocationDirection { get }
    var headingAccuracy: CLLocationDirection { get }
    var timestamp: Date { get }
}

extension CLHeading: CLHeadingCompatible {}

struct CLHeadingMock: CLHeadingCompatible {
    let magneticHeading: CLLocationDirection
    let trueHeading: CLLocationDirection
    let headingAccuracy: CLLocationDirection
    let timestamp = Date()
    
    init(magneticHeading: CLLocationDirection, trueHeading: CLLocationDirection, headingAccuracy: CLLocationDirection) {
        self.magneticHeading = magneticHeading
        self.trueHeading = trueHeading
        self.headingAccuracy = headingAccuracy
    }
    
    init(trueHeading: CLLocationDirection) {
        self.init(magneticHeading: 0, trueHeading: trueHeading, headingAccuracy: 0)
    }
}

// Mock Location Service Protocol

protocol LocationManagerProvider {
    var desiredAccuracy: CLLocationAccuracy { get set }
    var distanceFilter: CLLocationDistance { get set }
    var headingFilter: CLLocationDegrees { get set }
    var pausesLocationUpdatesAutomatically: Bool { get set }
    var delegate: CLLocationManagerDelegate? { get set }
    var location: CLLocation? { get }
    
    var pathLocationPoints: [CLLocation] { get }
    
    static func authorizationStatus() -> CLAuthorizationStatus
    
    func startUpdatingHeading()
    func startUpdatingLocation()
    func requestWhenInUseAuthorization()
}

extension CLLocationManager: LocationManagerProvider {
    var pathLocationPoints: [CLLocation] {
        return []
    }
}

// Mock Location Service

enum MockLocationSet {
    case viaTLVOfficeToAzrieli
    case insideViaTLVOffice
    case viaTLVOfficeAroundTheCornerToIgalAlon
    case viaNYCOfficeAroundTheBlock
    
    var startLocation: CLLocation {
        switch self {
        case .viaTLVOfficeToAzrieli: return CLLocation(latitude: 32.0723327, longitude: 34.7953844)
        case .viaTLVOfficeAroundTheCornerToIgalAlon: return CLLocation(latitude: 32.073159, longitude: 34.796919)
        case .insideViaTLVOffice: return CLLocation(latitude: 32.073183, longitude: 34.797094)
        case .viaNYCOfficeAroundTheBlock: return CLLocation(latitude: 40.719957, longitude: -74.000324)
        }
    }
    
    var startHeading: CLHeadingCompatible {
        switch self {
        case .viaTLVOfficeToAzrieli: return CLHeadingMock(trueHeading: 200)
        case .viaTLVOfficeAroundTheCornerToIgalAlon: return CLHeadingMock(trueHeading: 0)
        case .insideViaTLVOffice: return CLHeadingMock(trueHeading: 0)
        case .viaNYCOfficeAroundTheBlock: return CLHeadingMock(trueHeading: 0)
        }
    }
    
    var pathLocationPoints: [CLLocation] {
        switch self {
        case .viaTLVOfficeToAzrieli: return [
                CLLocation(latitude: 32.0723807, longitude: 34.7954753),
                CLLocation(latitude: 32.0730221, longitude: 34.7955921),
                CLLocation(latitude: 32.0724242, longitude: 34.7946299),
                CLLocation(latitude: 32.0723249, longitude: 34.7945177),
                CLLocation(latitude: 32.0728956, longitude: 34.7934293)
            ]
            
        case .viaTLVOfficeAroundTheCornerToIgalAlon: return [
                CLLocation(latitude: 32.073114, longitude: 34.796890),
                CLLocation(latitude: 32.073405, longitude: 34.795985),
                CLLocation(latitude: 32.073527, longitude: 34.795599),
                CLLocation(latitude: 32.073674, longitude: 34.795146),
                CLLocation(latitude: 32.073755, longitude: 34.795177),
                CLLocation(latitude: 32.073845, longitude: 34.795213)
            ]
            
        case .insideViaTLVOffice: return [
                CLLocation(latitude: 32.073208, longitude: 34.797100),
                CLLocation(latitude: 32.073231, longitude: 34.797110),
                CLLocation(latitude: 32.073271, longitude: 34.797138)
            ]
            
        case .viaNYCOfficeAroundTheBlock: return [
                CLLocation(latitude: 40.719942, longitude: -74.000291),
                CLLocation(latitude: 40.719773, longitude: -74.000439),
                CLLocation(latitude: 40.719670, longitude: -74.000527),
                CLLocation(latitude: 40.719538, longitude: -74.000635),
                CLLocation(latitude: 40.719583, longitude: -74.000737),
                CLLocation(latitude: 40.719618, longitude: -74.000797)
            ]
        }
        
    }
}

enum LocationSource {
    case live
    case mock(MockLocationSet)
}

private class CLLocationManagerMock: LocationManagerProvider {
    var mockLocationSet: MockLocationSet
    
    var desiredAccuracy = kCLLocationAccuracyBest
    var distanceFilter = kCLDistanceFilterNone
    var headingFilter = kCLHeadingFilterNone
    var pausesLocationUpdatesAutomatically = true
    var location: CLLocation? { return mockLocationSet.startLocation }
    var delegate: CLLocationManagerDelegate?
    
    var pathLocationPoints: [CLLocation] {
        return mockLocationSet.pathLocationPoints
    }
    
    static func authorizationStatus() -> CLAuthorizationStatus {
        return .authorizedWhenInUse
    }
    
    init(mockLocationSet: MockLocationSet) {
        self.mockLocationSet = mockLocationSet
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
    
    var pathLocationPoints: [CLLocation] {
        return locationManager.pathLocationPoints
    }
    
    private var locationManager: LocationManagerProvider = CLLocationManagerMock(mockLocationSet: .viaNYCOfficeAroundTheBlock)
    
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
