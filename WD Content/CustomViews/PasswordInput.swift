//
//  PasswordInput.swift
//  v-Channel
//
//  Created by Сергей Сейтов on 16.02.17.
//  Copyright © 2016 ArchiSec Solutions, Ltd. All rights reserved.//
//

import UIKit

typealias CompletionBlock = () -> Void
typealias CompletionTextBlock = (String, String) -> Void

class PasswordInput: LGAlertView, TextFieldContainerDelegate {
    
    @IBOutlet weak var userField: TextFieldContainer!
    @IBOutlet weak var passwordField: TextFieldContainer!
   
    var handler:CompletionTextBlock?
    
    class func authDialog(title:String, message:String, cancelHandler:CompletionBlock?, acceptHandler:CompletionTextBlock?) -> PasswordInput? {
        if let textInput = Bundle.main.loadNibNamed("PasswordInput", owner: nil, options: nil)?.first as? PasswordInput {
            textInput.titleLabel.text = title
            textInput.messageLabel.text = message
            textInput.cancelButton.setTitle("Cancel", for: .normal)
            textInput.otherButton.setTitle("Ok", for: .normal)
            
            textInput.cancelButtonBlock = { alert in
                cancelHandler!()
            }
            textInput.otherButtonBlock = { alert in
                textInput.returnCredentials()
            }
            textInput.handler = acceptHandler
            
            textInput.userField.delegate = textInput
            textInput.userField.placeholder = "user name"
            textInput.userField.returnType = .next
            textInput.userField.textType = .emailAddress
            
            textInput.passwordField.delegate = textInput
            textInput.passwordField.placeholder = "password"
            textInput.passwordField.returnType = .done
            textInput.userField.textType = .default
            textInput.passwordField.secure = true
            
            UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
            NotificationCenter.default.addObserver(textInput, selector: #selector(LGAlertView.keyboardWillChange(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)

            return textInput
        } else {
            return nil
        }
    }
    
    override func dismiss() {
        super.dismiss()
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardDidChangeFrame, object: nil)
    }
    
    func returnCredentials() {
        handler!(userField.text(), passwordField.text())
        dismiss()
    }
    
    func textDone(_ sender:TextFieldContainer, text:String?) {
        if sender == userField {
            passwordField.activate(true)
        } else {
            returnCredentials()
        }
    }
    
    func textChange(_ sender:TextFieldContainer, text:String?) -> Bool {
        return true
    }
}
