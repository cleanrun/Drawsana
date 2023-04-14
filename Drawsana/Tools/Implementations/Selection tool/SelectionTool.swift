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
  private var originalCPoint: CGPoint?
  private var updatedAPoint: CGPoint?
  private var updatedBPoint: CGPoint?
  private var updatedCPoint: CGPoint?
  
  private var originalTransform: ShapeTransform?
  private var updatedTransform: ShapeTransform?
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
  
  private var drawsanaView: DrawsanaView!

  public init(delegate: SelectionToolDelegate? = nil, usingSelectionToolIndicatorViewFrom drawsanaView: DrawsanaView) {
    self.delegate = delegate
    self.selectionToolIndicatorView = drawsanaView.selectionIndicatorView
    self.drawsanaView = drawsanaView
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
    if let selectedShape = context.toolSettings.selectedShape {
      if selectedShape.hitTest(point: point) {
        if let delegate = delegate {
          delegate.selectionToolDidTapOnAlreadySelectedShape(selectedShape)
        } else {
          // Default behavior: deselect the shape
          context.toolSettings.selectedShape = nil
        }
        removeResizePoints()
        return
      }
    }

    updateSelection(context: context, context.drawing.shapes
      .compactMap({ $0 as? ShapeSelectable })
      .filter({ $0.hitTest(point: point) })
      .last)
    
    if let shape = context.drawing.shapes
      .compactMap({ $0 as? ShapeSelectable })
      .filter({ $0.hitTest(point: point) })
      .last {
      setResizePoints(shape: shape)
      
      if shape is ShapeWithTwoPoints {
        let castedShape = shape as! ShapeWithTwoPoints
        print("shape is two points, a: \(castedShape.a), b: \(castedShape.b)")
      }
    } else {
      removeResizePoints()
    }
  }

  public func handleDragStart(context: ToolOperationContext, point: CGPoint) {
    guard let selectedShape = context.toolSettings.selectedShape else {
      isDraggingShape = false
      return
    }
    
    if let selectedShape = context.toolSettings.selectedShape {
      if let selectedShape = context.toolSettings.selectedShape {
        selectionPointAction = getIfDraggingResizePoint(
          from: drawsanaView.convert(
            point,
            to: selectionToolIndicatorView),
          shape: selectedShape)

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
      calculatePointChangeForPanGesture(point: point, shape: selectedShape)
      context.toolSettings.isPersistentBufferDirty = true
    }
  }
  
  public func handleDragEnd(context: ToolOperationContext, point: CGPoint) {
    guard
      isDraggingShape,
      let originalTransform = originalTransform,
      let selectedShape = context.toolSettings.selectedShape,
      let startPoint = startPoint else
    {
      isDraggingShape = false
      return
    }
    
    let delta = CGPoint(x: point.x - startPoint.x, y: point.y - startPoint.y)
    
    if selectionPointAction == .movingAction {
      context.operationStack.apply(operation: ChangeTransformOperation(
        shape: selectedShape,
        transform: originalTransform,
        originalTransform: originalTransform))
      
      applyMovingOperation(shape: selectedShape, using: context, delta: delta)
      
      context.toolSettings.isPersistentBufferDirty = true
      updatedTransform = originalTransform.translated(by: delta)
      isDraggingShape = false
    } else {
      context.operationStack.apply(operation: ChangeTransformOperation(
        shape: selectedShape,
        transform: originalTransform,
        originalTransform: originalTransform))
      
      applyEditOperation(shape: selectedShape, using: context, delta: delta)
      
      context.toolSettings.isPersistentBufferDirty = true
      updatedTransform = originalTransform.translated(by: delta)
      isDraggingShape = false
    }
    
    removeOriginalPoints()
    selectionPointAction = nil
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
  
  private func setResizePoints(shape: ShapeSelectable) {
    if shape is ShapeWithTwoPoints {
      let castedShape = shape as! ShapeWithTwoPoints
      selectionToolIndicatorView.configurePointsForShapeWithTwoPoints(aPoint: castedShape.a, bPoint: castedShape.b)
    } else if shape is ShapeWithThreePoints {
      let castedShape = shape as! ShapeWithThreePoints
      selectionToolIndicatorView.configurePointsForShapeWithThreePoints(aPoint: castedShape.a, bPoint: castedShape.b, cPoint: castedShape.c)
    }
  }
  
  private func removeResizePoints() {
    selectionToolIndicatorView.removeAllPointsFromLayer()
  }
  
  private func getIfDraggingResizePoint(from point: CGPoint, shape: ShapeSelectable) -> SelectionPointAction? {
    if shape is ShapeWithTwoPoints {
      let castedShape = shape as! ShapeWithTwoPoints
      if castedShape.getAPointArea().contains(point) {
        return .aPoint
      } else if castedShape.getBPointArea().contains(point) {
        return .bPoint
      }
    } else if shape is ShapeWithThreePoints {
      let castedShape = shape as! ShapeWithThreePoints
      if castedShape.getAPointArea().contains(point) {
        return .aPoint
      } else if castedShape.getBPointArea().contains(point) {
        return .bPoint
      } else if castedShape.getCPointArea().contains(point) {
        return .cPoint
      }
    }
    
    return .movingAction
  }
  
  private func setOriginalPoints(shape: ShapeSelectable) {
    if shape is ShapeWithTwoPoints {
      let castedShape = shape as! ShapeWithTwoPoints
      originalAPoint = castedShape.a
      originalBPoint = castedShape.b
    } else if shape is ShapeWithThreePoints {
      let castedShape = shape as! ShapeWithThreePoints
      originalAPoint = castedShape.a
      originalBPoint = castedShape.b
      originalCPoint = castedShape.c
    }
  }
  
  private func removeOriginalPoints() {
    originalAPoint = nil
    originalBPoint = nil
    originalCPoint = nil
  }
  
  private func calculatePointChangeForPanGesture(point: CGPoint, shape: ShapeSelectable) {
    if shape is ShapeWithTwoPoints {
      var castedShape = shape as! ShapeWithTwoPoints
      switch selectionPointAction {
      case .aPoint:
        castedShape.a = point
      case .bPoint:
        castedShape.b = point
      default:
        break
      }
      selectionToolIndicatorView.updatePointsForShapeWithTwoPoints(aPoint: castedShape.a, bPoint: castedShape.b)
    } else if shape is ShapeWithThreePoints {
      var castedShape = shape as! ShapeWithThreePoints
      switch selectionPointAction {
      case .aPoint:
        castedShape.a = point
      case .bPoint:
        castedShape.b = point
      case .cPoint:
        castedShape.c = point
      default:
        break
      }
      selectionToolIndicatorView.updatePointsForShapeWithThreePoints(aPoint: castedShape.a, bPoint: castedShape.b, cPoint: castedShape.c)
    }
  }
  
  private func applyMovingOperation(shape: ShapeSelectable, using context: ToolOperationContext, delta: CGPoint) {
    if shape is ShapeWithTwoPoints {
      let castedShape = shape as! ShapeWithTwoPoints
      context.operationStack.apply(operation: ResizeShapeWithTwoPointsOperation(
        shape: castedShape,
        originalAPoint: castedShape.a,
        originalBPoint: castedShape.b,
        updatedAPoint: castedShape.a.applying(originalTransform!.translated(by: delta).affineTransform),
        updatedBPoint: castedShape.b.applying(originalTransform!.translated(by: delta).affineTransform)
      ))
    } else if shape is ShapeWithThreePoints {
      let castedShape = shape as! ShapeWithThreePoints
      context.operationStack.apply(operation: ResizeShapeWithThreePointsOperation(
        shape: castedShape,
        originalAPoint: castedShape.a,
        originalBPoint: castedShape.b,
        originalCPoint: castedShape.c,
        updatedAPoint: castedShape.a.applying(originalTransform!.translated(by: delta).affineTransform),
        updatedBPoint: castedShape.b.applying(originalTransform!.translated(by: delta).affineTransform),
        updatedCPoint: castedShape.c.applying(originalTransform!.translated(by: delta).affineTransform)
      ))
    }
  }
  
  private func applyEditOperation(shape: ShapeSelectable, using context: ToolOperationContext, delta: CGPoint) {
    if shape is ShapeWithTwoPoints {
      let castedShape = shape as! ShapeWithTwoPoints
      context.operationStack.apply(operation: ResizeShapeWithTwoPointsOperation(
        shape: castedShape,
        originalAPoint: originalAPoint!,
        originalBPoint: originalBPoint!,
        updatedAPoint: castedShape.a,
        updatedBPoint: castedShape.b))
    } else if shape is ShapeWithThreePoints {
      let castedShape = shape as! ShapeWithThreePoints
      context.operationStack.apply(operation: ResizeShapeWithThreePointsOperation(
        shape: castedShape,
        originalAPoint: originalAPoint!,
        originalBPoint: originalBPoint!,
        originalCPoint: originalCPoint!,
        updatedAPoint: castedShape.a,
        updatedBPoint: castedShape.b,
        updatedCPoint: castedShape.c
      ))
    }
  }
}
