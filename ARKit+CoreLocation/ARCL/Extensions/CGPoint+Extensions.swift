//
//  CGPoint+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 03/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit
import SceneKit

extension CGPoint {
    func distance(to point: CGPoint) -> CGFloat {
        return CGFloat(sqrt(Double(pow(point.x - x, 2) + pow(point.y - y, 2))))
    }
}
