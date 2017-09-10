//
//  PasswordInput.swift
//  v-Channel
//
//  Created by Сергей Сейтов on 16.02.17.
//  Copyright © 2016 ArchiSec Solutions, Ltd. All rights reserved.//
//

import UIKit

class HostInput: LGAlertView, TextFieldContainerDelegate {
    
    @IBOutlet weak var hostField: TextFieldContainer!
    @IBOutlet weak var portField: TextFieldContainer!
    
    var handler:CompletionTextBlock?

    class func hostDialog(cancelHandler:CompletionBlock?, acceptHandler:CompletionTextBlock?) -> HostInput? {
        if let hostInput = Bundle.main.loadNibNamed("HostInput", owner: nil, options: nil)?.first as? HostInput {
            hostInput.cancelButton.setTitle("Cancel", for: .normal)
            hostInput.otherButton.setTitle("Ok", for: .normal)
            
            hostInput.cancelButtonBlock = { alert in
                cancelHandler!()
            }
            hostInput.otherButtonBlock = { alert in
                hostInput.returnCredentials()
            }
            hostInput.handler = acceptHandler
            
            hostInput.hostField.delegate = hostInput
            hostInput.hostField.placeholder = "XXX.XXX.XXX.XXX"
            hostInput.hostField.returnType = .done
            hostInput.hostField.textType = .numbersAndPunctuation
            
            hostInput.portField.delegate = hostInput
            hostInput.portField.placeholder = "PORT"
            hostInput.portField.setText("445")
            hostInput.portField.returnType = .done
            hostInput.portField.textType = .numbersAndPunctuation
            
            UIApplication.shared.sendAction(#selector(UIApplication.resignFirstResponder), to: nil, from: nil, for: nil)
            NotificationCenter.default.addObserver(hostInput, selector: #selector(LGAlertView.keyboardWillChange(_:)), name: Notification.Name.UIKeyboardWillChangeFrame, object: nil)
            
            return hostInput
        } else {
            return nil
        }
    }
    
    func textDone(_ sender:TextFieldContainer, text:String?) {
    }
    
    func textChange(_ sender:TextFieldContainer, text:String?) -> Bool {
        return true
    }
    
    override func dismiss() {
        super.dismiss()
        NotificationCenter.default.removeObserver(self, name: Notification.Name.UIKeyboardDidChangeFrame, object: nil)
    }

    func returnCredentials() {
        handler!(hostField.text(), portField.text())
        dismiss()
    }

}
