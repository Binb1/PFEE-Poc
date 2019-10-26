//
//  ViewController.swift
//  ImageDetection-JPO
//
//  Created by Robin Champsaur on 25/06/2018.
//  Copyright © 2018 Robin Champsaur. All rights reserved.
//

//TODO - Fix the zposition of the plane on very big images

import UIKit
import SceneKit
import ARKit
import SpriteKit

class ViewController: UIViewController, ARSCNViewDelegate {
    

    @IBOutlet var gameView: GameView!
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    let scenaryHandler = ScenaryHandler()
    let imgDictionnary = ImageDictionnary()
    
    let updateQueue = DispatchQueue(label: Bundle.main.bundleIdentifier! +
        ".serialSceneKitQueue")
    
    var neatsie: Neatsie?
    
    var touch: UITouch?
    var direction = float2(0, 0)
    
    let plane = Plane(width: 1, height: 1, content: UIColor.cyan.withAlphaComponent(0.5), doubleSided: true, horizontal: true)

    override func viewDidLoad() {
        super.viewDidLoad()
        
        gameView.delegate = self
        gameView.showsStatistics = true
        
        gameView.scene = SCNScene()
        gameView.session.delegate = self
        
        
        neatsie = Neatsie()
        addPlane(object: neatsie)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        configureTracking(ressourceFolder: Constants.ARReference.folderName)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        gameView.session.pause()
    }
    
    @IBAction func resetCube(_ sender: Any) {
        neatsie?.removeFromParentNode()
        neatsie = Neatsie()
        
        if let neatsie = neatsie {
            plane.addChildNode(neatsie)
        }
    }
    
    func configureTracking(ressourceFolder: String) {
        guard let referenceImages = ARReferenceImage.referenceImages(inGroupNamed: ressourceFolder, bundle: nil) else {
            fatalError("Missing expected asset catalog resources")
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.detectionImages = referenceImages
        gameView.session.run(configuration, options: [])
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
    func addPlane(object: SCNNode? = nil){
        plane.position = SCNVector3(0, 0, -0.5)
        
        if let object = object {
            plane.addChildNode(object)
        }
        
        self.gameView.scene.rootNode.addChildNode(plane)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let imageAnchor = anchor as? ARImageAnchor else { return }
        let ref = imageAnchor.referenceImage
        updateQueue.async {
            //Triple check to see if the SKScene and the node can be created
            if let name = ref.name {
                if let dicoDescr = self.imgDictionnary.dictionnary[name] {
                    if !self.scenaryHandler.nodeHandler.onScreenNodes.contains(dicoDescr) {
                        self.scenaryHandler.runScenary3IE(objectName: dicoDescr, sceneView: self.gameView, ref: ref, node: node)
                    }
                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        let directionInV3 = float3(x: direction.x, y: -direction.y, z: 0)
        neatsie?.walkInDirection(directionInV3)
        direction = float2(0, 0)
        print("x: \(neatsie!.position.x) y: \(neatsie!.position.y) z: \(neatsie!.position.z)")
    }
}


extension ViewController {

    // store touch in global scope
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        touch = touches.first
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {

        if let touch = touch {

            // check whether our touch is within our dpad
            let touchLocation = touch.location(in: self.view)
            if gameView.virtualDPad().contains(touchLocation) {

                let middleOfCircleX = gameView.virtualDPad().origin.x + 75
                let middleOfCircleY = gameView.virtualDPad().origin.y + 75

                let lengthOfX = Float(touchLocation.x - middleOfCircleX)
                let lengthOfY = Float(touchLocation.y - middleOfCircleY)

                direction = float2(x: lengthOfX, y: lengthOfY)
                direction = normalize(direction)

                let degree = atan2(direction.x, direction.y)
                neatsie!.directionAngle = degree
                //print("moving x: \(direction.x) y: \(direction.y)")
            }
        }
    }
}
