/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import MetalKit
import simd

protocol MetalViewControllerDelegate: class {
  func updateLogic(timeSinceLastUpdate: CFTimeInterval)
  func renderObjects(drawable: CAMetalDrawable)
}

class MetalViewController: UIViewController {

  var device: MTLDevice!
  var pipelineState: MTLRenderPipelineState!
  var commandQueue: MTLCommandQueue!
  var projectionMatrix: float4x4!

  weak var metalViewControllerDelegate: MetalViewControllerDelegate?

  @IBOutlet weak var mtkView: MTKView! {
    didSet {
      mtkView.delegate = self
      mtkView.preferredFramesPerSecond = 60
      mtkView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    device = MTLCreateSystemDefaultDevice()
    mtkView.device = device

    projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0), aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height), nearZ: 0.01, farZ: 100.0)

    let defaultLibrary = device.newDefaultLibrary()!
    let fragmentProgram = defaultLibrary.makeFunction(name: "basic_fragment")
    let vertexProgram = defaultLibrary.makeFunction(name: "basic_vertex")

    let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
    pipelineStateDescriptor.vertexFunction = vertexProgram
    pipelineStateDescriptor.fragmentFunction = fragmentProgram
    pipelineStateDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

    pipelineState = try! device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)

    commandQueue = device.makeCommandQueue()
  }

  func render(_ drawable: CAMetalDrawable?) {
    guard let drawable = drawable else { return }
    self.metalViewControllerDelegate?.renderObjects(drawable: drawable)
  }
}

// MARK: - MTKViewDelegate
extension MetalViewController: MTKViewDelegate {

  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    projectionMatrix = float4x4.makePerspectiveViewAngle(float4x4.degrees(toRad: 85.0),
                                                         aspectRatio: Float(self.view.bounds.size.width / self.view.bounds.size.height),
                                                         nearZ: 0.01, farZ: 100.0)
  }
  
  func draw(in view: MTKView) {
    render(view.currentDrawable)
  }
  
}
