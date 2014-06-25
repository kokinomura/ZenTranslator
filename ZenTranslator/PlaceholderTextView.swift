//
//  HistoryView.swift
//  ZenTranslator
//
//  Created by nomura on 2014/06/20.
//  Copyright (c) 2014年 IMG SRC. All rights reserved.
//

import UIKit

class PlaceholderTextView : UITextView {
    var textField : UITextField?
    var placeholder = ""

    override func awakeFromNib() {
        textField = UITextField(frame: CGRect(x: 0, y: 0, width:self.bounds.size.width, height:self.bounds.size.height))
        textField!.backgroundColor = self.backgroundColor
        textField!.userInteractionEnabled = false
        textField!.font = self.font
        textField!.textColor = self.textColor
        textField!.clearButtonMode = UITextFieldViewMode.Never
        textField!.textAlignment = self.textAlignment
        textField!.minimumFontSize = 10
        textField!.adjustsFontSizeToFitWidth = true
        textField!.borderStyle = UITextBorderStyle.None
        self.addSubview(textField)
        
        self.textContainerInset = UIEdgeInsets(top: -2.0, left: 0.0, bottom: 0.0, right: -5.0)
    }
    
    func setPlaceHolder(str: String) {
        textField!.placeholder = str
        placeholder = str
    }
    
    func setTextPlaceholder(str: String) {
        self.text = str
        if self.text == "" {
            textField!.placeholder = placeholder
        } else {
            textField!.placeholder = nil
        }
    }
}