//
//  ValidateFirmwareTest.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 03/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
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

import XCTest
@testable import MobileFlight

class ValidateFirmwareTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testFirmware() {
        let connectExpect = expectationWithDescription("Connection")
        let mspExpect = expectationWithDescription("MSP-Tests")
        
        let msp = (UIApplication.sharedApplication().delegate as! AppDelegate).msp
        let comm = AsyncSocketComm(msp: msp, host: "localhost", port: 8666)
        comm.connect({ success in
            if success {
                connectExpect.fulfill()
                UIApplication.sharedApplication().delegate?.window!!.rootViewController!.initiateHandShake({ success in
                    if success {
                        self.runMspTest(msp, expectation: mspExpect)
                    } else {
                        XCTFail("Handshake failed")
                    }
                })
            } else {
                XCTFail("TCP/IP connection failed")
            }
        })
        waitForExpectationsWithTimeout(10) { error in
            if let error = error {
                XCTFail("waitForExpectationsWithTimeout errored: \(error)")
            }
        }
        comm.close()
    }
    
    private func runMspTest(msp: MSPParser, expectation: XCTestExpectation) {
        let settings = Settings.theSettings
        let config = Configuration.theConfig
        let motorData = MotorData.theMotorData
        let misc = Misc.theMisc
        let receiver = Receiver.theReceiver
        let gpsData = GPSData.theGPSData
        let inavConfig = INavConfig.theINavConfig
        let inavState = INavState.theINavState
        
        var gpsSupported = true
        var compassSupported = true
        
        let commands: [SendCommand] = [
            { callback in
                msp.sendRssiConfig(7) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_RSSI_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.rssiChannel, 7)
                        callback(success)
                    }
                }
            },
            { callback in
                msp.sendMixerConfiguration(settings) { success in
                    // betaflight 3.1.7 and earlier do not implement this msp call if compiled for quad only (micro scisky)
                    // All other versions compiled for quad only will fail this test (can't change the mixer type)
                    XCTAssert(success)
                    msp.sendMessage(.MSP_MIXER_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.mixerConfiguration, 2)
                        callback(success)
                    }
                }
            },
            { callback in
                msp.sendSetFeature(.Blackbox) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_FEATURE, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.features.rawValue, BaseFlightFeature.Blackbox.rawValue)
                        callback(success)
                    }
                }
            },
            { callback in
                let tmp = Settings(copyOf: settings)
                tmp.boardAlignYaw = 11
                tmp.boardAlignRoll = 22
                tmp.boardAlignPitch = 33
                msp.sendBoardAlignment(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_BOARD_ALIGNMENT, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.boardAlignYaw, tmp.boardAlignYaw)
                        XCTAssertEqual(settings.boardAlignPitch, tmp.boardAlignPitch)
                        XCTAssertEqual(settings.boardAlignRoll, tmp.boardAlignRoll)
                        callback(success)
                    }
                }
            },
            { callback in
                var data = [UInt8]()
                
                data.appendContentsOf(writeUInt16(1011))
                data.appendContentsOf(writeUInt16(1022))
                data.appendContentsOf(writeUInt16(1033))
                data.appendContentsOf(writeUInt16(1044))
                data.appendContentsOf(writeUInt16(1055))
                data.appendContentsOf(writeUInt16(1066))
                data.appendContentsOf(writeUInt16(1077))
                data.appendContentsOf(writeUInt16(1099))
                
                msp.sendMessage(.MSP_SET_MOTOR, data: data, retry: 2) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_MOTOR, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(motorData.throttle[0], 1011)
                        XCTAssertEqual(motorData.throttle[1], 1022)
                        XCTAssertEqual(motorData.throttle[2], 1033)
                        XCTAssertEqual(motorData.throttle[3], 1044)
                        callback(success)
                    }
                }
            },
            { callback in
                msp.sendMessage(.MSP_UID, data: nil, retry: 2) { success in
                    XCTAssert(success)
                    XCTAssertNotNil(config.uid)
                    callback(success)
                }
            },
            { callback in
                if config.isINav {
                    callback(true)
                    return
                }
                let tmp = Misc(copyOf: misc)
                tmp.accelerometerTrimRoll = 2
                tmp.accelerometerTrimPitch = -1
                msp.sendSetAccTrim(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_ACC_TRIM, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(misc.accelerometerTrimRoll, 2)
                        XCTAssertEqual(misc.accelerometerTrimPitch, -1)
                        callback(success)
                    }
                }
            },
            { callback in
                let tmp = Settings(copyOf: settings)
                tmp.rcRate = 0.97
                tmp.rcExpo = 0.03
                tmp.yawRate = 0.98
                tmp.yawExpo = 0.02
                tmp.rollSuperRate = 0.71
                tmp.pitchSuperRate = 0.72
                tmp.yawSuperRate = 0.73
                tmp.throttleMid = 0.51
                tmp.throttleExpo = 0.04
                tmp.tpaRate = 0.99
                tmp.tpaBreakpoint = 1502
                msp.sendSetRcTuning(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_RC_TUNING, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        if !config.isINav {
                            XCTAssertEqual(settings.rcRate, tmp.rcRate)
                            XCTAssertEqual(settings.yawRate, tmp.yawRate)
                        }
                        XCTAssertEqual(settings.rcExpo, tmp.rcExpo)
                        XCTAssertEqual(settings.yawExpo, tmp.yawExpo)
                        XCTAssertEqual(settings.rollSuperRate, tmp.rollSuperRate)
                        XCTAssertEqual(settings.pitchSuperRate, tmp.pitchSuperRate)
                        XCTAssertEqual(settings.yawSuperRate, tmp.yawSuperRate)
                        XCTAssertEqual(settings.throttleMid, tmp.throttleMid)
                        XCTAssertEqual(settings.throttleExpo, tmp.throttleExpo)
                        XCTAssertEqual(settings.tpaRate, tmp.tpaRate)
                        XCTAssertEqual(settings.tpaBreakpoint, tmp.tpaBreakpoint)
                        callback(success)
                    }
                }
            },
            { callback in
                let range1 = ModeRange(id: 1, auxChannelId: 0, start: 1400, end: 1600)
                let range2 = ModeRange(id: 2, auxChannelId: 3, start: 1600, end: 2100)
                msp.sendSetModeRange(0, range: range1) { success in
                    XCTAssert(success)
                    msp.sendSetModeRange(1, range: range2) { success in
                        XCTAssert(success)
                        msp.sendMessage(.MSP_MODE_RANGES, data: nil, retry: 2) { success in
                            XCTAssert(success)
                            XCTAssertEqual(settings.modeRanges![0].id, range1.id)
                            XCTAssertEqual(settings.modeRanges![0].auxChannelId, range1.auxChannelId)
                            XCTAssertEqual(settings.modeRanges![0].start, range1.start)
                            XCTAssertEqual(settings.modeRanges![0].end, range1.end)
                            XCTAssertEqual(settings.modeRanges![1].id, range2.id)
                            XCTAssertEqual(settings.modeRanges![1].auxChannelId, range2.auxChannelId)
                            XCTAssertEqual(settings.modeRanges![1].start, range2.start)
                            XCTAssertEqual(settings.modeRanges![1].end, range2.end)
                            callback(success)
                        }
                    }
                }
            },
            { callback in
                let tmp = Settings(copyOf: settings)
                tmp.disarmKillSwitch = !tmp.disarmKillSwitch
                tmp.autoDisarmDelay = 7
                msp.sendSetArmingConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_ARMING_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.disarmKillSwitch, tmp.disarmKillSwitch)
                        XCTAssertEqual(settings.autoDisarmDelay, tmp.autoDisarmDelay)
                        callback(success)
                    }
                }
            },
            { callback in
                var rxmap = [UInt8]()
                rxmap.append(7)
                rxmap.append(6)
                rxmap.append(5)
                rxmap.append(4)
                rxmap.append(3)
                rxmap.append(2)
                rxmap.append(1)
                rxmap.append(0)
                msp.sendSetRxMap(rxmap) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_RX_MAP, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        for i in 0 ..< rxmap.count {
                            XCTAssertEqual(receiver.map[i], Int(rxmap[i]))
                        }
                        callback(success)
                    }
                }

            },
            { callback in
                msp.sendMessage(.MSP_PID, data: nil, retry: 2) { success in
                    XCTAssert(success)
                    let tmp = Settings(copyOf: settings)
                    for i in 0 ..< tmp.pidValues!.count {
                        for j in 0 ..< 3 {
                            tmp.pidValues![i][j] += 1
                        }
                    }
                    msp.sendPid(tmp) { success in
                        XCTAssert(success)
                        msp.sendMessage(.MSP_PID, data: nil, retry: 2) { success in
                            XCTAssert(success)
                            XCTAssertEqual(settings.pidValues!, tmp.pidValues!)
                            callback(success)
                        }
                    }
                }
            },
            { callback in
                // Note: only two profiles with BF 3.1.7 on NAZE
                msp.sendSelectProfile(1) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_STATUS_EX, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(config.profile, 1)
                        callback(success)
                    }
                }
            },
            { callback in
                if !config.isApiVersionAtLeast("1.31") {
                    callback(true)
                    return
                }
                msp.sendSelectRateProfile(2) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_STATUS_EX, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(config.rateProfile, 2)
                        callback(success)
                    }
                }
            },
            { callback in
                msp.sendMessage(.MSP_CF_SERIAL_CONFIG, data: nil, retry: 2) { success in
                    XCTAssert(success)
                    let tmp = Settings(copyOf: settings)
                    tmp.portConfigs![1].functions = .TelemetrySmartPort
                    tmp.portConfigs![1].telemetryBaudRate = .Baud38400
                    if tmp.portConfigs!.count > 2 {
                        tmp.portConfigs![2].functions = .GPS
                        tmp.portConfigs![2].gpsBaudRate = .Baud19200
                    }
                    msp.sendSerialConfig(tmp) { success in
                        XCTAssert(success)
                        msp.sendMessage(.MSP_CF_SERIAL_CONFIG, data: nil, retry: 2) { success in
                            XCTAssert(success)
                            XCTAssertEqual(tmp.portConfigs![1].functions, tmp.portConfigs![1].functions)
                            XCTAssertEqual(tmp.portConfigs![1].telemetryBaudRate, tmp.portConfigs![1].telemetryBaudRate)
                            if tmp.portConfigs!.count > 2 {
                                XCTAssertEqual(tmp.portConfigs![2].functions, tmp.portConfigs![2].functions)
                                XCTAssertEqual(tmp.portConfigs![2].gpsBaudRate, tmp.portConfigs![2].gpsBaudRate)
                            }
                            callback(success)
                        }
                    }
                }
            },
            { callback in
                let tmp = Settings(copyOf: settings)
                tmp.midRC = 1497
                tmp.minCheck = 999
                tmp.maxCheck = 2001
                tmp.serialRxType = 2
                tmp.rcInterpolation = 1
                tmp.rcInterpolationInterval = 22
                tmp.rxMinUsec = 998
                tmp.rxMaxUsec = 2002
                msp.sendRxConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_RX_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.midRC, tmp.midRC)
                        XCTAssertEqual(settings.minCheck, tmp.minCheck)
                        XCTAssertEqual(settings.maxCheck, tmp.maxCheck)
                        XCTAssertEqual(settings.serialRxType, tmp.serialRxType)
                        if config.isApiVersionAtLeast("1.31") {
                            XCTAssertEqual(settings.rcInterpolation, tmp.rcInterpolation)
                            XCTAssertEqual(settings.rcInterpolationInterval, tmp.rcInterpolationInterval)
                        }
                        XCTAssertEqual(settings.rxMinUsec, tmp.rxMinUsec)
                        XCTAssertEqual(settings.rxMaxUsec, tmp.rxMaxUsec)
                        callback(success)
                    }
                }
            },
            { callback in
                let tmp = Settings(copyOf: settings)
                tmp.failsafeDelay = 0.9
                tmp.failsafeOffDelay = 0.8
                tmp.failsafeThrottle = 1503
                tmp.failsafeKillSwitch = !tmp.failsafeKillSwitch
                tmp.failsafeThrottleLowDelay = 0.7
                tmp.failsafeProcedure = tmp.failsafeProcedure == 1 ? 0 : 1
                msp.sendFailsafeConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_FAILSAFE_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.failsafeDelay, tmp.failsafeDelay)
                        XCTAssertEqual(settings.failsafeOffDelay, tmp.failsafeOffDelay)
                        XCTAssertEqual(settings.failsafeThrottle, tmp.failsafeThrottle)
                        if !config.isINav || !config.isApiVersionAtLeast("1.25") {                          // removed in INAV 1.7
                            XCTAssertEqual(settings.failsafeKillSwitch, tmp.failsafeKillSwitch)
                        }
                        XCTAssertEqual(settings.failsafeThrottleLowDelay, tmp.failsafeThrottleLowDelay)
                        XCTAssertEqual(settings.failsafeProcedure, tmp.failsafeProcedure)
                        callback(success)
                    }
                }
            },
            { callback in
                if !config.isApiVersionAtLeast("1.31") {
                    callback(true)
                    return
                }
                msp.sendCraftName("TESTME") { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_NAME, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.craftName, "TESTME")
                        callback(success)
                    }
                }
            },
            { callback in
                // INav: UAV needs to be armed and have a GPS fix and home pos to set GPS hold position. So we use a regular waypoint number
                if config.isINav {
                    let wp = Waypoint(number: 1, action: .Known(.Waypoint), position: GPSLocation(latitude: 3.14, longitude: 6.28), altitude: 10, param1: 1, param2: 2, param3: 3, last: true)
                    msp.sendINavWaypoint(wp) { success in
                        XCTAssert(success)
                        msp.sendMessage(.MSP_WP, data: [ UInt8(1) ], retry: 2) { success in
                            XCTAssert(success)
                            XCTAssertEqual(inavState.waypoints[0].position.latitude, 3.14)
                            XCTAssertEqual(inavState.waypoints[0].position.longitude, 6.28)
                            XCTAssertEqual(inavState.waypoints[0].altitude, 10)
                            XCTAssertEqual(inavState.waypoints[0].param1, 1)
                            XCTAssertEqual(inavState.waypoints[0].param2, 2)
                            XCTAssertEqual(inavState.waypoints[0].param3, 3)
                            callback(success)
                        }
                    }
                } else {
                    msp.setGPSHoldPosition(latitude: 3.14, longitude: 6.28, altitude: 0) { success in
                        if !success {
                            NSLog("ASSUMING NO GPS SUPPORT AVAILABLE")
                            gpsSupported = false
                            callback(true)
                        } else {
                            msp.sendMessage(.MSP_WP, data: [ UInt8(config.isINav ? 255 : 16) ], retry: 2) { success in
                                XCTAssert(success)
                                XCTAssertEqual(gpsData.posHoldPosition?.latitude, 3.14)
                                XCTAssertEqual(gpsData.posHoldPosition?.longitude, 6.28)
                                callback(success)
                            }
                        }
                    }
                }
            },
            { callback in
                if config.isApiVersionAtLeast("1.35") {
                    callback(true)
                    return
                }
                let tmp = Settings(copyOf: settings)
                tmp.midRC = 1480
                tmp.minThrottle = 1111
                tmp.maxThrottle = 1996
                tmp.minCommand = 1011
                tmp.failsafeThrottle = 1217
                tmp.gpsType = 1
                tmp.gpsUbxSbas = 1
                tmp.rssiChannel = 9
                tmp.magDeclination = 57
                tmp.vbatScale = 101
                tmp.vbatMinCellVoltage = 3.0
                tmp.vbatMaxCellVoltage = 5.0
                tmp.vbatWarningCellVoltage = 3.1
                msp.sendSetMisc(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_MISC, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.midRC, tmp.midRC)
                        XCTAssertEqual(settings.minThrottle, tmp.minThrottle)
                        XCTAssertEqual(settings.maxThrottle, tmp.maxThrottle)
                        XCTAssertEqual(settings.minCommand, tmp.minCommand)
                        XCTAssertEqual(settings.failsafeThrottle, tmp.failsafeThrottle)
                        if gpsSupported {
                            XCTAssertEqual(settings.gpsType, tmp.gpsType)
                            XCTAssertEqual(settings.gpsUbxSbas, tmp.gpsUbxSbas)
                        }
                        XCTAssertEqual(settings.rssiChannel, tmp.rssiChannel)
                        XCTAssertEqual(settings.magDeclination, tmp.magDeclination)
                        if !config.isApiVersionAtLeast("1.24") {    // Removed in CF 1.14
                            XCTAssertEqual(settings.vbatScale, tmp.vbatScale)
                            XCTAssertEqual(settings.vbatMinCellVoltage, tmp.vbatMinCellVoltage)
                            XCTAssertEqual(settings.vbatMaxCellVoltage, tmp.vbatMaxCellVoltage)
                            XCTAssertEqual(settings.vbatWarningCellVoltage, tmp.vbatWarningCellVoltage)
                        }
                        callback(success)
                    }
                }
            },
            { callback in
                // MSP_LOOP_TIME supported in CF up to 1.13 and INAV
                if config.isBetaflight || (!config.isINav && config.isApiVersionAtLeast("1.24")) {
                    callback(true)
                    return
                }
                let tmp = Settings(copyOf: settings)
                tmp.loopTime = 1002
                msp.sendLoopTime(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_LOOP_TIME, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.loopTime, tmp.loopTime)
                        callback(success)
                    }
                }
            },
            { callback in
                if !config.isINav || !config.isApiVersionAtLeast("1.24") {
                    callback(true)
                    return
                }
                let tmp = INavConfig(copyOf: inavConfig)
                tmp.userControlMode = INavUserControlMode(value: tmp.userControlMode.intValue == 0 ? 1 : 0)
                tmp.maxSpeed += 0.1
                tmp.maxClimbRate += 0.1
                tmp.maxManualSpeed += 0.1
                tmp.maxManualClimbRate += 0.1
                tmp.maxBankAngle += 1
                tmp.useThrottleMidForAltHold = !tmp.useThrottleMidForAltHold
                tmp.hoverThrottle += 1
                msp.sendNavPosHold(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_NAV_POSHOLD, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(inavConfig.userControlMode.intValue, tmp.userControlMode.intValue)
                        XCTAssertEqual(inavConfig.maxSpeed, tmp.maxSpeed)
                        XCTAssertEqual(inavConfig.maxClimbRate, tmp.maxClimbRate)
                        XCTAssertEqual(inavConfig.maxManualSpeed, tmp.maxManualSpeed)
                        XCTAssertEqual(inavConfig.maxManualClimbRate, tmp.maxManualClimbRate)
                        XCTAssertEqual(inavConfig.maxBankAngle, tmp.maxBankAngle)
                        XCTAssertEqual(inavConfig.useThrottleMidForAltHold, tmp.useThrottleMidForAltHold)
                        XCTAssertEqual(inavConfig.hoverThrottle, tmp.hoverThrottle)
                        callback(success)
                    }
                }
            },
            { callback in
                if !config.isINav || !config.isApiVersionAtLeast("1.26") {
                    callback(true)
                    return
                }
                let tmp = INavConfig(copyOf: inavConfig)
                tmp.rthAltitude += 0.1
                tmp.rthTailFirst = !tmp.rthTailFirst
                tmp.rthClimbFirst = !tmp.rthClimbFirst
                tmp.rthClimbIgnoreEmergency = !tmp.rthClimbIgnoreEmergency
                tmp.rthAllowLanding = !tmp.rthAllowLanding
                tmp.rthAbortThreshold += 0.1
                tmp.minRthDistance += 0.1
                tmp.rthAltControlMode = (tmp.rthAltControlMode + 1) % 5

                msp.sendRthAndLandConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_RTH_AND_LAND_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(inavConfig.rthAltitude, tmp.rthAltitude)
                        XCTAssertEqual(inavConfig.rthTailFirst, tmp.rthTailFirst)
                        XCTAssertEqual(inavConfig.rthClimbFirst, tmp.rthClimbFirst)
                        XCTAssertEqual(inavConfig.rthClimbIgnoreEmergency, tmp.rthClimbIgnoreEmergency)
                        XCTAssertEqual(inavConfig.rthAllowLanding, tmp.rthAllowLanding)
                        XCTAssertEqual(inavConfig.rthAbortThreshold, tmp.rthAbortThreshold)
                        XCTAssertEqual(inavConfig.minRthDistance, tmp.minRthDistance)
                        XCTAssertEqual(inavConfig.rthAltControlMode, tmp.rthAltControlMode)
                        callback(success)
                    }
                }
            },
            { callback in
                if !config.isINav || !config.isApiVersionAtLeast("1.26") {
                    callback(true)
                    return
                }
                let tmp = INavConfig(copyOf: inavConfig)
                tmp.fwCruiseThrottle += 1
                tmp.fwMinThrottle += 1
                tmp.fwMaxThrottle += 1
                tmp.fwMaxBankAngle += 1
                tmp.fwMaxClimbAngle += 1
                tmp.fwMaxDiveAngle += 1
                tmp.fwLoiterRadius += 1
                tmp.fwPitchToThrottle += 1
                
                msp.sendFwConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_FW_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(inavConfig.fwCruiseThrottle, tmp.fwCruiseThrottle)
                        XCTAssertEqual(inavConfig.fwMinThrottle, tmp.fwMinThrottle)
                        XCTAssertEqual(inavConfig.fwMaxThrottle, tmp.fwMaxThrottle)
                        XCTAssertEqual(inavConfig.fwMaxBankAngle, tmp.fwMaxBankAngle)
                        XCTAssertEqual(inavConfig.fwMaxClimbAngle, tmp.fwMaxClimbAngle)
                        XCTAssertEqual(inavConfig.fwMaxDiveAngle, tmp.fwMaxDiveAngle)
                        XCTAssertEqual(inavConfig.fwLoiterRadius, tmp.fwLoiterRadius)
                        XCTAssertEqual(inavConfig.fwPitchToThrottle, tmp.fwPitchToThrottle)
                        callback(success)
                    }
                }
            },
            { callback in
                msp.sendMessage(.MSP_VOLTAGE_METER_CONFIG, data: nil, retry: 2, callback: callback)
            },
            { callback in
                let tmp = Settings(copyOf: settings)
                tmp.vbatScale += 1
                tmp.vbatMaxCellVoltage = 4.8
                tmp.vbatMinCellVoltage = 3.1
                tmp.vbatWarningCellVoltage = 3.3
                tmp.vbatMeterType = tmp.vbatMeterType == 0 ? 1 : 0
                
                tmp.vbatResistorDividerValue += 1
                tmp.vbatResistorDividerMultiplier += 1
                
                msp.sendVoltageMeterConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_VOLTAGE_METER_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.vbatScale, tmp.vbatScale)
                        if !config.isApiVersionAtLeast("1.35") {
                            XCTAssertEqual(settings.vbatMaxCellVoltage, tmp.vbatMaxCellVoltage)
                            XCTAssertEqual(settings.vbatMinCellVoltage, tmp.vbatMinCellVoltage)
                            XCTAssertEqual(settings.vbatWarningCellVoltage, tmp.vbatWarningCellVoltage)
                            if config.isApiVersionAtLeast("1.31") {
                                XCTAssertEqual(settings.vbatMeterType, tmp.vbatMeterType)
                            }
                        } else {
                            XCTAssertEqual(settings.vbatResistorDividerValue, tmp.vbatResistorDividerValue)
                            XCTAssertEqual(settings.vbatResistorDividerMultiplier, tmp.vbatResistorDividerMultiplier)
                        }
                        callback(success)
                    }
                }
            },
            { callback in
                if !config.isApiVersionAtLeast("1.35") {
                    callback(true)
                    return
                }
                let tmp = Settings(copyOf: settings)
                tmp.vbatMaxCellVoltage = 4.7
                tmp.vbatMinCellVoltage = 3.3
                tmp.vbatWarningCellVoltage = 3.6
                tmp.batteryCapacity += 1
                tmp.currentMeterSource = 1 - tmp.currentMeterSource
                tmp.voltageMeterSource = 1 - tmp.voltageMeterSource
                
                msp.sendBatteryConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_BATTERY_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.vbatMaxCellVoltage, tmp.vbatMaxCellVoltage)
                        XCTAssertEqual(settings.vbatMinCellVoltage, tmp.vbatMinCellVoltage)
                        XCTAssertEqual(settings.vbatWarningCellVoltage, tmp.vbatWarningCellVoltage)
                        XCTAssertEqual(settings.batteryCapacity, tmp.batteryCapacity)
                        XCTAssertEqual(settings.currentMeterSource, tmp.currentMeterSource)
                        XCTAssertEqual(settings.voltageMeterSource, tmp.voltageMeterSource)
                        callback(success)
                    }
                }
            },
            { callback in
                let tmp = Settings(copyOf: settings)
                tmp.currentScale = 15 - tmp.currentScale
                tmp.currentOffset = 10 - tmp.currentOffset
                tmp.currentMeterType = 1 - tmp.currentMeterType
                tmp.batteryCapacity += 1
                
                msp.sendCurrentMeterConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_CURRENT_METER_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.currentScale, tmp.currentScale)
                        XCTAssertEqual(settings.currentOffset, tmp.currentOffset)
                        XCTAssertEqual(settings.currentMeterType, tmp.currentMeterType)
                        if !config.isApiVersionAtLeast("1.35") {
                            XCTAssertEqual(settings.batteryCapacity, tmp.batteryCapacity)
                        }
                        callback(success)
                    }
                }
            },
            { callback in
                if !config.isApiVersionAtLeast("1.35") {
                    callback(true)
                }
                let tmp = Settings(copyOf: settings)
                tmp.minCommand = 1012
                tmp.minThrottle = 1112
                tmp.maxThrottle = 1995
                
                msp.sendMotorConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_MOTOR_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.minCommand, tmp.minCommand)
                        XCTAssertEqual(settings.minThrottle, tmp.minThrottle)
                        XCTAssertEqual(settings.maxThrottle, tmp.maxThrottle)
                        callback(success)
                    }
                }
            },
            { callback in
                if !config.isApiVersionAtLeast("1.35") {
                    callback(true)
                }
                msp.sendCompassConfig(-0.9) { success in
                    if !success {
                        NSLog("ASSUMING NO COMPASS SUPPORT AVAILABLE")
                        compassSupported = false
                        callback(true)
                    } else {
                        msp.sendMessage(.MSP_COMPASS_CONFIG, data: nil, retry: 2) { success in
                            XCTAssert(success)
                            XCTAssertEqual(settings.magDeclination, -0.9)
                            callback(success)
                        }
                    }
                }
            },
            { callback in
                if !config.isApiVersionAtLeast("1.35") || !gpsSupported {
                    callback(true)
                }
                let tmp = Settings(copyOf: settings)
                tmp.gpsType = 1 - tmp.gpsType
                tmp.gpsUbxSbas = 1 - tmp.gpsUbxSbas
                tmp.gpsAutoBaud = !tmp.gpsAutoBaud
                tmp.gpsAutoConfig = !tmp.gpsAutoConfig
                
                msp.sendGpsConfig(tmp) { success in
                    XCTAssert(success)
                    msp.sendMessage(.MSP_GPS_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.gpsType, tmp.gpsType)
                        XCTAssertEqual(settings.gpsUbxSbas, tmp.gpsUbxSbas)
                        XCTAssertEqual(settings.gpsAutoBaud, tmp.gpsAutoBaud)
                        XCTAssertEqual(settings.gpsAutoConfig, tmp.gpsAutoConfig)
                        callback(success)
                    }
                }
            },
        ]
        chainMspSend(commands) { success in
            XCTAssert(success)
            expectation.fulfill()
        }
    }
}
