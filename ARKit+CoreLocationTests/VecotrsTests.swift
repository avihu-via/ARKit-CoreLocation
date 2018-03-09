//
//  VecotrsTests.swift
//  ARKit+CoreLocationTests
//
//  Created by Avihu Turzion on 09/03/2018.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import XCTest
import SceneKit

class ArraysTest: XCTestCase {
    func testNumericArraySum() {
        XCTAssertEqual([0].sum(), 0)
        XCTAssertEqual([1,2,3].sum(), 6)
        XCTAssertEqual([1.0, 2.0].sum(), 3.0)
    }
}

class VectorsTests: XCTestCase {
    func testSubtraction() {
        XCTAssertEqual(SCNVector3(1,1,1) - SCNVector3(1,1,1), SCNVector3Zero)
        XCTAssertEqual(SCNVector4(1,1,1,1) - SCNVector4(1,1,1,1), SCNVector4Zero)
    }
    
    func testAddition() {
        let vec3 = SCNVector3(1,1,1)
        XCTAssertEqual(SCNVector3Zero + vec3, vec3)
        
        let vec4 = SCNVector4(1,1,1,1)
        XCTAssertEqual(SCNVector4Zero + vec4, vec4)
    }
    
    func testMultiplication() {
        let vec3 = SCNVector3(2,2,2)
        XCTAssertEqual(vec3 * vec3, SCNVector3(4,4,4))
        
        let vec4 = SCNVector4(2,2,2,2)
        XCTAssertEqual(vec4 * vec4, SCNVector4(4,4,4,4))
    }
    
    func testScalarMultiplication() {
        XCTAssertEqual(SCNVector3(2,2,2) / 2, SCNVector3(1,1,1))
        XCTAssertEqual(SCNVector4(2,2,2,2) / 2, SCNVector4(1,1,1,1))
    }
    
    func testMidpoint() {
        XCTAssertEqual(SCNVector3.midpoint(from: SCNVector3Zero, to: SCNVector3(2,2,2)), SCNVector3(1,1,1))
        XCTAssertEqual(SCNVector4.midpoint(from: SCNVector4Zero, to: SCNVector4(2,2,2,2)), SCNVector4(1,1,1,1))
    }
    
    func testDotProduct() {
        XCTAssertEqual(SCNVector3(1,2,3)‧SCNVector3(4,5,6), 32)
        XCTAssertEqual(SCNVector4(1,2,3,4)‧SCNVector4(5,6,7,8), 70)
    }
    
    func testMagnitude() {
        XCTAssertEqual(SCNVector3(3,4,0).magnitude, 5)
    }
    
    func testDistance() {
        XCTAssertEqual(SCNVector3Zero.distance(to: SCNVector3(3,4,0)), 5)
    }
}
