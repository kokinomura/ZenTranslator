//
//  ViewController.swift
//  ZenTranslator
//
//  Created by nomura on 2014/06/18.
//  Copyright (c) 2014年 IMG SRC. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, UITextViewDelegate, NSXMLParserDelegate, V8HorizontalPickerViewDelegate, V8HorizontalPickerViewDataSource {
                            
    @IBOutlet var inputTextField : UITextField
    @IBOutlet var translateTextField: PlaceholderTextView
    @IBOutlet var creditLabel : UILabel
    
    var accessToken : String = ""
    var tmpParsedString : String?
    
    // Languages
    let langCodes = langData.langCodes
    let langNames = langData.langNames
    
    var fromLangCode = ""
    var toLangCode = ""

    @IBOutlet var fromLangView : V8HorizontalPickerView
    @IBOutlet var toLangView : V8HorizontalPickerView
    var fromLangsHideTimer : NSTimer?
    var toLangsHideTimer : NSTimer?    
    
    // view management -------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // hide keyboard
        var tapRecognizer = UITapGestureRecognizer(target: self, action:"hideKeyboard")
        self.view.addGestureRecognizer(tapRecognizer)
        
        // text fields
        inputTextField.delegate = self
        translateTextField.delegate = self
        translateTextField.setPlaceHolder("翻訳")
        
        // credit label
        var attributedText = NSMutableAttributedString(string:creditLabel.text)
        attributedText.addAttribute(NSKernAttributeName, value:1.6, range:NSMakeRange(0, attributedText.length))
        creditLabel.attributedText = attributedText;
        
        // Lang Views
        fromLangView.backgroundColor = UIColor.clearColor()
        fromLangView.selectedTextColor = UIColor.whiteColor()
        fromLangView.textColor = UIColor.clearColor()
        fromLangView.delegate = self
        fromLangView.dataSource = self
        fromLangView.elementFont = UIFont(name:"AvenirNext-Bold", size:24.0)
        fromLangView.selectionPoint = CGPointMake(fromLangView.bounds.size.width/2, CGFloat(0))
        fromLangView.scrollEnabled = true
        
        fromLangView.reloadData()
        
        toLangView.backgroundColor = UIColor.clearColor()
        toLangView.selectedTextColor = UIColor.whiteColor()
        toLangView.textColor = UIColor.clearColor()
        toLangView.delegate = self
        toLangView.dataSource = self
        toLangView.elementFont = UIFont(name:"AvenirNext-Regular", size:15.0)
        toLangView.selectionPoint = CGPointMake(toLangView.bounds.size.width/2, CGFloat(0))
        toLangView.scrollEnabled = true
        
        toLangView.reloadData()
        
        // ここで背景色と同じ色の画像を用意すればフェードもできる
//        var leftFade = UIImageView(image:UIImage(named:"left_fade"))
//        fromLangView.leftEdgeView = leftFade
        
        UITextField.appearance().tintColor = UIColor.grayColor()
        UITextView.appearance().tintColor = UIColor.grayColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        getAccessToken()
        let enLangCode = 4
        let jaLangCode = 15
        fromLangView.scrollToElement(jaLangCode, animated:false)
        toLangView.scrollToElement(enLangCode, animated:false, completion:{
            (finished: Bool) in
            self.showLangs(self.toLangView)
            self.showLangs(self.fromLangView)
        })
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //-----------------------------------------------
    
    // methods --------------------------------------
    
    func getAccessToken() {
        let clientId = "zen_translator"
        let clientSecret = "TXN4VOEx1Kn0i2J1xP+x6aIH0uGrLOISlnF0D4pZOmk="
        let encodedClientSecret = clientSecret.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())
        let query = "client_id=" + clientId + "&client_secret=" + encodedClientSecret
                  + "&scope=http://api.microsofttranslator.com&grant_type=client_credentials"
        let queryData = query.dataUsingEncoding(NSUTF8StringEncoding)
        
        let url = NSURL.URLWithString("https://datamarket.accesscontrol.windows.net/v2/OAuth2-13")
        var request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "POST"
        request.HTTPBody = queryData
        
        var response : AutoreleasingUnsafePointer<NSURLResponse?> = nil
        let optionalResult : NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse: response, error: nil)
        
        if let result = optionalResult {
            let contents : NSDictionary = NSJSONSerialization.JSONObjectWithData(result, options: nil, error: nil) as NSDictionary
            println(contents)
            
            // get access token in <expires_in> sec
            accessToken = contents.objectForKey("access_token") as String
            let expires_in_str = contents.objectForKey("expires_in") as NSString
            let expires_in = Int64(expires_in_str.intValue) * Int64(NSEC_PER_SEC)
            var time = dispatch_time(DISPATCH_TIME_NOW, expires_in)
            dispatch_after(time, dispatch_get_main_queue(), {
                self.getAccessToken()
            })
        }
    }
    
    func translate(text: String) -> String {
        let urlStr = "http://api.microsofttranslator.com/v2/Http.svc/Translate?text="
                   + text.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())
                   + "&from=" + fromLangCode + "&to=" + toLangCode
        let url = NSURL.URLWithString(urlStr)
        let authToken = "Bearer" + " " + accessToken
        
        var request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = "GET"
        request.addValue(authToken, forHTTPHeaderField:"Authorization")
        
        var optionalResult : NSData? = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: nil)
        if let result = optionalResult {
            var parser = NSXMLParser(data:result)
            parser.delegate = self
            parser.parse()
            if let parsedString = tmpParsedString {
                tmpParsedString = ""
                return parsedString
            } else {
                return ""
            }
        } else {
            return ""
        }
    }
}    
 
