//
//  Vertex.swift
//  Trapeze
//
//  Created by Nikita Pokidyshev on 29.05.17.
//  Copyright © 2017 Nikita Pokidyshev. All rights reserved.
//

struct Vertex {
  var x,y,z: Float     // position data
  var nX,nY,nZ: Float  // normal

  func floatBuffer() -> [Float] {
    return [x,y,z,nX,nY,nZ]
  }
};
