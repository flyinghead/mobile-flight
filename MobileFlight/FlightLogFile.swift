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

    var armedDate = Date()
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
    
    class func openForWriting(_ fileURL: URL, msp: MSPParser) {
        do {
            if FileManager.default.createFile(atPath: fileURL.path, contents: nil, attributes: nil) {
                let file = try FileHandle(forUpdating: fileURL)
                file.write(Data(bytes: UnsafePointer<UInt8>(UnsafePointer(Header2)), count: Header2.count))
                
                writeFlightStats2(FlightLogStats(), toFile: file)
                
                let aircraftData = NSKeyedArchiver.archivedData(withRootObject: AllAircraftData.allAircraftData)
                
                // Write size of state
                file.write(Data(bytes: UnsafePointer<UInt8>(UnsafePointer(writeInt32(aircraftData.count))), count: 4))
                // Write state
                file.write(aircraftData)
                
                objc_sync_enter(msp)
                msp.datalog = file
                msp.datalogStart = Date()
                objc_sync_exit(msp)
            }
        } catch let error as NSError {
            NSLog("Cannot open %@: %@", fileURL.absoluteString, error.localizedDescription)
        }

    }
    
    class fileprivate func writeFlightStats2(_ stats: FlightLogStats, toFile file: FileHandle) {
        var interval = stats.armedDate.timeIntervalSinceReferenceDate as Double
        file.write(Data(bytes: &interval, count: MemoryLayout<Double>.size))
        file.write(Data(bytes: &stats.flightTime, count: MemoryLayout<Double>.size))
        file.write(Data(bytes: &stats.totalDistance, count: MemoryLayout<Double>.size))
        file.write(Data(bytes: &stats.maxDistanceToHome, count: MemoryLayout<Double>.size))
        file.write(Data(bytes: &stats.maxSpeed, count: MemoryLayout<Double>.size))
        file.write(Data(bytes: &stats.maxAltitude, count: MemoryLayout<Double>.size))
        file.write(Data(bytes: &stats.maxAmps, count: MemoryLayout<Double>.size))
        file.write(Data(bytes: &stats.mAmpsUsed, count: MemoryLayout<Double>.size))
    }
    
    class fileprivate func readFlightStats2(_ file: FileHandle) -> FlightLogStats {
        let stats = FlightLogStats()
        stats.armedDate = Date(timeIntervalSinceReferenceDate: readDoubleFromFile(file))
        stats.flightTime = readDoubleFromFile(file)
        stats.totalDistance = readDoubleFromFile(file)
        stats.maxDistanceToHome = readDoubleFromFile(file)
        stats.maxSpeed = readDoubleFromFile(file)
        stats.maxAltitude = readDoubleFromFile(file)
        stats.maxAmps = readDoubleFromFile(file)
        stats.mAmpsUsed = readDoubleFromFile(file)
        
        return stats
    }
    
    class fileprivate func readDoubleFromFile(_ file: FileHandle) -> Double {
        var double = 0.0
        let data = file.readData(ofLength: MemoryLayout<Double>.size)
        (data as NSData).getBytes(&double, length: data.count)
        
        return double
    }
    
    class func openForReading(_ fileURL: URL) throws -> (FileHandle, FlightLogStats?) {
        let file = try FileHandle(forReadingFrom: fileURL)
        var data = file.readData(ofLength: Header1.count)
        var readHeader = [UInt8](repeating: 0, count: 4)
        (data as NSData).getBytes(&readHeader, length:readHeader.count)
        var flightStats: FlightLogStats?
        if readHeader == Header1 || readHeader == Header2 {
            if readHeader == Header1 {
                data = file.readData(ofLength: 4)
                var dataLengthArray = [UInt8](repeating: 0, count: 4)
                (data as NSData).getBytes(&dataLengthArray, length: dataLengthArray.count)
                let flightStatsDataSize = readInt32(dataLengthArray, index: 0)
                
                flightStats = NSKeyedUnarchiver.unarchiveObject(with: file.readData(ofLength: flightStatsDataSize)) as? FlightLogStats
                flightStats?.armedDate = Date(timeIntervalSinceReferenceDate: 0)
            } else if readHeader == Header2 {
                flightStats = readFlightStats2(file)
            }
            var aircraftDataSize: Int32 = 0
            var data = file.readData(ofLength: MemoryLayout<Int32>.size)
            (data as NSData).getBytes(&aircraftDataSize, length: data.count)
            data = file.readData(ofLength: Int(aircraftDataSize))
            if let aircraftData = NSKeyedUnarchiver.unarchiveObject(with: data) as? AllAircraftData {
                AllAircraftData.allAircraftData = aircraftData
            } else {
                throw NSError(domain: "com.flyinghead", code: 0, userInfo: nil)
            }
        } else {
            file.seek(toFileOffset: 0)
        }
        
        return (file, flightStats)
    }
    
    class func close(_ msp: MSPParser) {
        objc_sync_enter(msp)
        if let datalog = msp.datalog {
            msp.datalog = nil
            msp.datalogStart = nil
            objc_sync_exit(msp)

            datalog.seek(toFileOffset: UInt64(Header2.count));    // Right after header
            
            let stats = readFlightStats2(datalog)
            datalog.seek(toFileOffset: UInt64(Header2.count));
            
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
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
