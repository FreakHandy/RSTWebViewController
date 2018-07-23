//
//  RSTWebViewController.swift
//  RSTWebViewController
//
//  Created by Riley Testut on 12/23/14.
//  Copyright (c) 2014 Riley Testut. All rights reserved.
//

import UIKit
import WebKit

public extension RSTWebViewController {
    
    //MARK: Update UI
    
    func updateToolbarItems()
    {
        if self.webView.isLoading
        {
            self.refreshButton = self.stopLoadingButton
        }
        else
        {
            self.refreshButton = self.reloadButton
        }
        
        if self.showsDoneButton && self.doneButton == nil
        {
            self.doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(RSTWebViewController.dismissWebViewController(_:)))
        }
        else if !self.showsDoneButton && self.doneButton != nil
        {
            self.doneButton = nil
        }
        
        self.backButton.isEnabled = self.webView.canGoBack
        self.forwardButton.isEnabled = self.webView.canGoForward
        
        if self.traitCollection.horizontalSizeClass == .regular
        {
            self.toolbarItems = nil
            
            let fixedSpaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            fixedSpaceItem.width = 20.0
            
            let reloadButtonFixedSpaceItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
            reloadButtonFixedSpaceItem.width = fixedSpaceItem.width
            
            if self.refreshButton == self.stopLoadingButton
            {
                reloadButtonFixedSpaceItem.width = fixedSpaceItem.width + 1
            }
            
            var items = [self.shareButton, fixedSpaceItem, self.refreshButton, reloadButtonFixedSpaceItem, self.forwardButton, fixedSpaceItem, self.backButton, fixedSpaceItem]
            
            if self.showsDoneButton
            {
                items.insert(fixedSpaceItem, at: 0)
                items.insert(self.doneButton!, at: 0)
            }
            
            self.navigationItem.rightBarButtonItems = items
        }
        else
        {
            // We have to set rightBarButtonItems instead of simply rightBarButtonItem to properly clear previous buttons
            self.navigationItem.rightBarButtonItems = self.showsDoneButton ? [self.doneButton!] : nil
            
            let flexibleSpaceItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            self.toolbarItems = [self.backButton, flexibleSpaceItem, self.forwardButton, flexibleSpaceItem, self.refreshButton, flexibleSpaceItem, self.shareButton]
        }
    }
    
}

open class RSTWebViewController: UIViewController {
    
    //MARK: Public Properties
    
    // WKWebView used to display webpages
    open fileprivate(set) var webView: WKWebView
    
