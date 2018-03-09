//
//  SCNVecto3+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 23/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import SceneKit

private extension Array where Element: Numeric {
    func sum() -> Element { return reduce(0, +) }
}

protocol Vector {
    static func -(lhs: Self, rhs: Self) -> Self
    static func +(lhs: Self, rhs: Self) -> Self
    static func *(lhs: Self, rhs: Self) -> Self
    static func /(lhs: Self, rhs: Float) -> Self
    
    static func ==(lhs: Self, rhs: Self) -> Bool
    
    static func midpoint(from: Self, to: Self) -> Self
    
    func dot(_ vector: Self) -> Float
    
    var components: [Float] { get set }
    var dimensions: Int { get }
    
    var magnitude: Float { get }
    
    init()
    
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
    
    static func ==(lhs: Self, rhs: Self) -> Bool {
        return zip(lhs.components, rhs.components).map(==).reduce(true) { $0 && $1 }
    }
    
    static func midpoint(from origin: Self, to destination: Self) -> Self {
        return (origin + destination) / 2
    }
    
    func dot(_ vector: Self) -> Float {
        return zip(components, vector.components).map(*).sum()
    }
    
    var magnitude: Float {
        return sqrt((self * self).components.sum())
    }
    
    private init(components: [Float]) {
        self.init()
        self.components = components
    }
    
    func distance(to vec: Self) -> Float {
        return (vec - self).magnitude
    }
}

extension SCNVector3: Vector {
    var components: [Float] {
        get {
            return [x, y, z]
        }
        set {
            guard newValue.count == dimensions else { fatalError("Tried to initialize SCNVector3 with \(components.count) components instead of 3")}
            x = newValue[0]
            y = newValue[1]
            z = newValue[2]
        }
    }
    
    var dimensions: Int { return 3 }
}

extension SCNVector4: Vector {
    var components: [Float] {
        get {
            return [x, y, z, w]
        }
        set {
            guard newValue.count == dimensions else { fatalError("Tried to initialize SCNVector4 with \(components.count) components instead of 4") }
            x = newValue[0]
            y = newValue[1]
            z = newValue[2]
            w = newValue[3]
        }
    }
    
    var dimensions: Int { return 4 }
}


// MARK: - ARCL SCNVector3 Extensions

extension SCNVector3 {
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
}
