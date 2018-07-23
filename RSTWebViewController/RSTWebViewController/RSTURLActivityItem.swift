//
//  RSTURLActivityItem.swift
//  RSTWebViewController
//
//  Created by Riley Testut on 12/26/14.
//  Copyright (c) 2014 Riley Testut. All rights reserved.
//

import Foundation
import MobileCoreServices

internal extension RSTURLActivityItem
{
    // Set an item to be provided for the given activityType
    func setItem(_ item: AnyObject?, forActivityType activityType: UIActivityType)
    {
        if let item: AnyObject = item
        {
            if self.itemDictionary == nil
            {
                self.itemDictionary = [UIActivityType: NSExtensionItem]()
            }
            
            self.itemDictionary![activityType] = item
        }
        else
        {
            self.itemDictionary?[activityType] = nil
            
            if self.itemDictionary?.count == 0
            {
                self.itemDictionary = nil
            }
        }
    }
    
    // Returns item that will be provided for the given activityType
    func itemForActivityType(_ activityType: UIActivityType) -> AnyObject?
    {
        return self.itemDictionary?[activityType]
    }
}

internal class RSTURLActivityItem: NSObject, UIActivityItemSource
{
    internal var title: String?
    internal var URL: Foundation.URL
    internal var typeIdentifier = kUTTypeURL
    
    fileprivate var itemDictionary: [UIActivityType: AnyObject]?
    
    init(URL: Foundation.URL)
    {
        self.URL = URL
        
        super.init()
    }
    
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any
    {
        return self.URL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivityType) -> Any?
    {
        if let item: AnyObject = self.itemDictionary?[activityType]
        {
            return item
        }
        
//        let extensionActivityTypes: [UIActivityType] = []
        let extensionActivityTypes: [UIActivityType] = [UIActivityType.postToTwitter, UIActivityType.postToFacebook, UIActivityType.postToWeibo, UIActivityType.postToFlickr, UIActivityType.postToVimeo, UIActivityType.postToTencentWeibo]
        let applicationActivityTypes: [UIActivityType] = [UIActivityType(rawValue: RSTActivityTypeSafari), UIActivityType(rawValue: RSTActivityTypeChrome)]
        
        if self.title != nil && !applicationActivityTypes.contains(activityType) && (!activityType.rawValue.lowercased().hasPrefix("com.apple") || extensionActivityTypes.contains(activityType))
        {
            let item = NSExtensionItem()
            
            // Theoretically, attributedTitle would be most appropriate for a URL title, but Apple supplies URL titles as attributedContentText from Safari
            // In addition, Apple's own share extensions (Twitter, Facebook, etc.) only use the attributedContentText property to fill in their compose view
            // So, to ensure all share/action extensions can access the URL title, we set it for both attributedTitle and attributedContentText
            item.attributedTitle = NSAttributedString(string: self.title!)
            item.attributedContentText = item.attributedTitle
            
            item.attachments = [NSItemProvider(item: self.URL as NSSecureCoding, typeIdentifier: kUTTypeURL as String)]
            
            return item
        }
        
        return self.URL
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String
    {
        return self.title ?? ""
    }
    
    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivityType?) -> String
    {
        return self.typeIdentifier as String
    }
}
