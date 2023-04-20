//
//  SelectionIndicatorView.swift
//  Drawsana
//
//  Created by cleanmac on 09/04/23.
//  Copyright © 2023 Asana. All rights reserved.
//

import UIKit

public enum PointRectangle {
  case aPoint
  case bPoint
  case cPoint
  case noPoint
}

public class SelectionIndicatorView: UIView {
  private let pointWidthAndHeight: CGFloat = 10
  private var pointCornerRadius: CGFloat {
    pointWidthAndHeight / 2
  }
  
  private(set) var selectionLayer = CAShapeLayer()
  private var aPointLayer = CAShapeLayer()
  private var bPointLayer = CAShapeLayer()
  private var cPointLayer = CAShapeLayer()
  
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
  
  private func configurePoint(using pointLayer: inout CAShapeLayer, point: CGPoint, color: UIColor) {
    let rect = CGRect(
      x: point.x - frame.minX - pointCornerRadius,
      y: point.y - frame.minY - pointCornerRadius,
      width: pointWidthAndHeight,
      height: pointWidthAndHeight)
    
    pointLayer.frame = bounds
    pointLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: pointCornerRadius).cgPath
    pointLayer.fillColor = color.cgColor
  }
  
  private func updatePoint(using pointLayer: inout CAShapeLayer, point: CGPoint) {
    let rect = CGRect(
      x: point.x - frame.minX - pointCornerRadius,
      y: point.y - frame.minY - pointCornerRadius,
      width: pointWidthAndHeight,
      height: pointWidthAndHeight)
    
    pointLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: pointCornerRadius).cgPath
    pointLayer.setNeedsDisplay()
  }
  
  public func configurePointsForShapeWithTwoPoints(aPoint: CGPoint, bPoint: CGPoint, color: UIColor = .black) {
    configurePoint(using: &aPointLayer, point: aPoint, color: color)
    configurePoint(using: &bPointLayer, point: bPoint, color: color)
    
    layer.addSublayer(aPointLayer)
    layer.addSublayer(bPointLayer)
  }
  
  public func configurePointsForShapeWithThreePoints(aPoint: CGPoint, bPoint: CGPoint, cPoint: CGPoint, color: UIColor = .black) {
    configurePoint(using: &aPointLayer, point: aPoint, color: color)
    configurePoint(using: &bPointLayer, point: bPoint, color: color)
    configurePoint(using: &cPointLayer, point: cPoint, color: color)
    
    layer.addSublayer(aPointLayer)
    layer.addSublayer(bPointLayer)
    layer.addSublayer(cPointLayer)
  }
  
  public func updatePointsForShapeWithTwoPoints(aPoint: CGPoint, bPoint: CGPoint) {
    updatePoint(using: &aPointLayer, point: aPoint)
    updatePoint(using: &bPointLayer, point: bPoint)
  }
  
  public func updatePointsForShapeWithThreePoints(aPoint: CGPoint, bPoint: CGPoint, cPoint: CGPoint) {
    updatePoint(using: &aPointLayer, point: aPoint)
    updatePoint(using: &bPointLayer, point: bPoint)
    updatePoint(using: &cPointLayer, point: cPoint)
  }
  
  public func removeAllPointsFromLayer() {
    if let sublayers = layer.sublayers {
      for sublayer in sublayers {
        guard sublayer != selectionLayer else { return }
        if sublayer is CAShapeLayer {
          sublayer.removeFromSuperlayer()
        }
      }
    }
  }
}
