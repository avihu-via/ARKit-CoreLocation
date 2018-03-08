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
        case .viaTLVOfficeToAzrieli: return CLLocation(latitude: 32.0723327, longitude: 34.7953844)
        }
    }
    
    var startHeading: CLHeadingCompatible {
        switch self {
        case .viaTLVOfficeToAzrieli: return CLHeadingMock(trueHeading: 200)
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
        }
    }
}

enum LocationSource {
    case live
    case mock(MockLocationSet)
}

private class CLLocationManagerMock: LocationManagerProvider {
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
    
    var source: LocationSource = .mock(.viaTLVOfficeToAzrieli) {
        didSet {
            switch source {
            case .live:
                locationManager = CLLocationManager()
            case .mock(let mockSet):
                locationManager = CLLocationManagerMock(mockLocationSet: mockSet)
                pathLocationPoints = mockSet.pathLocationPoints
            }
        }
    }
    
    private(set) var pathLocationPoints: [CLLocation] = MockLocationSet.viaTLVOfficeToAzrieli.pathLocationPoints
    
    private var locationManager: LocationManagerProvider = CLLocationManagerMock(mockLocationSet: .viaTLVOfficeToAzrieli)
    
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
