//
//  AutoCoded.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 07/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class AutoCoded: NSObject, NSCoding {
    
    private let AutoCodingKey = "autoEncoding"
    
    override init() {
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        
        let decodings = aDecoder.decodeObjectForKey(AutoCodingKey) as! [String]
        setValue(decodings, forKey: AutoCodingKey)
        
        for decoding in decodings {
            setValue(aDecoder.decodeObjectForKey(decoding), forKey: decoding)
        }
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(valueForKey(AutoCodingKey), forKey: AutoCodingKey)
        for encoding in valueForKey(AutoCodingKey) as! [String] {
            aCoder.encodeObject(valueForKey(encoding), forKey: encoding)
        }
    }
    
    override class func accessInstanceVariablesDirectly() -> Bool {
        return true
    }
}