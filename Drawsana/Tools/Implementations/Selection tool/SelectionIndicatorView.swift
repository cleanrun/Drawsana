//
//  SelectionIndicatorView.swift
//  Drawsana
//
//  Created by cleanmac on 09/04/23.
//  Copyright © 2023 Asana. All rights reserved.
//

import UIKit

public class SelectionIndicatorView: UIView {
  
  private enum PointRectangle {
    case aPoint
    case bPoint
    case cPoint
    case dPoint
    case ePoint
    case fPoint
    case gPoint
    case hPoint
  }
  
  private let pointWidthAndHeight: CGFloat = 10
  private var pointCornerRadius: CGFloat {
    pointWidthAndHeight / 2
  }
  
  private(set) var selectionLayer = CAShapeLayer()

  /// These points represents the dragging points to resize the shape.
  /// So for example, you have a bounding rectangle of a shape, the
  /// points looks pretty much like this:
  /*
    [A]----[B]----[C]
     |             |
     |             |
    [D]           [E]
     |             |
     |             |
    [F]----[G]----[H]
  */
  
  private(set) var aPointLayer = CAShapeLayer()
  private(set) var bPointLayer = CAShapeLayer()
  private(set) var cPointLayer = CAShapeLayer()
  private(set) var dPointLayer = CAShapeLayer()
  private(set) var ePointLayer = CAShapeLayer()
  private(set) var fPointLayer = CAShapeLayer()
  private(set) var gPointLayer = CAShapeLayer()
  private(set) var hPointLayer = CAShapeLayer()
  
  init() {
    super.init(frame: .zero)
    setSelectionLayer()
  }

  override init(frame: CGRect) {
    super.init(frame: frame)
    setSelectionLayer()
  }
  
  required init?(coder: NSCoder) {
    fatalError("Not supported for this view")
  }
  
  public override func layoutSubviews() {
    super.layoutSubviews()
    setPointLayers()
  }
  
  private func setSelectionLayer() {
    layer.shadowColor = UIColor.white.cgColor
    layer.shadowOffset = .zero
    layer.shadowRadius = 1
    layer.shadowOpacity = 1
    
    selectionLayer.strokeColor = UIColor.black.cgColor
    selectionLayer.lineWidth = 2
    selectionLayer.lineDashPattern = [4, 4]
    selectionLayer.fillColor = nil
    selectionLayer.frame = bounds
    selectionLayer.path = UIBezierPath(rect: bounds).cgPath
    
    layer.addSublayer(selectionLayer)
  }
  
  private func setPointLayers() {
    configurePoint(using: &aPointLayer, type: .aPoint)
    configurePoint(using: &bPointLayer, type: .bPoint)
    configurePoint(using: &cPointLayer, type: .cPoint)
    configurePoint(using: &dPointLayer, type: .dPoint)
    configurePoint(using: &ePointLayer, type: .ePoint)
    configurePoint(using: &fPointLayer, type: .fPoint)
    configurePoint(using: &gPointLayer, type: .gPoint)
    configurePoint(using: &hPointLayer, type: .hPoint)
    
    layer.addSublayer(aPointLayer)
    layer.addSublayer(bPointLayer)
    layer.addSublayer(cPointLayer)
    layer.addSublayer(dPointLayer)
    layer.addSublayer(ePointLayer)
    layer.addSublayer(fPointLayer)
    layer.addSublayer(gPointLayer)
    layer.addSublayer(hPointLayer)
  }
  
  private func createPointPath(using point: PointRectangle) -> CGPath {
    var rect: CGRect!
    
    switch point {
    case .aPoint:
      rect = CGRect(x: bounds.minX - pointCornerRadius, y: bounds.minY - pointCornerRadius, width: pointWidthAndHeight, height: pointWidthAndHeight)
    case .bPoint:
      rect = CGRect(x: bounds.midX - pointCornerRadius, y: bounds.minY - pointCornerRadius, width: pointWidthAndHeight, height: pointWidthAndHeight)
    case .cPoint:
      rect = CGRect(x: bounds.maxX - pointCornerRadius, y: bounds.minY - pointCornerRadius, width: pointWidthAndHeight, height: pointWidthAndHeight)
    case .dPoint:
      rect = CGRect(x: bounds.minX - pointCornerRadius, y: bounds.midY - pointCornerRadius, width: pointWidthAndHeight, height: pointWidthAndHeight)
    case .ePoint:
      rect = CGRect(x: bounds.maxX - pointCornerRadius, y: bounds.midY - pointCornerRadius, width: pointWidthAndHeight, height: pointWidthAndHeight)
    case .fPoint:
      rect = CGRect(x: bounds.minX - pointCornerRadius, y: bounds.maxY - pointCornerRadius, width: pointWidthAndHeight, height: pointWidthAndHeight)
    case .gPoint:
      rect = CGRect(x: bounds.midX - pointCornerRadius, y: bounds.maxY - pointCornerRadius, width: pointWidthAndHeight, height: pointWidthAndHeight)
    case .hPoint:
      rect = CGRect(x: bounds.maxX - pointCornerRadius, y: bounds.maxY - pointCornerRadius, width: pointWidthAndHeight, height: pointWidthAndHeight)
    }
    
    return UIBezierPath(roundedRect: rect, cornerRadius: pointCornerRadius).cgPath
  }
  
  private func configurePoint(using pointLayer: inout CAShapeLayer, type: PointRectangle) {
    pointLayer.frame = bounds
    pointLayer.path = createPointPath(using: type)
    pointLayer.fillColor = UIColor.black.cgColor
  }
}
