//
//  Node.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 29.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

import Foundation
import Metal
import QuartzCore
import simd

class Node {

  let device: MTLDevice
  let name: String

  var vertexCount: Int
  var vertexBuffer: MTLBuffer

  var positionX: Float = 0.0
  var positionY: Float = 0.0
  var positionZ: Float = 0.0

  var rotationX: Float = 0.0
  var rotationY: Float = 0.0
  var rotationZ: Float = 0.0

  var scale: Float     = 1.0

  var bufferProvider: BufferProvider

  let light = Light(color:             (1.0, 1.0, 1.0),
                    direction:         (0.0, 0.0, 1.0),
                    shininess:         10,
                    ambientIntensity:  0.1,
                    diffuseIntensity:  0.8,
                    specularIntensity: 2)

  var texture: MTLTexture
  // instructs the GPU how to use the texture
  lazy var samplerState: MTLSamplerState? = Node.defaultSampler(device: self.device)

  // returns a model matrix which is used to apply the model transformation
  var modelMatrix: float4x4 {
    var matrix = float4x4()
    matrix.translate(positionX, y: positionY, z: positionZ)
    matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
    matrix.scale(scale, y: scale, z: scale)
    return matrix
  }

  init(name: String, vertices: Array<Vertex>, device: MTLDevice, texture: MTLTexture) {
    // form a single buffer with floats
    var vertexData = Array<Float>()
    for vertex in vertices {
      vertexData += vertex.floatBuffer()
    }

    // ask the device to create a vertex buffer with the float buffer
    // this creates a new buffer on the GPU, passing in the data from the CPU
    // empty array as options for default configuration.
    let dataSize = vertexData.count * MemoryLayout.size(ofValue: vertexData[0])
    vertexBuffer = device.makeBuffer(bytes: vertexData, length: dataSize, options: [])

    self.name = name
    self.device = device
    vertexCount = vertices.count
    self.texture = texture

    let sizeOfUniformsBuffer = MemoryLayout<Float>.size * float4x4.numberOfElements() * 2 + Light.size()
    self.bufferProvider = BufferProvider(device: device,
                                         inflightBuffersCount: 3,
                                         sizeOfUniformsBuffer: sizeOfUniformsBuffer)
  }

  func render(commandQueue: MTLCommandQueue,
              pipelineState: MTLRenderPipelineState,
              drawable: CAMetalDrawable,
              parentModelViewMatrix: float4x4,
              projectionMatrix: float4x4,
              clearColor: MTLClearColor?) {

    _ = bufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)

    // object that configures which texture is being rendered to, 
    // what the clear color is, and a bit of other configuration
    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    // set the texture to the clear color before doing any drawing
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .store

    // The list of render commands that we wish to execute for this frame
    // Nothing actually happens until the command buffer is commited
    let commandBuffer = commandQueue.makeCommandBuffer()
    commandBuffer.addCompletedHandler { _ in
      self.bufferProvider.avaliableResourcesSemaphore.signal()
    }

    // Helper object to create a render command
    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    renderEncoder.setCullMode(MTLCullMode.front)
    // Specify the pipeline and vertex buffer
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)

    // This simply passes the texture and sampler to the shaders
    renderEncoder.setFragmentTexture(texture, at: 0)
    if let samplerState = samplerState{
      renderEncoder.setFragmentSamplerState(samplerState, at: 0)
    }

    // take model matrix and multiply it by the view matrix
    var nodeModelMatrix = modelMatrix
    nodeModelMatrix.multiplyLeft(parentModelViewMatrix)

    let uniformBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix,
                                                          modelViewMatrix: nodeModelMatrix,
                                                          light: light)

    // identical data across an entire model
    renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
    renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 1)

    // Tell the GPU to draw a set of triangles, based on the vertex buffer. 
    // Each triangle consists of three vertices, starting at index 0 inside the vertex buffer
    renderEncoder.drawPrimitives(type: .triangle,
                                 vertexStart: 0,
                                 vertexCount: vertexCount,
                                 instanceCount: vertexCount/3)
    renderEncoder.endEncoding()

    // Make sure the new texture is presented as soon as the drawing completes.
    commandBuffer.present(drawable)
    // Commit the transaction to send the task to the GPU.
    commandBuffer.commit()
  }

  // generates a simple texture sampler that basically holds a bunch of flags
  class func defaultSampler(device: MTLDevice) -> MTLSamplerState {
    let sampler = MTLSamplerDescriptor()
    sampler.minFilter             = MTLSamplerMinMagFilter.nearest
    sampler.magFilter             = MTLSamplerMinMagFilter.nearest
    sampler.mipFilter             = MTLSamplerMipFilter.nearest
    sampler.maxAnisotropy         = 1
    sampler.sAddressMode          = MTLSamplerAddressMode.clampToEdge
    sampler.tAddressMode          = MTLSamplerAddressMode.clampToEdge
    sampler.rAddressMode          = MTLSamplerAddressMode.clampToEdge
    sampler.normalizedCoordinates = true
    sampler.lodMinClamp           = 0
    sampler.lodMaxClamp           = FLT_MAX
    return device.makeSamplerState(descriptor: sampler)
  }
}
