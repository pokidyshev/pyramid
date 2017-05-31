//
//  MySceneViewController.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 28.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

import UIKit
import simd

class MySceneViewController: MetalViewController {

  // view transformation 
  // converts node’s coordinates from world coordinates to camera coordinates
  var worldModelMatrix: float4x4!

  var objectToDraw: Pyramid!

  var panSensivity: Float = 5.0
  var lastPanLocation: CGPoint!

  var rotationSensivity: Float = 0.05

  override func viewDidLoad() {
    super.viewDidLoad()

    worldModelMatrix = float4x4()
    worldModelMatrix.translate(0.0, y: 0.0, z: -3.5)

    objectToDraw = Pyramid(device: device, commandQ: commandQueue, textureLoader: textureLoader)
    self.metalViewControllerDelegate = self

    setupGestures()
  }

  //MARK: - Gesture related

  func setupGestures() {
    let pan = UIPanGestureRecognizer(target: self, action: #selector(MySceneViewController.pan))
    pan.maximumNumberOfTouches = 1
    self.view.addGestureRecognizer(pan)

    let pinch = UIPinchGestureRecognizer(target: self, action: #selector(MySceneViewController.pinch))
    self.view.addGestureRecognizer(pinch)
  }

  func pan(panRecognizer: UIPanGestureRecognizer) {
    if panRecognizer.state == .changed {
      let pointInView = panRecognizer.location(in: self.view)

      let xDelta = Float((lastPanLocation.x - pointInView.x)/self.view.bounds.width) * panSensivity
      let yDelta = Float((lastPanLocation.y - pointInView.y)/self.view.bounds.height) * panSensivity

      objectToDraw.rotationY -= xDelta
      objectToDraw.rotationX -= yDelta

      lastPanLocation = pointInView
    } else if panRecognizer.state == .began {
      lastPanLocation = panRecognizer.location(in: self.view)
    }
  }

  func pinch(pinchRecognizer: UIPinchGestureRecognizer) {
    if pinchRecognizer.state == .changed {
      objectToDraw.scale *= Float(pinchRecognizer.scale)
      pinchRecognizer.scale = 1
    }
  }
}

extension MySceneViewController: MetalViewControllerDelegate {

  func renderObjects(drawable:CAMetalDrawable) {

    objectToDraw.render(commandQueue: commandQueue,
                        pipelineState: pipelineState,
                        drawable: drawable,
                        parentModelViewMatrix: worldModelMatrix,
                        projectionMatrix: projectionMatrix,
                        clearColor: nil)
  }
}
