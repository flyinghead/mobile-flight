//
//  ValidateFirmwareTest.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 03/06/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import XCTest
@testable import Cleanflight_Configurator

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
        let comm = TCPComm(msp: msp, host: "localhost", port: 8666)
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
                msp.sendMixerConfiguration(1) { success in
                    // betaflight 3.1.7 and earlier do not implement this msp call if compiled for quad only (micro scisky)
                    // All other versions compiled for quad only will fail this test (can't change the mixer type)
                    XCTAssert(success)
                    msp.sendMessage(.MSP_MIXER_CONFIG, data: nil, retry: 2) { success in
                        XCTAssert(success)
                        XCTAssertEqual(settings.mixerConfiguration, 1)
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
                        XCTAssertEqual(settings.rcRate, tmp.rcRate)
                        XCTAssertEqual(settings.rcExpo, tmp.rcExpo)
                        XCTAssertEqual(settings.yawRate, tmp.yawRate)
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
                        XCTAssertEqual(settings.failsafeKillSwitch, tmp.failsafeKillSwitch)
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
        ]
        chainMspSend(commands) { success in
            XCTAssert(success)
            expectation.fulfill()
        }
    }
}
