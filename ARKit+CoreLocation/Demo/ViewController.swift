//
//  ViewController.swift
//  ARKit+CoreLocation
//
//  Created by Andrew Hart on 02/07/2017.
//  Copyright © 2017 Project Dent. All rights reserved.
//

import UIKit
import SceneKit 
import MapKit
import CocoaLumberjack

@available(iOS 11.0, *)
class ViewController: UIViewController {
    private let infoLabelRefreshInterval = 0.1
    
    @IBOutlet private weak var sceneLocationView: SceneLocationView!
    @IBOutlet private weak var infoLabel: UILabel!
    
    @IBOutlet private var smallDebugInfoLabelConstraint: NSLayoutConstraint!
    @IBOutlet private var fullWidthDebugContainerConstraint: NSLayoutConstraint!
    
    var updateInfoLabelTimer: Timer?
    
    var adjustNorthByTappingSidesOfScreen = false
    var showARDebugInfo = false {
        didSet {
            UIView.animate(withDuration: 0.15) { [weak self] in
                self?.updateARDebugInfoUI()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureSceneLocationView()
        configureUpdateTimers()
        addInitialPin()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DDLogDebug("run")
        sceneLocationView.run()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DDLogDebug("pause")
        sceneLocationView.pause()
    }
    
    @objc func updateARDebugInfoLabel() {
        guard showARDebugInfo else { return }
        
        if let position = sceneLocationView.currentScenePosition {
            infoLabel.text = "x: \(String(format: "%.2f", position.x)), y: \(String(format: "%.2f", position.y)), z: \(String(format: "%.2f", position.z))\n"
        }
        
        if let eulerAngles = sceneLocationView.currentEulerAngles() {
            infoLabel.text!.append("Euler x: \(String(format: "%.2f", eulerAngles.x)), y: \(String(format: "%.2f", eulerAngles.y)), z: \(String(format: "%.2f", eulerAngles.z))\n")
        }
        
        if let heading = sceneLocationView.locationManager.heading,
            let accuracy = sceneLocationView.locationManager.headingAccuracy {
            infoLabel.text!.append("Bearing: \(heading)º, accuracy: \(Int(round(accuracy)))º\n")
        }
        
        let date = Date()
        let comp = Calendar.current.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        
        if let hour = comp.hour, let minute = comp.minute, let second = comp.second, let nanosecond = comp.nanosecond {
            infoLabel.text!.append("\(String(format: "%02d", hour)):\(String(format: "%02d", minute)):\(String(format: "%02d", second)):\(String(format: "%03d", nanosecond / 1000000))")
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard let touch = touches.first, touch.view != nil else { return }
        
        let location = touch.location(in: view)
        if location.x <= 40 && adjustNorthByTappingSidesOfScreen {
            print("left side of the screen")
            sceneLocationView.moveSceneHeadingAntiClockwise()
        } else if location.x >= view.frame.size.width - 40 && adjustNorthByTappingSidesOfScreen {
            print("right side of the screen")
            sceneLocationView.moveSceneHeadingClockwise()
        } else {
            let image = UIImage(named: "pin")!
            let annotationNode = ImageAnnotatedLocationNode(location: nil, image: image)
            annotationNode.scaleRelativeToDistance = true
            sceneLocationView.tagCurrentLocation(with: annotationNode)
        }
    }
}

// MARK: - Actions

private extension ViewController {
    @IBAction private func toggleARDebugInfo() {
        showARDebugInfo = !showARDebugInfo
    }
}

// MARK: - Private Methods

private extension ViewController {
    private func configureSceneLocationView() {
        //Set to true to display an arrow which points north.
        //Checkout the comments in the property description and on the readme on this.
        //        sceneLocationView.orientToTrueNorth = false
        
        //        sceneLocationView.locationEstimateMethod = .coreLocationDataOnly
        sceneLocationView.showAxesNode = true
        sceneLocationView.locationDelegate = self
        sceneLocationView.showFeaturePoints = showARDebugInfo
    }
    
    private func configureUpdateTimers() {
        updateInfoLabelTimer = Timer.scheduledTimer(timeInterval: infoLabelRefreshInterval, target: self, selector:  #selector(updateARDebugInfoLabel), userInfo: nil, repeats: true)
    }
    
    private func addInitialPin() {
        let parkHayarkonLocation = CLLocation(coordinate: CLLocationCoordinate2D(latitude: 32.1007717, longitude: 34.8118973), altitude: 17)
        let pinLocationNode = ImageAnnotatedLocationNode(location: parkHayarkonLocation, image: UIImage(named: "pin")!)
        sceneLocationView.add(confirmedLocationNode: pinLocationNode)
    }
    
    private func updateARDebugInfoUI() {
        smallDebugInfoLabelConstraint.isActive = !showARDebugInfo
        fullWidthDebugContainerConstraint.isActive = showARDebugInfo
        if !showARDebugInfo { infoLabel.text = "Debug" }
        view.layoutIfNeeded()
    }
}
    
// MARK: - SceneLocationViewDelegate

extension ViewController: SceneLocationViewDelegate {
    func sceneLocationViewDidAddSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        DDLogDebug("add scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidRemoveSceneLocationEstimate(sceneLocationView: SceneLocationView, position: SCNVector3, location: CLLocation) {
        DDLogDebug("remove scene location estimate, position: \(position), location: \(location.coordinate), accuracy: \(location.horizontalAccuracy), date: \(location.timestamp)")
    }
    
    func sceneLocationViewDidConfirmLocationOfNode(_ sceneLocationView: SceneLocationView, node: LocationNode) {}
    
    func sceneLocationViewDidSetupSceneNode(_ sceneLocationView: SceneLocationView, sceneNode: SCNNode) {}
    
    func sceneLocationViewDidUpdateLocationAndNodeScale(_ sceneLocationView: SceneLocationView, node: LocationNode) {}
}

extension DispatchQueue {
    func asyncAfter(timeInterval: TimeInterval, execute block: @escaping () -> Void) {
        self.asyncAfter(deadline: DispatchTime.now() + Double(Int64(timeInterval * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: block)
    }
}

extension UIView {
    func flatSubviews() -> [UIView] {
        var flatSubviews = subviews
        subviews.forEach { flatSubviews.append(contentsOf: $0.flatSubviews()) }
        return flatSubviews
    }
}
