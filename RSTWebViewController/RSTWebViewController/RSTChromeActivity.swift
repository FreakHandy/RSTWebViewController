//
//  RSTChromeActivity.swift
//  RSTWebViewController
//
//  Created by Riley Testut on 12/26/14.
//  Copyright (c) 2014 Riley Testut. All rights reserved.
//

import UIKit

internal class RSTChromeActivity: UIActivity {
    
    fileprivate var URL: Foundation.URL?
    
    override class var activityCategory : UIActivityCategory
    {
        return .share
    }
    
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: RSTActivityTypeChrome)
    }
    
    override var activityTitle : String?
    {
        return NSLocalizedString("Chrome", comment: "")
    }
    
    override var activityImage : UIImage?
    {
        let bundle = Bundle(for: RSTChromeActivity.self)
        return UIImage(named: "chrome_activity", in: bundle, compatibleWith: nil)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool
    {
        if let application = UIApplication.rst_shared()
        {
            if let chromeURLScheme = Foundation.URL(string: "googlechrome://")
            {
                let activityItem: AnyObject? = self.firstValidActivityItemInActivityItems(activityItems as [AnyObject])
                
                if application.canOpenURL(chromeURLScheme) && activityItem != nil
                {
                    return true
                }
            }
        }
        
        return false
    }
    
    override func prepare(withActivityItems activityItems: [Any])
    {
        if let activityItem: AnyObject = self.firstValidActivityItemInActivityItems(activityItems as [AnyObject])
        {
            if activityItem is String
            {
                self.URL = Foundation.URL(string: activityItem as! String)
            }
            else if activityItem is Foundation.URL
            {
                self.URL = activityItem as? Foundation.URL
            }
        }
    }
    
    override func perform()
    {
        let application = UIApplication.rst_shared()
        
        if self.URL == nil || application == nil
        {
            return self.activityDidFinish(false)
        }
        
        if var components = URLComponents(url: self.URL!, resolvingAgainstBaseURL: false)
        {
            let scheme = components.scheme?.lowercased()
            
            if scheme != nil && scheme == "https"
            {
                components.scheme = "googlechromes"
            }
            else
            {
                components.scheme = "googlechrome"
            }
            
            let finished = application?.rst_open(components.url)
            self.activityDidFinish(finished!)
        }
        else
        {
            self.activityDidFinish(false)
        }
    }
    
    func firstValidActivityItemInActivityItems(_ activityItems: [AnyObject]) -> AnyObject?
    {
        if let application = UIApplication.rst_shared()
        {
            for activityItem in activityItems
            {
                var URL: Foundation.URL?
                
                if activityItem is String
                {
                    URL = Foundation.URL(string: activityItem as! String)
                }
                else if activityItem is Foundation.URL
                {
                    URL = activityItem as? Foundation.URL
                }
                
                if let URL = URL
                {
                    if application.canOpenURL(URL)
                    {
                        return activityItem
                    }
                }
            }
        }
        
        return nil
    }

}
