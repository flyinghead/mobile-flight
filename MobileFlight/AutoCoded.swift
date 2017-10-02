//
//  AutoCoded.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 07/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

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
