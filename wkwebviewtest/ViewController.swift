import UIKit
import WebKit
import JavaScriptCore


class Debug {
    private struct Args: CustomStringConvertible, CustomDebugStringConvertible {
        let args: [Any]
        let separator: String
        var description: String {
            return args.map { "\($0)" }.joined(separator: separator)
        }
        var debugDescription: String {
            return args
                .map { ($0 as? CustomDebugStringConvertible)?.debugDescription ?? "\($0)" }
                .joined(separator: separator)
        }
    }
    
    class func print(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        Swift.print(Args(args: items, separator: separator), separator: separator, terminator: terminator)
        #endif
    }
    
    class func debugPrint(_ items: Any..., separator: String = " ", terminator: String = "\n") {
        #if DEBUG
        Swift.debugPrint(Args(args: items, separator: separator), separator: separator, terminator: terminator)
        #endif
    }
    
    class func dump<T>(_ value: T, name: String? = nil, indent: Int = 0, maxDepth: Int = Int.max, maxItems: Int = Int.max) -> T {
        #if DEBUG
        return Swift.dump(value, name: name, indent: indent, maxDepth: maxDepth, maxItems: maxItems)
        #else
        return value
        #endif
    }
}


class ViewController: UIViewController, WKUIDelegate, WKScriptMessageHandler {
    
    var webView: WKWebView!

    var userContentController: WKUserContentController!
    
    override func loadView() {
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userContentController = WKUserContentController()
        userContentController.add(self, name: "callbackHandler")
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = userContentController
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        view = webView
        
        let myURL = URL(string: "https://letsgo-201314.appspot.com/login")
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
    
    //MARK: - Javascriiptを実行
    func doJavascript(webView: WKWebView, javaScript:String)
    {
        
        Debug.debugPrint("doJavascript:\(javaScript)")
        
        webView.evaluateJavaScript(javaScript,  completionHandler: {
            (object, error) -> Void in
            
            if error == nil && object != nil
            {
                Debug.debugPrint("object: \(object!)")
            }
            else
            {
                Debug.debugPrint("error:\(String(describing: error))")
            }
        })
        
    }
    
    public func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage)
    {
        if(message.name == "callbackHandler")
        {
            Debug.debugPrint("JavaScript is sending a message \(message.body)")
            
            if let dictarray = message.body as? Array<AnyObject>
            {
                
                //Debug.debugPrint("dictarray.count:\(dictarray.count)")
                
                for i in 0..<dictarray.count
                {
                    
                    if let dict:NSDictionary = dictarray[i] as? NSDictionary
                    {
                        
                        let transaction = dict["transaction"] as! String
                        
                        Debug.debugPrint("transaction \(transaction)")
                        
                        if transaction == "getversion"
                        {
                            
                            let identifier = Bundle.main.object(forInfoDictionaryKey: "CFBundleIdentifier") as! String
                            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
                            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
                            
                            let appversion = "バージョン:\(version)-\(build)-\(identifier)"
                            Debug.debugPrint(appversion)
                            doJavascript(webView: webView ,javaScript:"SetVersion('\(appversion)');")
                            
                        }
                    }
                }
            }
        }
        
    }
    
    //MARK: - WKUIDelegate 新しいウィンドウやフレームを指定してコンテンツが開かれようとしているときに呼ばれる。
    func webView(_ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (@escaping () -> Void))
    {
        
        Debug.debugPrint("webView:\(webView) runJavaScriptAlertPanelWithMessage:\(message) initiatedByFrame:\(frame) completionHandler:\(completionHandler)")
        
        let alertController = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler()
        }))
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    //MARK: - WKUIDelegate 新しいウィンドウやフレームを指定してコンテンツが開かれようとしているときに呼ばれる。
    func webView(_ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String, initiatedByFrame frame: WKFrameInfo, completionHandler: (@escaping (Bool) -> Void))
    {
        
        Debug.debugPrint("webView:\(webView) runJavaScriptConfirmPanelWithMessage:\(message) initiatedByFrame:\(frame) completionHandler:\(completionHandler)")
        
        let alertController = UIAlertController(title: frame.request.url?.host, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            completionHandler(false)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler(true)
        }))
        self.present(alertController, animated: true, completion: nil)
        
    }
    
    //MARK: - WKUIDelegate 新しいウィンドウやフレームを指定してコンテンツが開かれようとしているときに呼ばれる。
    func webView(_ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String, defaultText: String?, initiatedByFrame frame: WKFrameInfo, completionHandler: @escaping (String?) -> Void) {
        
        Debug.debugPrint("webView:\(webView) runJavaScriptTextInputPanelWithPrompt:\(prompt) defaultText:\(String(describing: defaultText)) initiatedByFrame:\(frame) completionHandler:\(completionHandler)")
        
        let alertController = UIAlertController(title: frame.request.url?.host, message: prompt, preferredStyle: .alert)
        weak var alertTextField: UITextField!
        alertController.addTextField { textField in
            textField.text = defaultText
            alertTextField = textField
        }
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            completionHandler(nil)
        }))
        alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            completionHandler(alertTextField.text)
        }))
        self.present(alertController, animated: true, completion: nil)
        
    }
    
}
