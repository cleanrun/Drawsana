//
//  TextToolEditingViewController.swift
//  Drawsana
//
//  Created by cleanmac on 23/04/23.
//  Copyright © 2023 Asana. All rights reserved.
//

import UIKit

public class TextToolEditingViewController: UIViewController {
  
  private var textField: UITextField!
  
  /// The original text of the TextShape.
  private var originalText: String
  
  /// The callback when this view controller is dismissed.
  /// Use this callback to handle changes in your text and apply
  /// it to the text shape.
  private var dismissalCallback: ((String) -> Void)?
  
  public init(originalText: String, dismissalCallback: ((String) -> Void)? = nil) {
    self.originalText = originalText
    self.dismissalCallback = dismissalCallback
    super.init(nibName: nil, bundle: nil)
    self.modalPresentationStyle = .overCurrentContext
  }
  
  required init?(coder: NSCoder) {
    fatalError("Storyboard/XIB initializations are not supported")
  }
  
  public override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    textField.becomeFirstResponder()
  }
  
  public override func loadView() {
    super.loadView()
    view.backgroundColor = UIColor.black.withAlphaComponent(0.8)
    
    textField = UITextField()
    textField.translatesAutoresizingMaskIntoConstraints = false
    textField.delegate = self
    textField.returnKeyType = .done
    textField.placeholder = "Your text here"
    textField.textAlignment = .center
    if !originalText.isEmpty {
      textField.text = originalText
    }
    
    view.addSubview(textField)
    NSLayoutConstraint.activate([
      textField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
      textField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
      textField.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
    ])
    
    textField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
  }
  
  @objc private func textFieldDidChange(_ sender: UITextField) {
    originalText = sender.text ?? ""
  }
}

extension TextToolEditingViewController: UITextFieldDelegate {
  public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    dismiss(animated: false) { [unowned self] in
      self.dismissalCallback?(originalText)
    }
    return true
  }
}
