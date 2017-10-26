//
//  FirstTest.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 24/02/16.
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

import XCTest
import KIF
@testable import MobileFlight

class TelemetryTest : XCTestCase {
    static var simulatorStarted = false
    
    override func setUp() {
        super.setUp()
        
        if !TelemetryTest.simulatorStarted {
            XCTAssert(CleanflightSimulator.instance.start(), "Cannot start CleanflightSimulator")
            TelemetryTest.simulatorStarted = true
        }
    }
    
    override func tearDown() {
        CleanflightSimulator.instance.resetValues()
        disconnect()
        
        super.tearDown()
    }
    
    fileprivate func connect() {
        tester().tapView(withAccessibilityLabel: "Wi-Fi")
        tester().clearText(fromAndThenEnterText: "localhost", intoViewWithAccessibilityIdentifier: "ipAddress")
        tester().clearText(fromAndThenEnterText: "8777", intoViewWithAccessibilityIdentifier: "ipPort")
        tester().tapView(withAccessibilityIdentifier: "connect")
        UIAutomationHelper.acknowledgeSystemAlert()
        
        tester().waitForView(withAccessibilityLabel: "menuw 1")
    }
    
    fileprivate func disconnect() {
        // Disconnect from simulator
        if UIApplication.shared.keyWindow!.accessibilityElement(withLabel: "Wi-Fi") == nil {
            tester().tapView(withAccessibilityLabel: "menuw 1")
            tester().tapView(withAccessibilityLabel: "Disconnect")
            tester().waitForTappableView(withAccessibilityLabel: "Wi-Fi")
        }
    }
    
    func testConnectDisconnect() {
        connect()
        tester().tapView(withAccessibilityLabel: "menuw 1")
        tester().tapView(withAccessibilityLabel: "Disconnect")
        tester().waitForTappableView(withAccessibilityLabel: "Wi-Fi")
    }
    
    fileprivate func colorsEqual(_ color1: UIColor, _ color2: UIColor) -> Bool {
        var red1: CGFloat = 0, green1: CGFloat = 0, blue1: CGFloat = 0, alpha1: CGFloat = 0
        color1.getRed(&red1, green: &green1, blue: &blue1, alpha: &alpha1)
        var red2: CGFloat = 0, green2: CGFloat = 0, blue2: CGFloat = 0, alpha2: CGFloat = 0
        color1.getRed(&red2, green: &green2, blue: &blue2, alpha: &alpha2)

        return red1 == red2 && green1 == green2 && blue1 == blue2 && alpha1 == alpha2
    }
    
    func testRssi() {
        connect()
        UserDefaults().set(true, forKey: "rssialarm_enabled")
        UserDefaults().set(20, forKey: "rssialarm_low")
        UserDefaults().set(10, forKey: "rssialarm_critical")

        let rssi = tester().waitForView(withAccessibilityIdentifier: "rssi") as! UILabel
        XCTAssert(colorsEqual(rssi.textColor, UIColor.red))
        // Check blink
        tester().wait(for: nil, view: nil, withElementMatching: NSPredicate(format: "alpha == 0 && accessibilityIdentifier == 'rssi'"), tappable: false)
        tester().wait(for: nil, view: nil, withElementMatching: NSPredicate(format: "alpha == 1 && accessibilityIdentifier == 'rssi'"), tappable: false)
        tester().wait(for: nil, view: nil, withElementMatching: NSPredicate(format: "alpha == 0 && accessibilityIdentifier == 'rssi'"), tappable: false)

        CleanflightSimulator.instance.rssi = 676    // 676 / 1023 = 66%
        
        tester().waitForView(withAccessibilityLabel: "66%")
        XCTAssert(colorsEqual(rssi.textColor, UIColor.white))
        
        UserDefaults().set(70, forKey: "rssialarm_low")
        XCTAssert(colorsEqual(rssi.textColor, UIColor.yellow))
        
        UserDefaults().set(70, forKey: "rssialarm_critical")
        XCTAssert(colorsEqual(rssi.textColor, UIColor.red))
    }

