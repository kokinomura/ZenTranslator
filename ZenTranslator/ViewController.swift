//
//  ViewController.swift
//  ZenTranslator
//
//  Created by nomura on 2014/06/18.
//  Copyright (c) 2014年 IMG SRC. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITextFieldDelegate, NSXMLParserDelegate{
                            
    @IBOutlet var inputTextField : UITextField
    @IBOutlet var translateTextField : UITextField
    @IBOutlet var creditLabel : UILabel
    
    var accessToken = ""
    var tmpParsedString = ""
    
    // view management -------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // input text field
        inputTextField.delegate = self
        
        // credit label
        var attributedText = NSMutableAttributedString(string:creditLabel.text)
        attributedText.addAttribute(NSKernAttributeName, value:1.6, range:NSMakeRange(0, attributedText.length))
        creditLabel.attributedText = attributedText;
    }
    
    override func viewDidAppear(animated: Bool) {
        getAccessToken()
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
            var contents : NSDictionary = NSJSONSerialization.JSONObjectWithData(result, options: nil, error: nil) as NSDictionary
            println(contents)
            accessToken = contents.objectForKey("access_token")? as String
        }
    }
    
    func translate(text: String) -> String {
        let urlStr = "http://api.microsofttranslator.com/v2/Http.svc/Translate?text="
                   + text.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.alphanumericCharacterSet())
                   + "&from=" + "en" + "&to=" + "ja"
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
            return tmpParsedString
        } else {
            return ""
        }
    }
    
    //-----------------------------------------------
    
    // delegate method
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        let translated = translate(textField.text)
        translateTextField.text = translated
        
        textField.resignFirstResponder()
        return true
    }
    
    @IBAction func edtingDidBegin(textField: UITextField) {
        textField.text = ""
        translateTextField.text = ""
    }
    
    func parser(parser: NSXMLParser, elementName: NSString, namespaceURI: NSString, qName: NSString, attributeDict: NSDictionary) {

    }

    func parser(parser: NSXMLParser, elementName: NSString, namespaceURI: NSString, qName: NSString) {
        
    }
    
    func parser(parser: NSXMLParser, foundCharacters: NSString) {
        tmpParsedString = foundCharacters as String
    }
    
    func parser(parser: NSXMLParser, parseError: NSError) {
        
    }
    
}

