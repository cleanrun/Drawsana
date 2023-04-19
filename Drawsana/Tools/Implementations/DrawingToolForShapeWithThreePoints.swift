//
//  DrawingToolForShapeWithThreePoints.swift
//  Drawsana
//
//  Created by Thanh Vu on 5/3/19.
//  Copyright © 2019 Asana. All rights reserved.
//

import Foundation

import CoreGraphics

/**
 Base class for tools (angle)
 */
open class DrawingToolForShapeWithThreePoints: DrawingTool {
  public typealias ShapeType = Shape & ShapeWithThreePoints
  
  open var name: String { fatalError("Override me") }
  
  public var shapeInProgress: ShapeType?
  
  public var isProgressive: Bool { return false }
  
  private var dragEndCount: Int = 0
  
  public init() { }
  
  /// Override this method to return a shape ready to be drawn to the screen.
  open func makeShape() -> ShapeType {
    fatalError("Override me")
  }
  
  public func handleTap(context: ToolOperationContext, point: CGPoint) {
  }
  
  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    if dragEndCount == 0 {
      shapeInProgress = makeShape()
      shapeInProgress?.a = point
      shapeInProgress?.b = point
      shapeInProgress?.c = point
      shapeInProgress?.apply(userSettings: context.userSettings)
      return
    }
    shapeInProgress?.c = point
  }
  
  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    if dragEndCount == 0 {
      shapeInProgress?.b = point
      return
    }
    shapeInProgress?.c = point
  }
  
  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard var shape = shapeInProgress else { return }
    if dragEndCount == 0 {
      dragEndCount += 1
      shape.b = point
      context.operationStack.apply(operation: AddShapeOperation(shape: shape))
      return
    }
    shape.c = point
    context.operationStack.undo()
    context.operationStack.apply(operation: AddShapeOperation(shape: shape))
    dragEndCount = 0
    shapeInProgress = nil
  }
  
  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    // No such thing as a cancel for this tool. If this was recognized as a tap,
    // just end the shape normally.
    handleDragEnd(context: context, point: point)
  }
  
  public func handlePinchStart(context: ToolOperationContext, startPoint: CGPoint, endPoint: CGPoint, scale: CGFloat) {
    let midYFromBothPoints: CGFloat = startPoint.y + ((endPoint.y - startPoint.y) / 2)
    let midXFromBothPoints: CGFloat = startPoint.x + ((endPoint.x - startPoint.x) / 2)
    shapeInProgress = makeShape()
    shapeInProgress?.a = startPoint
    shapeInProgress?.b = CGPoint(x: midXFromBothPoints, y: midYFromBothPoints)
    shapeInProgress?.c = endPoint
    shapeInProgress?.apply(userSettings: context.userSettings)
  }
  
  public func handlePinchContinue(context: ToolOperationContext, startPoint: CGPoint, endPoint: CGPoint, scale: CGFloat) {
    shapeInProgress?.a = startPoint
    shapeInProgress?.c = endPoint
  }
  
  public func handlePinchEnd(context: ToolOperationContext, startPoint: CGPoint, endPoint: CGPoint, scale: CGFloat) {
    guard var shape = shapeInProgress else { return }
    shape.a = startPoint
    shape.c = endPoint
    context.operationStack.apply(operation: AddShapeOperation(shape: shape))
    shapeInProgress = nil
  }
  
  public func handlePinchCancel(context: ToolOperationContext, startPoint: CGPoint, endPoint: CGPoint, scale: CGFloat) {
    handlePinchEnd(context: context, startPoint: startPoint, endPoint: endPoint, scale: scale)
  }
  
  public func renderShapeInProgress(transientContext: CGContext) {
    shapeInProgress?.render(in: transientContext)
  }
  
  public func apply(context: ToolOperationContext, userSettings: UserSettings) {
    shapeInProgress?.apply(userSettings: userSettings)
    context.toolSettings.isPersistentBufferDirty = true
  }
  
  private func generateDistanceFromTwoPoints(from: CGPoint, to: CGPoint) -> CGFloat {
    let squared: CGFloat = (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    return sqrt(squared)
  }
  
  private func generateBPoint(x: CGFloat, y: CGFloat, angle: CGFloat) -> CGPoint {
    let distance: CGFloat = 100
    let xValue: CGFloat = x + distance * __sinpi(angle/180)
    let yValue: CGFloat = y + distance * __cospi(angle/180)
    
    return CGPoint(x: xValue, y: yValue)
  }
  
  private func getAngle(from: CGPoint, to: CGPoint) -> Double {
    let deltaY = from.y - to.y
    let deltaX = from.x - to.x
    let angle = atan2(deltaY, deltaX) * 180 / .pi
    return angle
  }
}
