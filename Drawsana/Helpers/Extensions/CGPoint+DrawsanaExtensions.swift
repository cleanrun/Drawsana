//
//  CGPoint+DrawsanaExtensions.swift
//  Drawsana
//
//  Created by Steve Landey on 8/2/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import CoreGraphics

extension CGPoint {
  init(angle: CGFloat, radius: CGFloat) {
    self.init(x: cos(angle) * radius, y: sin(angle) * radius)
  }

  var length: CGFloat {
    return sqrt((x * x) + (y * y))
  }
  
  func getRotatedPoint(from origin: CGPoint, angle radians: CGFloat) -> CGPoint {
    let dx = self.x - origin.x
    let dy = self.y - origin.y
    let radius = sqrt(dx * dx + dy * dy)
    let azimuth = atan2(dy, dx)
    let newAzimuth = azimuth + radians
    let newX = origin.x + radius * cos(newAzimuth)
    let newY = origin.y + radius * sin(newAzimuth)
    return CGPoint(x: newX, y: newY)
  }
  
  func getAngleFromPoint(_ point: CGPoint) -> CGFloat {
    let originX = point.x - self.x
    let originY = point.y - self.y
    return atan2(originY, originX)
  }
}

func +(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
  return CGPoint(x: a.x + b.x, y: a.y + b.y)
}

func -(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
  return CGPoint(x: a.x - b.x, y: a.y - b.y)
}

func CGPointGetMiddlePoint(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
  let newX = (a.x + b.x) / 2
  let newY = (a.y + b.y) / 2
  return CGPoint(x: newX, y: newY)
}

func CGPointGetMiddlePoint(_ a: CGPoint, _ b: CGPoint, _ c: CGPoint) -> CGPoint {
  let newX = (a.x + b.x + c.x) / 3
  let newy = (a.y + b.y + c.y) / 3
  return CGPoint(x: newX, y: newy)
}

func CGPointGetDistanceBetweenPoints(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
  sqrt(pow((b.x - a.x), 2) + pow((b.y - a.y), 2))
}

func CGPointGetPointFromPoint(_ point: CGPoint, _ radius: CGFloat, _ angle: CGFloat) -> CGPoint {
  let x = point.x + radius * cos(angle)
  let y = point.y + radius * sin(angle)
  return CGPoint(x: x, y: y)
}
