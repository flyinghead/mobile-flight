//
//  FlightLogFile.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 06/01/16.
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
import SVProgressHUD

class FlightLogStats : AutoCoded {
    var autoEncoding = [ "flightTime", "totalDistance", "maxDistanceToHome", "maxSpeed", "maxAltitude", "maxAmps", "mAmpsUsed" ]

    var armedDate = NSDate()
    var flightTime = 0.0
    var totalDistance = 0.0         // MWOSD computes this using the GPS speed and the cycle loop time. Not sure we can do the same given the update frequency
    var maxDistanceToHome = 0.0
    var maxSpeed = 0.0
    var maxAltitude = 0.0
    var maxAmps = 0.0
    var mAmpsUsed = 0.0

}

class FlightLogFile {
    //                             M   F   L   0 (header version)
    static let Header1: [UInt8] = [ 77, 70, 76, 0 ]     // V1: flight stats use NSKeyedArchiver. Until 1.0.2
    static let Header2: [UInt8] = [ 77, 70, 76, 1 ]     // V2: flight stats loaded/saved "manually". Introduced in 1.1
    
    class func openForWriting(fileURL: NSURL, msp: MSPParser) {
        do {
            if NSFileManager.defaultManager().createFileAtPath(fileURL.path!, contents: nil, attributes: nil) {
                let file = try NSFileHandle(forUpdatingURL: fileURL)
                file.writeData(NSData(bytes: UnsafePointer(Header2), length: Header2.count))
                
                writeFlightStats2(FlightLogStats(), toFile: file)
                
                let aircraftData = NSKeyedArchiver.archivedDataWithRootObject(AllAircraftData.allAircraftData)
                
                // Write size of state
                var stateSize = Int32(aircraftData.length)
                file.writeData(NSData(bytes: &stateSize, length: sizeof(Int32)))
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
    
    class private func writeFlightStats2(stats: FlightLogStats, toFile file: NSFileHandle) {
        var interval = stats.armedDate.timeIntervalSinceReferenceDate as Double
        file.writeData(NSData(bytes: &interval, length: sizeof(Double)))
        file.writeData(NSData(bytes: &stats.flightTime, length: sizeof(Double)))
        file.writeData(NSData(bytes: &stats.totalDistance, length: sizeof(Double)))
        file.writeData(NSData(bytes: &stats.maxDistanceToHome, length: sizeof(Double)))
        file.writeData(NSData(bytes: &stats.maxSpeed, length: sizeof(Double)))
        file.writeData(NSData(bytes: &stats.maxAltitude, length: sizeof(Double)))
        file.writeData(NSData(bytes: &stats.maxAmps, length: sizeof(Double)))
        file.writeData(NSData(bytes: &stats.mAmpsUsed, length: sizeof(Double)))
    }
    
    class private func readFlightStats2(file: NSFileHandle) -> FlightLogStats {
        let stats = FlightLogStats()
        stats.armedDate = NSDate(timeIntervalSinceReferenceDate: readDoubleFromFile(file))
        stats.flightTime = readDoubleFromFile(file)
        stats.totalDistance = readDoubleFromFile(file)
        stats.maxDistanceToHome = readDoubleFromFile(file)
        stats.maxSpeed = readDoubleFromFile(file)
        stats.maxAltitude = readDoubleFromFile(file)
        stats.maxAmps = readDoubleFromFile(file)
        stats.mAmpsUsed = readDoubleFromFile(file)
        
        return stats
    }
    
    class private func readDoubleFromFile(file: NSFileHandle) -> Double {
        var double = 0.0
        let data = file.readDataOfLength(sizeof(Double))
        data.getBytes(&double, length: data.length)
        
        return double
    }
    
    class func openForReading(fileURL: NSURL) throws -> (NSFileHandle, FlightLogStats?) {
        let file = try NSFileHandle(forReadingFromURL: fileURL)
        var data = file.readDataOfLength(Header1.count)
        var readHeader = [UInt8](count: 4, repeatedValue: 0)
        data.getBytes(&readHeader, length:readHeader.count)
        var flightStats: FlightLogStats?
        if readHeader == Header1 || readHeader == Header2 {
            if readHeader == Header1 {
                data = file.readDataOfLength(4)
                var dataLengthArray = [UInt8](count: 4, repeatedValue: 0)
                data.getBytes(&dataLengthArray, length: dataLengthArray.count)
                let flightStatsDataSize = readInt32(dataLengthArray, index: 0)
                
                flightStats = NSKeyedUnarchiver.unarchiveObjectWithData(file.readDataOfLength(flightStatsDataSize)) as? FlightLogStats
                flightStats?.armedDate = NSDate(timeIntervalSinceReferenceDate: 0)
            } else if readHeader == Header2 {
                flightStats = readFlightStats2(file)
            }
            var aircraftDataSize: Int32 = 0
            var data = file.readDataOfLength(sizeof(Int32))
            data.getBytes(&aircraftDataSize, length: data.length)
            data = file.readDataOfLength(Int(aircraftDataSize))
            if let aircraftData = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? AllAircraftData {
                AllAircraftData.allAircraftData = aircraftData
            } else {
                throw NSError(domain: "com.flyinghead", code: 0, userInfo: nil)
            }
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

            datalog.seekToFileOffset(UInt64(Header2.count));    // Right after header
            
            let stats = readFlightStats2(datalog)
            datalog.seekToFileOffset(UInt64(Header2.count));
            
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
            writeFlightStats2(stats, toFile: datalog)
            
            datalog.closeFile()
        } else {
            objc_sync_exit(msp)
        }
        
    }
    
}
