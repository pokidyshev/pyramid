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

  var time: CFTimeInterval = 0.0

  var bufferProvider: BufferProvider

  var texture: MTLTexture
  lazy var samplerState: MTLSamplerState? = Node.defaultSampler(device: self.device)

  let light = Light(color: (1.0,1.0,1.0), direction: (0.0, 0.0, 1.0), shininess: 10, ambientIntensity: 0.1, diffuseIntensity: 0.8, specularIntensity: 2)
  
  init(name: String, vertices: Array<Vertex>, device: MTLDevice, texture: MTLTexture) {
    var vertexData = Array<Float>()
    for vertex in vertices {
      vertexData += vertex.floatBuffer()
    }

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

  func modelMatrix() -> float4x4 {
    var matrix = float4x4()
    matrix.translate(positionX, y: positionY, z: positionZ)
    matrix.rotateAroundX(rotationX, y: rotationY, z: rotationZ)
    matrix.scale(scale, y: scale, z: scale)
    return matrix
  }

  func render(commandQueue: MTLCommandQueue,
              pipelineState: MTLRenderPipelineState,
              drawable: CAMetalDrawable,
              parentModelViewMatrix: float4x4,
              projectionMatrix: float4x4,
              clearColor: MTLClearColor?)
  {
    _ = bufferProvider.avaliableResourcesSemaphore.wait(timeout: DispatchTime.distantFuture)

    let renderPassDescriptor = MTLRenderPassDescriptor()
    renderPassDescriptor.colorAttachments[0].texture = drawable.texture
    renderPassDescriptor.colorAttachments[0].loadAction = .clear
    renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
    renderPassDescriptor.colorAttachments[0].storeAction = .store

    let commandBuffer = commandQueue.makeCommandBuffer()
    commandBuffer.addCompletedHandler { (_) in
      self.bufferProvider.avaliableResourcesSemaphore.signal()
    }

    let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
    renderEncoder.setCullMode(MTLCullMode.front)
    renderEncoder.setRenderPipelineState(pipelineState)
    renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, at: 0)
    renderEncoder.setFragmentTexture(texture, at: 0)
    if let samplerState = samplerState {
      renderEncoder.setFragmentSamplerState(samplerState, at: 0)
    }

    var nodeModelMatrix = self.modelMatrix()
    nodeModelMatrix.multiplyLeft(parentModelViewMatrix)
    let uniformBuffer = bufferProvider.nextUniformsBuffer(projectionMatrix: projectionMatrix,
                                                          modelViewMatrix: nodeModelMatrix,
                                                          light: light)

    renderEncoder.setVertexBuffer(uniformBuffer, offset: 0, at: 1)
    renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, at: 1)
    renderEncoder.drawPrimitives(type: .triangle,
                                 vertexStart: 0,
                                 vertexCount: vertexCount,
                                 instanceCount: vertexCount/3)
    renderEncoder.endEncoding()
    
    commandBuffer.present(drawable)
    commandBuffer.commit()
  }

  func updateWithDelta(delta: CFTimeInterval) {
    time += delta
  }

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
