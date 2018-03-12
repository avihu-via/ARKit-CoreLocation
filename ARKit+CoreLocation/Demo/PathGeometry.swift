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

class TerminatorVertexNode: SCNReferenceNode {
    convenience init(position: SCNVector3) {
        self.init()
        self.position = position
        print("Creating terminator node")
        guard let modelURL = Bundle.main.url(forResource: "models.scnassets", withExtension: nil)?.appendingPathComponent("PickUp.scn") else { fatalError("No PickUp model file.") }
        print("Loading model from URL: \(modelURL.absoluteString)")
        referenceURL = modelURL
        load()
    }
}

class PathNode: SCNNode {
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init() {
        super.init()
    }
    
    convenience init(fromPoints points: SCNVector3...) {
        self.init(fromPointsSet: points)
    }
    
    convenience init(fromPointsSet points: [SCNVector3]) {
        self.init()
        
        if let firstPoint = points.first {
            position = firstPoint
        }
        
        addChildNodes(points.map { VertexNode(position: $0)})
        addChildNodes(zip(points[..<(points.count-1)], points[1...]).map { EdgeNode(pointsPair: $0) })
        
        if let lastPoint = points.last {
            addChildNode(TerminatorVertexNode(position: lastPoint))
        }
    }
}