    // UIBarButton items. Customizable, and subclasses can override updateToolbarItems() to arrange them however they want
    open var backButton: UIBarButtonItem = UIBarButtonItem(image: nil, style: .plain, target: nil, action: #selector(RSTWebViewController.goBack(_:)))
    open var forwardButton: UIBarButtonItem = UIBarButtonItem(image: nil, style: .plain, target: nil, action: #selector(RSTWebViewController.goForward(_:)))
    open var shareButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: nil, action: #selector(RSTWebViewController.shareLink(_:)))
    
    open var reloadButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: nil, action: #selector(RSTWebViewController.refresh(_:)))
    open var stopLoadingButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .stop, target: nil, action: #selector(RSTWebViewController.refresh(_:)))
    
    open var doneButton: UIBarButtonItem?
    
    // Set to true when presenting modally to show a Done button that'll dismiss itself.
    open var showsDoneButton: Bool = false {
        didSet {
            self.updateToolbarItems()
        }
    }
    
    // Array of activity types that should not be displayed in the UIActivityViewController share sheet
    open var excludedActivityTypes: [String]?
    
    // Array of application-specific UIActivities to handle sharing links via UIActivityViewController
    open var applicationActivities: [UIActivity]?
    
    
    //MARK: Private Properties
    
    fileprivate let initialReqest: URLRequest?
    fileprivate let progressView = UIProgressView()
    fileprivate var ignoreUpdateProgress: Bool = false
    fileprivate var refreshButton: UIBarButtonItem
    
    
    //MARK: Initializers
    
    public required init(request: URLRequest?)
    {
        self.initialReqest = request
        
        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        
        self.refreshButton = self.reloadButton
        
        super.init(nibName: nil, bundle: nil)
        
        self.initialize()
    }
    
    public convenience init (URL: Foundation.URL?)
    {
        if let URL = URL
        {
            self.init(request: URLRequest(url: URL))
        }
        else
        {
            self.init(request: nil)
        }
    }
    
    public convenience init (address: String?)
    {
        if let address = address
        {
            self.init(URL: URL(string: address))
        }
        else
        {
            self.init(URL: nil)
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        let configuration = WKWebViewConfiguration()
        self.webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        
        self.refreshButton = self.reloadButton
        
        self.initialReqest = nil
        
        super.init(coder: aDecoder)
        
        self.initialize()
    }
    
    fileprivate func initialize()
    {
        self.progressView.progressViewStyle = .bar
        self.progressView.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        self.progressView.progress = 0.5
        self.progressView.alpha = 0.0
        self.progressView.isHidden = true
        
        self.backButton.target = self
        self.forwardButton.target = self
        self.reloadButton.target = self
        self.stopLoadingButton.target = self
        self.shareButton.target = self
        
        let bundle = Bundle(for: RSTWebViewController.self)
        self.backButton.image = UIImage(named: "back_button", in: bundle, compatibleWith: nil)
        self.forwardButton.image = UIImage(named: "forward_button", in: bundle, compatibleWith: nil)
        
        self.webView.addObserver(self, forKeyPath: "url", options: [], context: RSTWebViewControllerContext)
    }
    
    deinit
    {
        self.stopKeyValueObserving()
    }
    
    
    //MARK: UIViewController
    
    open override func loadView()
    {
        self.startKeyValueObserving()
        
        if let request = self.initialReqest
        {
            self.webView.load(request)
        }
        
        self.view = self.webView
    }

    open override func viewDidLoad()
    {
        super.viewDidLoad()
        
        self.updateToolbarItems()
    }
    
    open override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        
        if self.webView.estimatedProgress < 1.0
        {
            self.transitionCoordinator?.animate(alongsideTransition: { (context) in
                
                self.showProgressBar(animated: true)
                
            }, completion: { (context) in
                
                if context.isCancelled
                {
                    self.hideProgressBar(animated: false)
                }
            })
        }
        
        if self.traitCollection.horizontalSizeClass == .regular
        {
            self.navigationController?.setToolbarHidden(true, animated: false)
        }
        else
        {
            self.navigationController?.setToolbarHidden(false, animated: false)
        }
        
        self.updateToolbarItems()
    }
    
    open override func viewWillDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        var shouldHideToolbarItems = true
        
        if let toolbarItems = self.navigationController?.topViewController?.toolbarItems
        {
            if toolbarItems.count > 0
            {
                shouldHideToolbarItems = false
            }
        }
        
        if shouldHideToolbarItems
        {
            self.navigationController?.setToolbarHidden(true, animated: false)
        }
        
        self.transitionCoordinator?.animate(alongsideTransition: { (context) in
            
            self.hideProgressBar(animated: true)
            
        }, completion: { (context) in
                
                if context.isCancelled && self.webView.estimatedProgress < 1.0
                {
                    self.showProgressBar(animated: false)
                }
        })
    }
    
    open override func didMove(toParentViewController parent: UIViewController?)
    {
        if parent == nil
        {
            self.webView.stopLoading()
        }
    }

    open override func didReceiveMemoryWarning()
    {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: Layout
    
    open override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.willTransition(to: newCollection, with: coordinator)
        
        coordinator.animate(alongsideTransition: { (context) in
            
            if self.traitCollection.horizontalSizeClass == .regular
            {
                self.navigationController?.setToolbarHidden(true, animated: true)
            }
            else
            {
                self.navigationController?.setToolbarHidden(false, animated: true)
            }
            
            }, completion: nil)
    }
    
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?)
    {
        super.traitCollectionDidChange(previousTraitCollection)
        
        self.updateToolbarItems()
    }
    
