//
//  ParameterList.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 13/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class ParameterList : NSObject, NSXMLParserDelegate {
    static let instance = ParameterList()
    
    private var copterParams = [String : ParameterMetadata]()
    private var planeParams = [String : ParameterMetadata]()
    
    private var currentParams = [String : ParameterMetadata]()
    private var currentParam: ParameterMetadata?
    private var currentValue: String?
    
    private override init() {
        super.init()
        let fileUrl = NSBundle.mainBundle().URLForResource("ParameterMetaDataBackup", withExtension: "xml") // pathForResource("ParameterMetaDataBackup.xml", ofType: "xml")
        //let data = NSData.dataWithContentsOfMappedFile(filePath!)
        let xmlParser = NSXMLParser(contentsOfURL: fileUrl!)!
        xmlParser.delegate = self
        xmlParser.parse()
    }
    
    func getParameter(id: String) -> ParameterMetadata? {
        return copterParams[id]
    }
    
    func parser(parser: NSXMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        switch elementName {
        case "Params", "ArduCopter2", "ArduPlane", "ArduRover", "ArduTracker":
            currentParams.removeAll()
        case "DisplayName", "Description", "Values", "User", "Range", "Units", "Increment", "Group", "RebootRequired", "Path", "Bitmask":
            currentValue = nil
        default:
            currentParam = ParameterMetadata(id: elementName)
        }
    }
    
    func parser(parser: NSXMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == currentParam?.id {
            currentParams[currentParam!.id] = currentParam!
            currentParam = nil
        } else {
            switch elementName {
            case "ArduCopter2":
                copterParams = currentParams
            case "ArduPlane":
                planeParams = currentParams
                
            case "DisplayName":
                if currentValue != nil {
                    currentParam!.name = currentValue!
                }
            case "Description":
                currentParam!.description = currentValue
            case "User":
                currentParam!.advanced = currentValue?.containsString("Advanced") ?? false
            case "Range":
                if currentValue != nil {
                    if let space = currentValue!.rangeOfString(" ") {
                        currentParam!.min = Double(currentValue!.substringToIndex(space.startIndex))
                        currentParam!.max = Double(currentValue!.substringFromIndex(space.endIndex))
                    }
                }
            case "Units":
                currentParam!.unit = currentValue
            case "Increment":
                if currentValue != nil {
                    currentParam!.increment = Double(currentValue!)
                }
            case "Values":
                if currentValue != nil {
                    currentParam!.values = [(value: Double, label: String)]()
                    let components = currentValue!.componentsSeparatedByString(",")
                    for comp in components {
                        let subcomps = comp.componentsSeparatedByString(":")
                        if let numberValue = Double(subcomps[0].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())) {
                            let label = subcomps.count == 1 ? String(numberValue) : subcomps[1]
                            currentParam!.values?.append((value: numberValue, label: label))
                        } else {
                            // Forget it
                            currentParam!.values = nil
                            break
                        }
                    }
                }
            case "RebootRequired":
                currentParam!.rebootRequired = currentValue?.containsString("True") ?? false
            default:
                break
            }
        }
    }
    
    func parser(parser: NSXMLParser, foundCharacters string: String) {
        if currentValue == nil {
            currentValue = string
        } else {
            currentValue! += string
        }
    }
}

struct ParameterMetadata {
    var id: String
    var name: String
    var description: String?
    var unit: String?
    var min: Double?
    var max: Double?
    var increment: Double?
    var values: [(value: Double, label: String)]?
    var advanced = false
    var rebootRequired = false
    
    // Bitmask: would allow to select/deselect invidual options. Unfrequent use (4 in copter). List of values usually sufficient
    // Group, Path: bogus
    
    init(id: String) {
        self.id = id
        self.name = id
    }
}