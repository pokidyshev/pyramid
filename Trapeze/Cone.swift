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

  var sideCount: Int = 20

  init(device: MTLDevice) {
    func NegZ(_ v: Vertex) -> Vertex {
      return Vertex(x: v.x, y: v.y, z: -v.z, r: v.r, g: v.g, b: v.b, a: v.a, nX: v.nX, nY: v.nY, nZ: v.nZ)
    }

    func NegX(_ v: Vertex) -> Vertex {
      return Vertex(x: -v.x, y: v.y, z: v.z, r: v.r, g: v.g, b: v.b, a: v.a, nX: v.nX, nY: v.nY, nZ: v.nZ)
    }

    func Neg(_ v: Vertex) -> Vertex {
      return Vertex(x: -v.x, y: v.y, z: -v.z, r: v.r, g: v.g, b: v.b, a: v.a, nX: v.nX, nY: v.nY, nZ: v.nZ)
    }

    // Base center
    let O = Vertex(x: 0.0, y: 0.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0, nX: 0.0, nY: 0.0, nZ: -1.0)
    // Top
    let H = Vertex(x: 0.0, y: 2.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0, nX: 0.0, nY: 0.0, nZ: 1.0)
    // Points on the base circle
    var A = Vertex(x: 1.0, y: 0.0, z:   0.0, r:  1.0, g:  0.0, b:  0.0, a:  1.0, nX: 0.0, nY: -1.0, nZ: 0.0)
    var B = A

    let delta = Float.pi / Float(2*sideCount)
    var alpha = delta

    var vertices = [Vertex]()

    for _ in 1...sideCount {
      A = B
      alpha += delta
      B = Vertex(x: cos(alpha), y: 0.0, z: sin(alpha), r: 1.0, g: 0.0, b: 0.0, a: 1.0, nX: 0.0, nY: -1.0, nZ: 0.0)
      vertices += [B,A,H,             O,A,B]
      vertices += [H,NegX(A),NegX(B), NegX(A),O,NegX(B)]
      vertices += [H,NegZ(A),NegZ(B), NegZ(A),O,NegZ(B)]
      vertices += [Neg(B),Neg(A),H,   O,Neg(A),Neg(B)]
    }

    super.init(name: "Cone", vertices: vertices, device: device)
  }
}
