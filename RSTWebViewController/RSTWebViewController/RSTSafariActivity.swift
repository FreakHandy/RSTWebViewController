//
//  RSTSafariActivity.swift
//  RSTWebViewController
//
//  Created by Riley Testut on 12/27/14.
//  Copyright (c) 2014 Riley Testut. All rights reserved.
//

import UIKit

internal class RSTSafariActivity: UIActivity {

    fileprivate var URL: Foundation.URL?
    
    override class var activityCategory : UIActivityCategory
    {
        return .share
    }
    
    override var activityType: UIActivityType? {
        return UIActivityType(rawValue: RSTActivityTypeSafari)
    }
    
    override var activityTitle : String?
    {
        return NSLocalizedString("Safari", comment: "")
    }
    
    override var activityImage : UIImage?
    {
        let bundle = Bundle(for: RSTSafariActivity.self)
        return UIImage(named: "safari_activity", in: bundle, compatibleWith: nil)
    }
    
    override func canPerform(withActivityItems activityItems: [Any]) -> Bool
    {
        if let application = UIApplication.rst_shared()
        {
            if let safariURLScheme = Foundation.URL(string: "http://")
            {
                let activityItem: AnyObject? = self.firstValidActivityItemInActivityItems(activityItems as [AnyObject])
                
                if application.canOpenURL(safariURLScheme) && activityItem != nil
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
        
        let finished = application?.rst_open(self.URL)
        self.activityDidFinish(finished!)
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
