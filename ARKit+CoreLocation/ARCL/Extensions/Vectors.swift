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
    
    init(components: [Float])
    
    func distance(to vec: Self) -> Float
}

extension Vector {
    static func -(lhs: Self, rhs: Self) -> Self {
        return Self(components: zip(lhs.components, rhs.components).map { $0 - $1 })
    }
    
    static func +(lhs: Self, rhs: Self) -> Self {
        return Self(components: zip(lhs.components, rhs.components).map { $0 + $1 })
    }
    
    static func *(lhs: Self, rhs: Self) -> Self {
        return Self(components: zip(lhs.components, rhs.components).map { $0 * $1 })
    }
    
    static func /(lhs: Self, rhs: Float) -> Self {
        return Self(components: lhs.components.map { $0 / rhs })
    }
    
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
    
    var components: [Float] {
        return [x, y, z]
    }
    
    init(components: [Float]) {
        guard components.count == 3 else { fatalError("Tried to initialize SCNVector3 with \(components.count) components instead of 3") }
        self.init(components[0], components[1], components[2])
    }
}

extension SCNVector4: Vector {
    var components: Float {
        return [x, y, z, w]
    }
    
    init(components: [Float]) {
        guard components.count == 4 else { fatalError("Tried to initialize SCNVector4 with \(componenets.count) components instead of 4") }
        self.init(components[0], components[1], components[2], components[3])
    }
}
