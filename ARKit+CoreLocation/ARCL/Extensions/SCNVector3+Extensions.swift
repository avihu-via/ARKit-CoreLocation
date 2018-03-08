//
//  SCNVecto3+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 23/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import SceneKit

protocol Vector {
    static func -(lhs: Self, rhs: Self) -> Self
    static func +(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
    static func /(lhs: Self, rhs: Float) -> Self
    
    static func midpoint(from: Self, to: Self) -> Self
    
    var components: [Float] { get }
    var magnitude: Float { get }
    
    func distance(to vec: Self) -> Float
}

extension Vector {
    static func midpoint(from origin: Self, to destination: Self) -> Self {
        return (origin + destination) / 2
    }
    
    var magnitude: Float {
        return sqrt((self * self).components.reduce(0, +))
    }
    
    func distance(to vec: Self) -> Float {
        return (vec - self).magnitude
    }
}

extension SCNVector3: Vector {
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
    
    static func -(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z)
    }
    
    static func +(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z)
    }
    
    static func *(lhs: SCNVector3, rhs: SCNVector3) -> SCNVector3 {
        return SCNVector3(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z)
    }
    
    static func /(lhs: SCNVector3, rhs: Float) -> SCNVector3 {
        return SCNVector3(lhs.x / rhs, lhs.y / rhs, lhs.z / rhs)
    }
    
    var components: [Float] {
        return [x, y, z]
    }
}
