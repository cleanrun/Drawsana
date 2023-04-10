//
//  AMDrawingTool+Text.swift
//  AMDrawingView
//
//  Created by Steve Landey on 7/26/18.
//  Copyright © 2018 Asana. All rights reserved.
//

import UIKit

public protocol SelectionToolDelegate: AnyObject {
  /// User tapped on a shape, but it was already selected. You might want to
  /// take this opportuny to activate a tool that can edit that shape, if one
  /// exists.
  func selectionToolDidTapOnAlreadySelectedShape(_ shape: ShapeSelectable)
}

public class SelectionTool: DrawingTool {
  
  private enum SelectionPointAction {
    case aPoint
    case bPoint
    case cPoint
    case dPoint
    case ePoint
    case fPoint
    case gPoint
    case hPoint
    case movingAction
  }
  
  public let name = "Selection"
  
  public var isProgressive: Bool { return false }

  /// You may set yourself as the delegate to be notified when special selection
  /// events happen that you might want to react to. The core framework does
  /// not use this delegate.
  public weak var delegate: SelectionToolDelegate?

  private var originalAPoint: CGPoint?
  private var originalBPoint: CGPoint?
  private var updatedAPoint: CGPoint?
  private var updatedBPoint: CGPoint?
  
  private var originalTransform: ShapeTransform?
  private var startPoint: CGPoint?
  /* When you tap away from a shape you've just dragged, the method calls look
     like this:
      - handleDragStart (hitTest on selectedShape fails)
      - handleDragContinue
      - handleDragCancel
      - handleTap

     We need to be careful not to incorrectly reset the transform for the selected
     shape when you tap away, so we explicitly capture whether you are actually
     dragging the shape or not.
   */
  private var isDraggingShape = false

  private var isUpdatingSelection = false
  
  private var selectionPointAction: SelectionPointAction?
  
  private var selectionToolIndicatorView: SelectionIndicatorView!

  public init(delegate: SelectionToolDelegate? = nil, usingSelectionToolIndicatorViewFrom drawsanaView: DrawsanaView) {
    self.delegate = delegate
    self.selectionToolIndicatorView = drawsanaView.selectionIndicatorView
  }
  
  public func deactivate(context: ToolOperationContext) {
    context.toolSettings.selectedShape = nil
  }

  public func apply(context: ToolOperationContext, userSettings: UserSettings) {
    if let shape = context.toolSettings.selectedShape {
      if isUpdatingSelection {
        if let shapeWithStandardState = shape as? ShapeWithStandardState {
          context.userSettings.fillColor = shapeWithStandardState.fillColor
          context.userSettings.strokeColor = shapeWithStandardState.strokeColor
          context.userSettings.strokeWidth = shapeWithStandardState.strokeWidth
        } else if let shapeWithStrokeState = shape as? ShapeWithStrokeState {
          context.userSettings.strokeColor = shapeWithStrokeState.strokeColor
          context.userSettings.strokeWidth = shapeWithStrokeState.strokeWidth
        }
      } else {
        shape.apply(userSettings: userSettings)
        context.toolSettings.isPersistentBufferDirty = true
      }
    }
  }

  public func handleTap(context: ToolOperationContext, point: CGPoint) {
    if let selectedShape = context.toolSettings.selectedShape, selectedShape.hitTest(point: point) {
      if let delegate = delegate {
        delegate.selectionToolDidTapOnAlreadySelectedShape(selectedShape)
      } else {
        // Default behavior: deselect the shape
        context.toolSettings.selectedShape = nil
      }
      return
    }

    updateSelection(context: context, context.drawing.shapes
      .compactMap({ $0 as? ShapeSelectable })
      .filter({ $0.hitTest(point: point) })
      .last)
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    if let selectedShape = context.toolSettings.selectedShape {
      selectionPointAction = getIfDraggingResizePoint(from: point, shape: selectedShape, in: selectionToolIndicatorView.frame)

      if selectionPointAction == .movingAction {
        if selectedShape.hitTest(point: point) {
          isDraggingShape = true
          originalTransform = selectedShape.transform
          startPoint = point
        } else {
          selectionPointAction = nil
          isDraggingShape = false
          return
        }
      } else {
        originalTransform = selectedShape.transform
        isDraggingShape = false
      }
    }
  }

  public func handleDragContinue(context: ToolOperationContext, point: CGPoint, velocity: CGPoint) {
    guard var selectedShape = context.toolSettings.selectedShape else {
      isDraggingShape = false
      return
    }
    
    if isDraggingShape {
      guard
        let originalTransform = originalTransform,
        let startPoint = startPoint else
      {
        isDraggingShape = false
        return
      }
      let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
      selectedShape.transform = originalTransform.translated(by: delta)
      context.toolSettings.isPersistentBufferDirty = true
    } else {
      if selectedShape is ShapeWithTwoPoints {
        var castedShape = selectedShape as! ShapeWithTwoPoints
        calculateResizeChangesForShapesWithTwoPoints(point: point, shape: &castedShape)
        
        print("point: \(point), selected shape a: \(castedShape.a), b: \(castedShape.b)")
      }
      context.toolSettings.isPersistentBufferDirty = true
    }
  }

  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard
      let originalTransform = originalTransform,
      let selectedShape = context.toolSettings.selectedShape,
      let startPoint = startPoint else
    {
      isDraggingShape = false
      return
    }
    
