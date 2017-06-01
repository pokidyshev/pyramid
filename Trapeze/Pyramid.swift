//
//  Cone.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 30.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

import Foundation
import MetalKit

class Pyramid: Node {

  var sideCount: Int = 8

  init(device: MTLDevice, commandQ: MTLCommandQueue, textureLoader: MTKTextureLoader) {

    // In Metal, the default coordinate system is the normalized coordinate system, 
    // which means that by default we are looking at a 2x2x1 cube centered at (0, 0, 0.5).

    // Base center
    let O = Vertex(x: 0.0, y: 0.0, z: 0.0, nX: 0.0, nY: -1.0, nZ:  0.0, s: 0.5, t: 1.0)
    // Top
    let H = Vertex(x: 0.0, y: 2.0, z: 0.0, nX: 0.0, nY:  1.0, nZ:  0.0, s: 0.5, t: 0.0)
    // Points on the base circle
    var A = Vertex(x: 1.0, y: 0.0, z: 0.0, nX: 0.0, nY: -1.0, nZ:  0.0, s: 0.0, t: 1.0)
    var B = A

    let delta = (2*Float.pi) / Float(sideCount)
    var alpha = delta
    var vertices = [Vertex]()
    
    let ds = 1.0 / Float(sideCount)
    var s = ds

    for _ in 1...sideCount {
      A = B
      B = Vertex(x: cos(alpha), y: 0.0, z: sin(alpha), nX: 0.0, nY: -1.0, nZ: 0.0, s: s, t: 1.0)
      vertices += Pyramid.withNormals(v1: B, v2: A, v3: H)
      vertices += [O,A,B]
      alpha += delta
      s += ds
    }

    let path = Bundle.main.path(forResource: "pyramid", ofType: "png")!
    let data = NSData(contentsOfFile: path) as! Data
    let texture = try! textureLoader.newTexture(with: data, options: [MTKTextureLoaderOptionSRGB : (false as NSNumber)])

    super.init(name: "Cone", vertices: vertices, device: device, texture: texture)
  }

  private static func calculateSurfaceNormal(v1: Vertex, v2: Vertex, v3: Vertex) -> vector_float3 {
    let p1 = vector3(v1.x, v1.y, v1.z)
    let p2 = vector3(v2.x, v2.y, v2.z)
    let p3 = vector3(v3.x, v3.y, v3.z)

    return normalize(cross(p2 - p1, p3 - p1))
  }

  private static func withNormals(v1: Vertex, v2: Vertex, v3: Vertex) -> [Vertex] {
    let norm = calculateSurfaceNormal(v1: v1, v2: v2, v3: v3)
    return [
      Vertex(x: v1.x, y: v1.y, z: v1.z, nX: norm.x, nY: norm.y, nZ: norm.z, s: v1.s, t: v1.t),
      Vertex(x: v2.x, y: v2.y, z: v2.z, nX: norm.x, nY: norm.y, nZ: norm.z, s: v2.s, t: v2.t),
      Vertex(x: v3.x, y: v3.y, z: v3.z, nX: norm.x, nY: norm.y, nZ: norm.z, s: v3.s, t: v3.t),
    ]
  }
}
