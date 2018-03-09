//
//  VecotrsTests.swift
//  ARKit+CoreLocationTests
//
//  Created by Avihu Turzion on 09/03/2018.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import XCTest

class VectorsTests: XCTestCase {
    func testNumericArraySum() {
        XCTAssertEqual([0].sum(), 0)
        XCTAssertEqual([1,2,3].sum(), 6)
        XCTAssertEqual([1.0, 2.0].sum(), 3.0)
    }
}