// MARK: - delegate methods
extension ViewController {

    // Text Field
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField.text != "" {
            let translated = translate(textField.text)
            translateTextField.setTextPlaceholder(translated)
        }
        
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func edtingDidBegin(textField: UITextField) {
        translateTextField.setTextPlaceholder("")
    }
    
    //
    func hideKeyboard() {
        inputTextField.resignFirstResponder()
        translateTextField.resignFirstResponder()
    }
    
    // Parse XML
    func parser(parser: NSXMLParser, elementName: NSString, namespaceURI: NSString, qName: NSString, attributeDict: NSDictionary) {

    }

    func parser(parser: NSXMLParser, elementName: NSString, namespaceURI: NSString, qName: NSString) {
        
    }
    
    func parser(parser: NSXMLParser, foundCharacters: NSString) {
        tmpParsedString = foundCharacters as String
    }
    
    func parser(parser: NSXMLParser, parseError: NSError) {
        
    }
    
    // Horizontal View
    func numberOfElementsInHorizontalPickerView(picker: V8HorizontalPickerView!) -> Int {
        assert(langNames.count == langCodes.count)
        return langNames.count
    }
    
    func horizontalPickerView(picker: V8HorizontalPickerView!, titleForElementAtIndex: Int) -> String {
        return langNames[titleForElementAtIndex]
    }
    
    func horizontalPickerView(picker: V8HorizontalPickerView!, widthForElementAtIndex: Int) -> Int {
        let langName = langNames[widthForElementAtIndex] as NSString
        let textSize = langName.sizeWithAttributes([NSFontAttributeName: picker.elementFont])
        let spaceSize = "    ".sizeWithAttributes([NSFontAttributeName: picker.elementFont])
        return Int(textSize.width + spaceSize.width)
    }
    
    func horizontalPickerView(picker: V8HorizontalPickerView!, didSelectElementAtIndex: Int) {
        if picker == fromLangView {
            fromLangCode = langCodes[didSelectElementAtIndex]
            if let timer = fromLangsHideTimer {
                timer.invalidate()
            }
            fromLangsHideTimer = NSTimer.scheduledTimerWithTimeInterval(0.8, target:self, selector:"hideFromLangs:", userInfo:nil, repeats:false)
        } else {
            toLangCode = langCodes[didSelectElementAtIndex]
            if let timer = toLangsHideTimer {
                timer.invalidate()
            }
            toLangsHideTimer = NSTimer.scheduledTimerWithTimeInterval(0.8, target:self, selector:"hideToLangs:", userInfo:nil, repeats:false)
        }

    }
    
    func horizontalPickerViewWillBeginDragging(picker: V8HorizontalPickerView!) {
        showLangsImmediately(picker)
    }
    
    func horizontalPickerViewLongPressed(picker: V8HorizontalPickerView!) {
        showLangs(picker)
    }
    
    func showLangs(picker: V8HorizontalPickerView!) {
        var alpha : Float
        if picker == fromLangView {
            alpha = 0.2 
        } else {
            alpha = 0.4
        }
        UIView.transitionWithView(
            picker,
            duration:0.25, 
            options:UIViewAnimationOptions.TransitionCrossDissolve, 
            animations:{
                picker.textColor = UIColor(white:1.0, alpha:CGFloat(alpha))
            }, 
            completion:nil
        )
        picker.reloadData()
    }
    
    func hideFromLangs(timer: NSTimer) {
        UIView.transitionWithView(
            self.fromLangView, 
            duration:0.25, 
            options:UIViewAnimationOptions.TransitionCrossDissolve, 
            animations:{
                self.fromLangView.textColor = UIColor.clearColor()
            }, 
            completion:nil
        )
        self.fromLangView.reloadData()  
    }
    
    func hideToLangs(timer: NSTimer) {
        UIView.transitionWithView(
            self.toLangView, 
            duration:0.25, 
            options:UIViewAnimationOptions.TransitionCrossDissolve, 
            animations:{
                self.toLangView.textColor = UIColor.clearColor()
            }, 
            completion:nil
        )
        self.toLangView.reloadData()  
    }

    func showLangsImmediately(picker: V8HorizontalPickerView!) {
        var alpha : Float
        if picker == fromLangView {
            alpha = 0.2
        } else {
            alpha = 0.4
        }
        picker.textColor = UIColor(white:1.0, alpha:CGFloat(alpha))
        dispatch_async(dispatch_get_main_queue()) {
            picker.reloadData()
        }
    }
}