    //MARK: KVO
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?)
    {
        if context == RSTWebViewControllerContext
        {
            let webView = (object as! WKWebView)
            guard let keyPath = keyPath else {
                print("Empty KVO keypath")
                return
            }
            switch keyPath
            {
            case "title":
                self.updateTitle(webView.title)
                
            case "estimatedProgress":
                self.updateProgress(Float(webView.estimatedProgress))
                
            case "loading":
                self.updateLoadingStatus(status: webView.isLoading)
                
            case "canGoBack", "canGoForward":
                self.updateToolbarItems()
                
            case "url":
                    self.shareButton.isEnabled = (webView.url != nil)
                
            default:
                print("Unknown KVO keypath")
            }
        }
        else
        {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }

}

// Cannot be private or else they will crash upon being called ಠ_ಠ
internal extension RSTWebViewController {
    
    //MARK: Dismissal
    
    @objc func dismissWebViewController(_ sender: UIBarButtonItem)
    {
        self.parent?.dismiss(animated: true, completion: nil)
    }
    
    //MARK: Toolbar Items
    
    @objc func goBack(_ button: UIBarButtonItem)
    {
        self.webView.goBack()
    }
    
    @objc func goForward(_ button: UIBarButtonItem)
    {
        self.webView.goForward()
    }
    
    @objc func refresh(_ button: UIBarButtonItem)
    {
        if self.webView.isLoading
        {
            self.ignoreUpdateProgress = true
            self.webView.stopLoading()
        }
        else
        {
            if self.webView.url == nil && self.webView.backForwardList.backList.count == 0 && self.initialReqest != nil
            {
                self.webView.load(self.initialReqest!)
            }
            else
            {
                self.webView.reload()
            }
        }
    }
    
    @objc func shareLink(_ button: UIBarButtonItem)
    {
        //TODO:- fix force unwrapped URL
        guard let url = self.webView.url else {
            return
        }
        
        let activityItem = RSTURLActivityItem(URL: url)
        activityItem.title = self.webView.title
        
        if self.excludedActivityTypes == nil || (self.excludedActivityTypes != nil && !self.excludedActivityTypes!.contains(RSTActivityTypeOnePassword))
        {
            
            #if DEBUG
                
                // If UIApplication.rst_sharedApplication() is nil, we are running in an application extension, meaning NSBundle.mainBundle() will return the extension bundle, not the container app's
                // Because of this, we can't check to see if the Imported UTIs have been added, but since the assert is purely for debugging, it's not that big of an issue
                
                if UIApplication.rst_shared() != nil
                {
                    var importedOnePasswordUTI = false
                    var importedURLUTI = false
                    
                    if let importedUTIs = Bundle.main.object(forInfoDictionaryKey: "UTImportedTypeDeclarations") as! [[String: AnyObject]]?
                    {
                        for importedUTI in importedUTIs
                        {
                            let identifier = importedUTI["UTTypeIdentifier"] as! String
                            
                            if identifier == "org.appextension.fill-webview-action"
                            {
                                importedOnePasswordUTI = true
                            }
                            else if identifier == "com.rileytestut.RSTWebViewController.url"
                            {
                                let UTIs = importedUTI["UTTypeConformsTo"] as! [String]
                                
                                if UTIs.contains("org.appextension.fill-webview-action") && UTIs.contains("public.url")
                                {
                                    importedURLUTI = true
                                    break
                                }
                            }
                            
                            if importedOnePasswordUTI && importedURLUTI
                            {
                                break
                            }
                        }
                    }
                    
                    assert(importedOnePasswordUTI && importedURLUTI, "Either the 1Password Extension UTI, the RSTWebViewController URL UTI, or both, have not been properly declared as Imported UTIs. Please see the RSTWebViewController README for details on how to add them.")
                }
                
            #endif
            
            
            let onePasswordURLScheme = URL(string: "org-appextension-feature-password-management://")
            
            // If we're running in an application extension, there is no way to detect if 1Password is installed.
            // Because of this, if UIApplication.rst_sharedApplication() == nil, we'll simply assume it is installed, since there's no harm in doing so
            if UIApplication.rst_shared() == nil || (onePasswordURLScheme != nil && UIApplication.rst_shared().canOpenURL(onePasswordURLScheme!))
            {
                activityItem.typeIdentifier = "com.rileytestut.RSTWebViewController.url" as CFString
                
                RSTOnePasswordExtension.shared().createExtensionItem(forWebView: self.webView, completion: { (extensionItem, error) in
                    activityItem.setItem(extensionItem, forActivityType: UIActivityType(rawValue: "com.agilebits.onepassword-ios.extension"))
                    activityItem.setItem(extensionItem, forActivityType: UIActivityType(rawValue: "com.agilebits.beta.onepassword-ios.extension"))
                    self.presentActivityViewControllerWithItems([activityItem], fromBarButtonItem: button)
                })
                
                return
            }
        }
        
        self.presentActivityViewControllerWithItems([activityItem], fromBarButtonItem: button)
    }
    
