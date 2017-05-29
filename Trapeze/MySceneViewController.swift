//
//  MySceneViewController.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 28.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

import UIKit

class MySceneViewController: MetalViewController, MetalViewControllerDelegate {

  var worldModelMatrix: Matrix4!
  var objectToDraw: Cube!

  override func viewDidLoad() {
    super.viewDidLoad()

    worldModelMatrix = Matrix4()
    worldModelMatrix.translate(0.0, y: 0.0, z: -4)
    worldModelMatrix.rotateAroundX(Matrix4.degrees(toRad: 25), y: 0.0, z: 0.0)

    objectToDraw = Cube(device: device, commandQ:commandQueue)
    self.metalViewControllerDelegate = self
  }

  //MARK: - MetalViewControllerDelegate
  func renderObjects(drawable:CAMetalDrawable) {

    objectToDraw.render(commandQueue: commandQueue, pipelineState: pipelineState, drawable: drawable, parentModelViewMatrix: worldModelMatrix, projectionMatrix: projectionMatrix, clearColor: nil)
  }

  func updateLogic(timeSinceLastUpdate: CFTimeInterval) {
    objectToDraw.updateWithDelta(delta: timeSinceLastUpdate)
  }


}

