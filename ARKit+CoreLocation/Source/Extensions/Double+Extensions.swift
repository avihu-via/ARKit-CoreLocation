//
//  Double+Extensions.swift
//  ARKit+CoreLocation
//
//  Created by Avihu Turzion on 05/03/2018.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import Foundation

extension Double {
    func metersToLatitude() -> Double {
        return self / (6360500.0)
    }
    
    func metersToLongitude() -> Double {
        return self / (5602900.0)
    }
}