    func testBatteryIndicators() {
        connect()

        CleanflightSimulator.instance.voltage = 12.3
        tester().waitForView(withAccessibilityLabel: "12.3")
        
        CleanflightSimulator.instance.amps = 21.0
        tester().waitForView(withAccessibilityLabel: "21")
        
        CleanflightSimulator.instance.mAh = 982
        tester().waitForView(withAccessibilityLabel: "982")
    }

    func testFlightModes() {
        connect()

        tester().waitForView(withAccessibilityLabel: "DISARMED")

        tester().waitForAbsenceOfView(withAccessibilityIdentifier: "acroMode")
        tester().waitForAbsenceOfView(withAccessibilityIdentifier: "altMode")
        tester().waitForAbsenceOfView(withAccessibilityIdentifier: "posMode")
        tester().waitForAbsenceOfView(withAccessibilityIdentifier: "headingMode")
        tester().waitForAbsenceOfView(withAccessibilityIdentifier: "failsafeMode")
        
        // Arm
        CleanflightSimulator.instance.setMode(.ARM)
        
        tester().waitForAbsenceOfView(withAccessibilityLabel: "DISARMED")
        tester().waitForView(withAccessibilityLabel: "ARMED")
        tester().waitForAbsenceOfView(withAccessibilityLabel: "ARMED")
        
        // Check that timer started by waiting for 2sec mark
        tester().waitForView(withAccessibilityLabel: "00:02")
        
        // Horizon / Angle
        CleanflightSimulator.instance.setMode(.HORIZON)
        tester().waitForView(withAccessibilityLabel: "HOZN")
        
        CleanflightSimulator.instance.setMode(.ANGLE)
        tester().waitForAbsenceOfView(withAccessibilityLabel: "HOZN")
        tester().waitForView(withAccessibilityLabel: "ANGL")
        
        // Pos
        CleanflightSimulator.instance.setMode(.GPS_HOLD)
        tester().waitForView(withAccessibilityLabel: "POS")
        CleanflightSimulator.instance.setMode(.GPS_HOME)
        tester().waitForAbsenceOfView(withAccessibilityLabel: "POS")
        tester().waitForView(withAccessibilityLabel: "RTH")
        
        // Alt
        let sonarButton = tester().waitForView(withAccessibilityIdentifier: "sonarMode")
        XCTAssertEqual(sonarButton?.tintColor, UIColor.black)
        
        CleanflightSimulator.instance.setMode(.BARO)
        tester().waitForView(withAccessibilityLabel: "ALT")
        XCTAssertEqual(sonarButton?.tintColor, UIColor.black)
        CleanflightSimulator.instance.unsetMode(.BARO)
        tester().waitForAbsenceOfView(withAccessibilityLabel: "ALT")
        CleanflightSimulator.instance.setMode(.SONAR)
        tester().waitForView(withAccessibilityLabel: "ALT")
        XCTAssertEqual(sonarButton?.tintColor, UIColor.green)
        
        // Heading
        CleanflightSimulator.instance.setMode(.MAG)
        tester().waitForView(withAccessibilityLabel: "HDG")
        
        // Failsafe
        CleanflightSimulator.instance.setMode(.FAILSAFE)
        tester().waitForView(withAccessibilityLabel: "RX FAIL")
        
        // Air Mode
        CleanflightSimulator.instance.setMode(.AIR)
        tester().waitForView(withAccessibilityLabel: "AIR")
    }
    
    func testSecondaryFlightModes() {
        connect()
        doTestSecondaryFlightMode(.TELEMETRY, viewId: "telemetryMode")
        doTestSecondaryFlightMode(.CAMSTAB, viewId: "camstabMode")
        doTestSecondaryFlightMode(.CALIB, viewId: "calibrateMode")
        doTestSecondaryFlightMode(.BLACKBOX, viewId: "blackboxMode")
        doTestSecondaryFlightMode(.GTUNE, viewId: "autotuneMode")
        
    }
    fileprivate func doTestSecondaryFlightMode(_ mode: Mode, viewId: String) {
        let view = tester().waitForView(withAccessibilityIdentifier: viewId)
        XCTAssertEqual(view?.tintColor, UIColor.black)
        CleanflightSimulator.instance.setMode(mode)
        tester().wait(forTimeInterval: 0.3)
        XCTAssertEqual(view?.tintColor, UIColor.green)
        CleanflightSimulator.instance.unsetMode(mode)
        tester().wait(forTimeInterval: 0.3)
        XCTAssertEqual(view?.tintColor, UIColor.black)
    }
    