    func presentActivityViewControllerWithItems(_ activityItems: [AnyObject], fromBarButtonItem barButtonItem: UIBarButtonItem)
    {
        var applicationActivities = self.applicationActivities ?? [UIActivity]()
        
        if let excludedActivityTypes = self.excludedActivityTypes
        {
            if !excludedActivityTypes.contains(RSTActivityTypeSafari)
            {
                applicationActivities.append(RSTSafariActivity())
            }
            
            if !excludedActivityTypes.contains(RSTActivityTypeChrome)
            {
                applicationActivities.append(RSTChromeActivity())
            }
        }
        else
        {
            applicationActivities.append(RSTSafariActivity())
            applicationActivities.append(RSTChromeActivity())
        }
        
        let reloadButtonTintColor = self.reloadButton.tintColor
        let stopLoadingButtonTintColor = self.stopLoadingButton.tintColor
        
        let activityViewController = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        
        activityViewController.excludedActivityTypes = self.excludedActivityTypes?.map { (activityTypeString) -> UIActivityType in
            UIActivityType(activityTypeString)
        }
        
        activityViewController.modalPresentationStyle = .popover
        activityViewController.popoverPresentationController?.barButtonItem = barButtonItem
        
        activityViewController.completionWithItemsHandler = { activityType, success, items, error in
            
            if RSTOnePasswordExtension.shared().isOnePasswordExtensionActivityType(activityType.map { $0.rawValue })
            {
                RSTOnePasswordExtension.shared().fillReturnedItems(items, intoWebView: self.webView, completion: nil)
            }
            
            // Because tint colors aren't properly updated when views aren't in a view hierarchy, we manually fix any erroneous tint colors
            self.progressView.tintColorDidChange()
            
            let systemTintColor = UIColor(red: 0, green: 0.478431, blue: 1, alpha: 1)
            
            // If previous tint color is nil, we need to temporarily set the tint color to something else or it won't visually update the tint color
            if reloadButtonTintColor == nil
            {
                self.reloadButton.tintColor = systemTintColor
            }
            
            if stopLoadingButtonTintColor == nil
            {
                self.stopLoadingButton.tintColor = systemTintColor
            }
            
            self.reloadButton.tintColor = reloadButtonTintColor
            self.stopLoadingButton.tintColor = stopLoadingButtonTintColor
            
        }
        
        self.present(activityViewController, animated: true, completion: nil)
    }
}

private let RSTWebViewControllerContext: UnsafeMutableRawPointer? = nil

private extension RSTWebViewController {
    
    //MARK: KVO
    
    func startKeyValueObserving()
    {
        self.webView.addObserver(self, forKeyPath: "title", options: [], context: RSTWebViewControllerContext)
        self.webView.addObserver(self, forKeyPath: "estimatedProgress", options: [], context: RSTWebViewControllerContext)
        self.webView.addObserver(self, forKeyPath: "loading", options: [], context: RSTWebViewControllerContext)
        self.webView.addObserver(self, forKeyPath: "canGoBack", options: [], context: RSTWebViewControllerContext)
        self.webView.addObserver(self, forKeyPath: "canGoForward", options: [], context: RSTWebViewControllerContext)
    }
    
