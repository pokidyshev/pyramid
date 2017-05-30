//
//  Cone.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 30.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

import Foundation
import MetalKit

class Cone: Node {

  var sideCount: Int = 30

  init(device: MTLDevice) {
    // Base center
    let O = Vertex(x: 0.0, y: 0.0, z: 0.0, nX: 0.0, nY: -1.0, nZ:  0.0)
    // Top
    let H = Vertex(x: 0.0, y: 2.0, z: 0.0, nX: 0.0, nY:  1.0, nZ:  0.0)
    // Points on the base circle
    var A = Vertex(x: 1.0, y: 0.0, z: 0.0, nX: 0.0, nY: -1.0, nZ:  0.0)
    var B = A

    let delta = (2*Float.pi) / Float(sideCount)
    var alpha = delta
    var vertices = [Vertex]()

    for _ in 1...sideCount {
      A = B
      B = Vertex(x: cos(alpha), y: 0.0, z: sin(alpha), nX: 0.0, nY: -1.0, nZ: 0.0)
      vertices += Cone.WithNormals(v1: B, v2: A, v3: H)
      vertices += [O,A,B]
      alpha += delta
    }

    super.init(name: "Cone", vertices: vertices, device: device)
  }


  private static func CalculateSurfaceNormal(v1: Vertex, v2: Vertex, v3: Vertex) -> (Float, Float, Float) {
    let p1 = vector3(v1.x, v1.y, v1.z)
    let p2 = vector3(v2.x, v2.y, v2.z)
    let p3 = vector3(v3.x, v3.y, v3.z)

    let u = p2 - p1
    let v = p3 - p1

    let nX = u.y*v.z - u.z*v.y
    let nY = u.z*v.x - u.x*v.z
    let nZ = u.x*v.y - u.y*v.x

    return (nX, nY, nZ)
  }

  private static func WithNormals(v1: Vertex, v2: Vertex, v3: Vertex) -> [Vertex] {
    let norm = CalculateSurfaceNormal(v1: v1, v2: v2, v3: v3)
    return [
      Vertex(x: v1.x, y: v1.y, z: v1.z, nX: norm.0, nY: norm.1, nZ: norm.2),
      Vertex(x: v2.x, y: v2.y, z: v2.z, nX: norm.0, nY: norm.1, nZ: norm.2),
      Vertex(x: v3.x, y: v3.y, z: v3.z, nX: norm.0, nY: norm.1, nZ: norm.2),
    ]
  }
}