    func testIndicators() {
        connect()
        let attitude = tester().waitForView(withAccessibilityIdentifier: "attitudeIndicator") as! AttitudeIndicator2
        let heading = tester().waitForView(withAccessibilityIdentifier: "headingIndicator") as! HeadingStrip
        let altitude = tester().waitForView(withAccessibilityIdentifier: "altitudeIndicator") as! VerticalScale
        let variometer = tester().waitForView(withAccessibilityIdentifier: "variometerIndicator") as! SimpleVerticalScale
        let speed = tester().waitForView(withAccessibilityIdentifier: "speedIndicator") as! VerticalScale
        
        CleanflightSimulator.instance.roll = 15.0
        CleanflightSimulator.instance.pitch = -22.0
        CleanflightSimulator.instance.heading = 172
        
        CleanflightSimulator.instance.altitude = 32.7
        CleanflightSimulator.instance.variometer = 4.5
        
        CleanflightSimulator.instance.numSats = 5
        CleanflightSimulator.instance.speed = 8.7
        
        tester().wait(forTimeInterval: 0.3)
        XCTAssertEqual(attitude.roll, 15.0)
        XCTAssertEqual(attitude.pitch, -22.0)
        XCTAssertEqual(heading.heading, 172.0)
        XCTAssertEqualWithAccuracy(altitude.currentValue, 107.28, accuracy: 0.1)        // 32.7 m = 107.28 ft
        XCTAssertEqualWithAccuracy(variometer.currentValue, 14.76, accuracy: 0.1)       // 4.5 m/s = 14.76 ft/s
        XCTAssertEqualWithAccuracy(speed.currentValue, 5.41, accuracy: 0.1)             // 8.7 km/h = 5.41 mph
    }
    
    func testGPSSatsAndDTH() {
        connect()
        
        CleanflightSimulator.instance.numSats = 4
        
        let gpsSats = tester().waitForView(withAccessibilityIdentifier: "gpsSats") as! UILabel
        XCTAssert(colorsEqual(gpsSats.textColor, UIColor.red))
        // Check blink
        tester().wait(for: nil, view: nil, withElementMatching: NSPredicate(format: "alpha == 0 && accessibilityIdentifier == 'gpsSats'"), tappable: false)
        tester().wait(for: nil, view: nil, withElementMatching: NSPredicate(format: "alpha == 1 && accessibilityIdentifier == 'gpsSats'"), tappable: false)
        tester().wait(for: nil, view: nil, withElementMatching: NSPredicate(format: "alpha == 0 && accessibilityIdentifier == 'gpsSats'"), tappable: false)

        tester().tapView(withAccessibilityLabel: "menuw 1")
        let followMe = tester().waitForView(withAccessibilityLabel: "Follow Me") as! UIButton
        XCTAssert(!followMe.isEnabled)

        CleanflightSimulator.instance.numSats = 17
        CleanflightSimulator.instance.distanceToHome = 88
        
        tester().waitForView(withAccessibilityLabel: "17")
        tester().waitForView(withAccessibilityLabel: "289 ft") // = 88m
        tester().tapView(withAccessibilityLabel: "menuw 1")
        XCTAssert(followMe.isEnabled)
        XCTAssert(colorsEqual(gpsSats.textColor, UIColor.white))
        
        CleanflightSimulator.instance.distanceToHome = Int(METER_PER_MILE * 1.5)
        tester().waitForView(withAccessibilityLabel: "1.5 mi")
    }
}
