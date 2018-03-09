//
//  PathGeometry.swift
//  ARKit+CoreLocation
//
//  Created by Avihu Turzion on 08/03/2018.
//  Copyright © 2018 Project Dent. All rights reserved.
//

import Foundation
import SceneKit

let pathWidth: CGFloat = 0.8
let pathHeight: CGFloat = 0.2
let pathVertexHeight: CGFloat = pathHeight + 0.05
let pathVertexRadius: CGFloat = 0.5
let pathInitialVertexRadius: CGFloat = 1.2

let pathColor: UIColor = .cyan
let pathVertexColor: UIColor = .purple

private extension SCNNode {
    func addChildNodes(_ nodes: [SCNNode]) {
        nodes.forEach { addChildNode($0) }
    }
}

class EdgeNode: SCNNode {
    private let edgeBox = SCNBox(width: pathWidth, height: pathHeight, length: 0, chamferRadius: 0)
    
    var length: CGFloat {
        return edgeBox.length
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNode()
    }
    
    override init() {
        super.init()
        setupNode()
    }
    
    convenience init(length: CGFloat) {
        self.init()
        edgeBox.length = length
    }
    
    convenience init(pointsPair: (SCNVector3, SCNVector3)) {
        self.init()
        let (origin, destination) = pointsPair
        edgeBox.length = CGFloat(origin.distance(to: destination))
        position = SCNVector3.midpoint(from: origin, to: destination)
        look(at: origin)
    }
    
    private func setupNode() {
        edgeBox.firstMaterial?.diffuse.contents = pathColor
        edgeBox.firstMaterial?.lightingModel = .blinn
        geometry = edgeBox
    }
}

class VertexNode: SCNNode {
    let cylinder = SCNCylinder(radius: pathVertexRadius, height: pathVertexHeight)
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupNode()
    }
    
    override init() {
        super.init()
        setupNode()
    }
    
    convenience init(position: SCNVector3) {
        self.init()
        self.position = position
    }
    
    private func setupNode() {
        cylinder.firstMaterial?.diffuse.contents = pathVertexColor
        cylinder.firstMaterial?.lightingModel = .blinn
        geometry = cylinder
    }
}

class PathNode: SCNNode {
    static func from(points: SCNVector3...) -> PathNode {
        return from(pointsSet: points)
    }
    
    static func from(pointsSet points: [SCNVector3]) -> PathNode {
        let pathNode = PathNode()
        
        if let firstPoint = points.first {
            pathNode.position = firstPoint
        }
        
        pathNode.addChildNodes(points.map { VertexNode(position: $0)})
        pathNode.addChildNodes(zip(points[..<(points.count-1)], points[1...]).map { EdgeNode(pointsPair: $0) })
        
        return pathNode
    }
}
