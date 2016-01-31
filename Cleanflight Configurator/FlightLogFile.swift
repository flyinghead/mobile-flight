//
//  FlightLogFile.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 06/01/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation
import SVProgressHUD

class FlightLogStats : AutoCoded {
    var autoEncoding = [ "flightTime", "totalDistance", "maxDistanceToHome", "maxSpeed", "maxAltitude", "maxAmps", "mAmpsUsed" ]

    var flightTime = 0.0
    var totalDistance = 0.0         // MWOSD computes thus using the GPS speed and the cycle loop time. Not sure we can do the same given the update frequency
    var maxDistanceToHome = 0.0
    var maxSpeed = 0.0
    var maxAltitude = 0.0
    var maxAmps = 0.0
    var mAmpsUsed = 0.0

}

class FlightLogFile {
    //                             M   F   L   0 (header version)
    static let header: [UInt8] = [ 77, 70, 76, 0 ]
    
    class func openForWriting(fileURL: NSURL, msp: MSPParser) {
        do {
            if NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: nil, attributes: nil) {
                let file = try NSFileHandle(forWritingToURL: fileURL)
                //                      M   F   L   0 (header version)
                let header: [UInt8] = [ 77, 70, 76, 0 ]
                file.writeData(NSData(bytes: UnsafePointer(header), length: header.count))
                
                writeFlightStats(FlightLogStats(), toFile: file)
                
                let aircraftData = NSKeyedArchiver.archivedDataWithRootObject(AllAircraftData.allAircraftData)
                
                // Write size of state
                file.writeData(NSData(bytes: UnsafePointer(writeInt32(aircraftData.length)), length: 4))
                // Write state
                file.writeData(aircraftData)
                
                objc_sync_enter(msp)
                msp.datalog = file
                msp.datalogStart = NSDate()
                objc_sync_exit(msp)
            }
        } catch let error as NSError {
            NSLog("Cannot open %@: %@", fileURL, error)
        }

    }
    
    class private func writeFlightStats(stats: FlightLogStats, toFile file: NSFileHandle) {
        let flightStatsData = NSKeyedArchiver.archivedDataWithRootObject(stats)
        // Write size of stats
        file.writeData(NSData(bytes: UnsafePointer(writeInt32(flightStatsData.length)), length: 4))
        // Write stats
        file.writeData(flightStatsData)
    }
    
    class func openForReading(fileURL: NSURL) throws -> (NSFileHandle, FlightLogStats?) {
        let file = try NSFileHandle(forReadingFromURL: fileURL)
        var data = file.readDataOfLength(header.count)
        var readHeader = [UInt8](count: 4, repeatedValue: 0)
        data.getBytes(&readHeader, length:readHeader.count)
        var flightStats: FlightLogStats?
        if readHeader == header {
            data = file.readDataOfLength(4)
            var dataLengthArray = [UInt8](count: 4, repeatedValue: 0)
            data.getBytes(&dataLengthArray, length: dataLengthArray.count)
            let flightStatsDataSize = readInt32(dataLengthArray, index: 0)
            
            flightStats = NSKeyedUnarchiver.unarchiveObjectWithData(file.readDataOfLength(flightStatsDataSize)) as? FlightLogStats
            
            data = file.readDataOfLength(4)
            dataLengthArray = [UInt8](count: 4, repeatedValue: 0)
            data.getBytes(&dataLengthArray, length: dataLengthArray.count)
            let aircraftDataSize = readInt32(dataLengthArray, index: 0)
            AllAircraftData.allAircraftData = NSKeyedUnarchiver.unarchiveObjectWithData(file.readDataOfLength(aircraftDataSize)) as! AllAircraftData
        } else {
            file.seekToFileOffset(0)
        }
        
        return (file, flightStats)
    }
    
    class func close(msp: MSPParser) {
        objc_sync_enter(msp)
        if let datalog = msp.datalog {
            msp.datalog = nil
            msp.datalogStart = nil
            objc_sync_exit(msp)

            datalog.seekToFileOffset(4);    // Right after header
            
            let stats = FlightLogStats()
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            stats.flightTime = appDelegate.lastArmedTime
            
            let gpsData = GPSData.theGPSData
            let config = Configuration.theConfig
            let sensorData = SensorData.theSensorData
            
            stats.maxSpeed = gpsData.maxSpeed
            stats.maxDistanceToHome = Double(gpsData.maxDistanceToHome)
            if config.isBarometerActive() {
                stats.maxAltitude = sensorData.maxAltitude
            } else {
                stats.maxAltitude = Double(gpsData.maxAltitude)
            }
            stats.maxAmps = config.maxAmperage
            stats.mAmpsUsed = Double(config.mAhDrawn)
            writeFlightStats(stats, toFile: datalog)
            
            datalog.closeFile()
        } else {
            objc_sync_exit(msp)
        }
        
    }
    
}