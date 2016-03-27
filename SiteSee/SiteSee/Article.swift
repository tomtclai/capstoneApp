//
//  Article.swift
//  SiteSee
//
//  Created by Tom Lai on 3/23/16.
//  Copyright © 2016 Lai. All rights reserved.
//

import Foundation
import CoreData

class Article: NSManagedObject {
    
    struct Keys {
        static let Title = "title"
        static let Subtitle = "subtitle"
        static let Url = "url"
        static let SortOrder = "sortOrder"
    }
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String:AnyObject?], context: NSManagedObjectContext) {
        let entity = NSEntityDescription.entityForName("Article", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        title = dictionary[Keys.Title] as? String
        subtitle = dictionary[Keys.Subtitle] as? String
        url = dictionary[Keys.Url] as? String
        sortOrder = dictionary[Keys.SortOrder] as? NSNumber
    }
}