    if isDraggingShape {
      let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
      context.operationStack.apply(operation: ChangeTransformOperation(
        shape: selectedShape,
        transform: originalTransform.translated(by: delta),
        originalTransform: originalTransform))
      context.toolSettings.isPersistentBufferDirty = true
      isDraggingShape = false
    } else {
      guard let originalAPoint,
            let originalBPoint,
            let updatedAPoint,
            let updatedBPoint else {
        return
      }
      
      context.operationStack.apply(operation: ResizeShapeWithTwoPointsOperation(
        shape: selectedShape as! ShapeWithTwoPoints,
        originalAPoint: originalAPoint,
        originalBPoint: originalBPoint,
        updatedAPoint: updatedAPoint,
        updatedBPoint: updatedBPoint))
      context.toolSettings.isPersistentBufferDirty = true
      selectionPointAction = nil
    }
  }

  public func handleDragCancel(context: ToolOperationContext, point: CGPoint) {
    guard isDraggingShape else { return }
    context.toolSettings.selectedShape?.transform = originalTransform ?? .identity
    context.toolSettings.isPersistentBufferDirty = true
  }
  
  public func handlePinchStart(context: ToolOperationContext, startPoint: CGPoint, endPoint: CGPoint) {
    // FIXME: This tool doesn't support pinch gestures
  }
  
  public func handlePinchContinue(context: ToolOperationContext, startPoint: CGPoint, endPoint: CGPoint) {
    // FIXME: This tool doesn't support pinch gestures
  }
  
  public func handlePinchEnd(context: ToolOperationContext, startPoint: CGPoint, endPoint: CGPoint) {
    // FIXME: This tool doesn't support pinch gestures
  }
  
  public func handlePinchCancel(context: ToolOperationContext, startPoint: CGPoint, endPoint: CGPoint) {
    // FIXME: This tool doesn't support pinch gestures
  }

  /// Update selection on context.toolSettings, but make sure that when apply()
  /// is called as a part of that change, we don't immediately change the
  /// properties of the newly selected shape.
  private func updateSelection(context: ToolOperationContext, _ newSelectedShape: ShapeSelectable?) {
    isUpdatingSelection = true
    context.toolSettings.selectedShape = newSelectedShape
    isUpdatingSelection = false
  }
  
  private func getIfDraggingResizePoint(from point: CGPoint, shape: ShapeSelectable, in selectionRect: CGRect) -> SelectionPointAction? {
    if shape.getARect(from: selectionRect).contains(point) {
      return .aPoint
    } else if shape.getBRect(from: selectionRect).contains(point) {
      return .bPoint
    } else if shape.getCRect(from: selectionRect).contains(point) {
      return .cPoint
    } else if shape.getDRect(from: selectionRect).contains(point) {
      return .dPoint
    } else if shape.getERect(from: selectionRect).contains(point) {
      return .ePoint
    } else if shape.getFRect(from: selectionRect).contains(point) {
      return .fPoint
    } else if shape.getGRect(from: selectionRect).contains(point) {
      return .gPoint
    } else if shape.getHRect(from: selectionRect).contains(point) {
      return .hPoint
    }
    
    return .movingAction
  }
  
  private func calculateResizeChangesForShapesWithTwoPoints(point: CGPoint, shape: inout ShapeWithTwoPoints) {
    updatedAPoint = shape.a
    updatedBPoint = shape.b
    
    switch selectionPointAction {
    case .bPoint:
      if shape.a.y < shape.b.y {
        updatedAPoint = CGPoint(x: shape.a.x, y: point.y)
        updatedBPoint = shape.b
      } else {
        updatedAPoint = shape.a
        updatedBPoint = CGPoint(x: shape.b.x, y: point.y)
      }
    case .dPoint:
      if shape.a.x < shape.b.x {
        updatedAPoint = CGPoint(x: point.x, y: shape.a.y)
        updatedBPoint = shape.b
      } else {
        updatedAPoint = shape.a
        updatedBPoint = CGPoint(x: point.x, y: shape.b.y)
      }
    case .ePoint:
      if shape.a.x > shape.b.x {
        updatedAPoint = CGPoint(x: point.x, y: shape.a.y)
        updatedBPoint = shape.b
      } else {
        updatedAPoint = shape.a
        updatedBPoint = CGPoint(x: point.x, y: shape.b.y)
      }
    case .gPoint:
      if shape.a.y > shape.b.y {
        updatedAPoint = CGPoint(x: shape.a.x, y: point.y)
        updatedBPoint = shape.b
      } else {
        updatedAPoint = shape.a
        updatedBPoint = CGPoint(x: shape.b.x, y: point.y)
      }
    default:
      return
    }
    
    shape.a = updatedAPoint!
    shape.b = updatedBPoint!
  }
}