    func stopKeyValueObserving()
    {
        self.webView.removeObserver(self, forKeyPath: "url", context: RSTWebViewControllerContext)
        self.webView.removeObserver(self, forKeyPath: "title", context: RSTWebViewControllerContext)
        self.webView.removeObserver(self, forKeyPath: "estimatedProgress", context: RSTWebViewControllerContext)
        self.webView.removeObserver(self, forKeyPath: "loading", context: RSTWebViewControllerContext)
        self.webView.removeObserver(self, forKeyPath: "canGoBack", context: RSTWebViewControllerContext)
        self.webView.removeObserver(self, forKeyPath: "canGoForward", context: RSTWebViewControllerContext)
    }
    
    //MARK: Update UI
    
    func updateTitle(_ title: String?)
    {
        self.title = title
    }
    
    func updateLoadingStatus(status loading: Bool)
    {
        self.updateToolbarItems()
        
        if let application = UIApplication.rst_shared()
        {
            if loading
            {
                application.isNetworkActivityIndicatorVisible = true
            }
            else
            {
                application.isNetworkActivityIndicatorVisible = false
            }
        }
        
    }
    
    func updateProgress(_ progress: Float)
    {
        if self.progressView.isHidden
        {
            self.showProgressBar(animated: true)
        }
        
        if self.ignoreUpdateProgress
        {
            self.ignoreUpdateProgress = false
            self.hideProgressBar(animated: true)
        }
        else if progress < self.progressView.progress
        {
            // If progress is less than self.progressView.progress, another webpage began to load before the first one completed
            // In this case, we set the progress back to 0.0, and then wait until the next updateProgress, because it results in a much better animation
            
            self.progressView.setProgress(0.0, animated: false)
        }
        else
        {
            UIView.animate(withDuration: 0.4, animations: {
                
                self.progressView.setProgress(progress, animated: true)
                
                }, completion: { (finished) in
                    
                    if progress == 1.0
                    {
                        // This delay serves two purposes. One, it keeps the progress bar on screen just a bit longer so it doesn't appear to disappear too quickly.
                        // Two, it allows us to prevent the progress bar from disappearing if the user actually started loading another webpage before the current one finished loading.
                        
                        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(Int64((0.2 * Float(NSEC_PER_SEC)))) / Double(NSEC_PER_SEC), execute: {
                            
                            if self.webView.estimatedProgress == 1.0
                            {
                                self.hideProgressBar(animated: true)
                            }
                            
                        })
                    }
                    
            });
        }
    }
    
    func showProgressBar(animated: Bool)
    {
        let navigationBarBounds = self.navigationController?.navigationBar.bounds ?? CGRect.zero
        self.progressView.frame = CGRect(x: 0, y: navigationBarBounds.height - self.progressView.bounds.height, width: navigationBarBounds.width, height: self.progressView.bounds.height)
        
        self.navigationController?.navigationBar.addSubview(self.progressView)
        
        self.progressView.setProgress(Float(self.webView.estimatedProgress), animated: false)
        self.progressView.isHidden = false
        
        if animated
        {
            UIView.animate(withDuration: 0.4, animations: {
                self.progressView.alpha = 1.0
            }) 
        }
        else
        {
            self.progressView.alpha = 1.0
        }
    }
    
    func hideProgressBar(animated: Bool)
    {
        if animated
        {
            UIView.animate(withDuration: 0.4, animations: {
                self.progressView.alpha = 0.0
                }, completion: { (finished) in
                    
                    self.progressView.setProgress(0.0, animated: false)
                    self.progressView.isHidden = true
                    self.progressView.removeFromSuperview()
            })
        }
        else
        {
            self.progressView.alpha = 0.0
            
            // Completion
            self.progressView.setProgress(0.0, animated: false)
            self.progressView.isHidden = true
            self.progressView.removeFromSuperview()
        }
    }

}
