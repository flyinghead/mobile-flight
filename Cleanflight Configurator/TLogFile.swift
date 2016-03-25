//
//  TLogFile.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 23/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class TLogFile {
    class func openForWriting(directoryURL: NSURL, protocolHandler: ProtocolHandler) {
        let df = NSDateFormatter()
        df.dateFormat = "yyyy-MM-dd_HH-mm-ss"

        let fileURL = directoryURL.URLByAppendingPathComponent(String(format: "%@.tlog", df.stringFromDate(NSDate())))
        do {
            if NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: nil, attributes: nil) {
                let file = try NSFileHandle(forUpdatingURL: fileURL)

                synchronized(protocolHandler) {
                    protocolHandler.datalog = file
                }
            }
        } catch let error as NSError {
            NSLog("Cannot open %@: %@", fileURL, error)
        }
    }
    
    class func openForReading(fileURL: NSURL) throws -> (NSFileHandle, FlightLogStats?) {
        let file = try NSFileHandle(forReadingFromURL: fileURL)
        let data = file.readDataOfLength(8)
        if data.length < 8 {
            return (file, nil)
        }
        var buffer = [UInt8](count: 8, repeatedValue: 0)
        data.getBytes(&buffer, length:buffer.count)
        let flightStats = FlightLogStats()
        flightStats.armedDate = NSDate(timeIntervalSince1970: Double(TLogReplayComm.getTimestamp(buffer)) / 1000000)
        file.seekToFileOffset(0)
        
        return (file, flightStats)
    }
    
    class func close(protocolHandler: ProtocolHandler) {
        synchronized(protocolHandler) {
            if let datalog = protocolHandler.datalog {
                datalog.closeFile()
                protocolHandler.datalog = nil
            }
        }
    }
}