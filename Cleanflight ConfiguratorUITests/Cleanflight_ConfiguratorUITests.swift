//
//  Cleanflight_ConfiguratorUITests.swift
//  Cleanflight ConfiguratorUITests
//
//  Created by Raphael Jean-Leconte on 02/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import XCTest
@testable import Cleanflight_Configurator

class Cleanflight_ConfiguratorUITests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        
        XCTAssert(CleanflightSimulator.instance.start(), "Cannot start CleanflightSimulator")
        
        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false
        // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
        XCUIApplication().launch()

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }
    
    override func tearDown() {
        CleanflightSimulator.instance.stop()

        super.tearDown()
    }
    
    func connect() {
        let app = XCUIApplication()
        app.buttons["Wi-Fi"].tap()
        
        let elementsQuery = app.scrollViews.otherElements
        let ipaddressTextField = elementsQuery.textFields["ipAddress"]
        ipaddressTextField.tap()
        ipaddressTextField.tap()
        
        let selectAllMenuItem = app.menuItems["Select All"]
        selectAllMenuItem.tap()
        ipaddressTextField.typeText("127.0.0.1")
        
        let ipportTextField = elementsQuery.textFields["ipPort"]
        ipportTextField.tap()
        ipportTextField.tap()
        selectAllMenuItem.tap()
        ipportTextField.typeText("8777")
        
        elementsQuery.buttons["connect"].tap()
        
        let menu = app.buttons["menuw 1"]
        expect("exists == 1", forObject: menu, andWait: 10)
    }
    
    func expect(predicate: String, forObject: XCUIElement) {
        expectationForPredicate(NSPredicate(format: predicate), evaluatedWithObject: forObject, handler: nil)
    }
    
    func expect(predicate: String, forObject: XCUIElement, andWait: Double) {
        expectationForPredicate(NSPredicate(format: predicate), evaluatedWithObject: forObject, handler: nil)
        waitForExpectationsWithTimeout(andWait, handler: nil)
    }
    
    func testConnectDisconnect() {
        connect()

        let app = XCUIApplication()
        
        XCTAssert(app.staticTexts["DISARMED"].exists)
        // Secondary modes icons
        XCTAssert(app.buttons["camera"].exists)
        XCTAssert(app.buttons["calibrate"].exists)
        XCTAssert(app.buttons["telemetry"].exists)
        XCTAssert(app.buttons["sonar"].exists)
        XCTAssert(app.buttons["recorder"].exists)
        XCTAssert(app.buttons["tuning"].exists)

        XCTAssertEqual(app.staticTexts["rssi"].label, "0%")
        XCTAssertEqual(app.staticTexts["timer"].label, "00:00")
        XCTAssertEqual(app.staticTexts["gpsSats"].label, "0")
        XCTAssertEqual(app.staticTexts["dth"].label, "")
        
        let menu = app.buttons["menuw 1"]
        menu.tap()
        app.buttons["Disconnect"].tap()
        
        XCTAssert(app.buttons["Wi-Fi"].exists)
    }
    
    func testRssi() {
        connect()
        
        let app = XCUIApplication()
        CleanflightSimulator.instance.rssi = 676    // 676 / 1023 = 66%
        
        let rssi = app.staticTexts["rssi"]
        expect("label == '66%'", forObject: rssi, andWait: 5)
    }
    
    func testBatteryIndicators() {
        connect()
        
        let app = XCUIApplication()
        CleanflightSimulator.instance.voltage = 12.3
        CleanflightSimulator.instance.amps = 21.0
        CleanflightSimulator.instance.mAh = 982
        
        let voltage = app.staticTexts["batteryVolts"]
        expect("label == '12.3'", forObject: voltage, andWait: 5)
        let amps = app.staticTexts["batteryAmps"]
        XCTAssertEqual(amps.label, "21")
        let mAh = app.staticTexts["batterymAh"]
        XCTAssertEqual(mAh.label, "982")
    }
    
    func testFlightModes() {
        connect()
        
        let app = XCUIApplication()
        
        let armed = app.staticTexts["armedMode"]
        XCTAssertEqual(armed.label, "DISARMED")
        XCTAssertTrue(armed.hittable)
        
        let acro = app.staticTexts["acroMode"]
        XCTAssertFalse(acro.hittable)
        
        let alt = app.staticTexts["altMode"]
        XCTAssertFalse(alt.hittable)
        
        let pos = app.staticTexts["posMode"]
        XCTAssertFalse(pos.hittable)
        
        let heading = app.staticTexts["headingMode"]
        XCTAssertFalse(heading.hittable)

        let failsafe = app.staticTexts["failsafeMode"]
        XCTAssertFalse(failsafe.hittable)
        
        // Arm
        CleanflightSimulator.instance.setMode(.ARM)
        
        expect("label == 'ARMED'", forObject: armed)
        expect("hittable == 0", forObject: armed)
        let timer = app.staticTexts["timer"]
        // Check that timer started by waiting for 2sec mark
        expect("label == '00:02'", forObject: timer, andWait: 5)

        // Horizon / Angle
        CleanflightSimulator.instance.setMode(.HORIZON)
        expect("label == 'HOZN'", forObject: acro)
        expect("hittable == 1", forObject: acro, andWait: 5)

        CleanflightSimulator.instance.setMode(.ANGLE)
        expect("label == 'ANGL'", forObject: acro)
        expect("hittable == 1", forObject: acro, andWait: 5)
        
        // Pos
        CleanflightSimulator.instance.setMode(.GPSHOLD)
        expect("label == 'POS'", forObject: pos)
        expect("hittable == 1", forObject: pos, andWait: 5)
        CleanflightSimulator.instance.setMode(.GPSHOME)
        expect("label == 'RTH'", forObject: pos)
        expect("hittable == 1", forObject: pos, andWait: 5)
        
        // Alt
        CleanflightSimulator.instance.setMode(.BARO)
        expect("hittable == 1", forObject: alt, andWait: 5)
        CleanflightSimulator.instance.unsetMode(.BARO)
        expect("hittable == 0", forObject: alt, andWait: 5)
        CleanflightSimulator.instance.setMode(.SONAR)
        expect("hittable == 1", forObject: alt, andWait: 5)
        
        // Heading
        CleanflightSimulator.instance.setMode(.MAG)
        expect("hittable == 1", forObject: heading, andWait: 5)
        
        // Failsafe
        CleanflightSimulator.instance.setMode(.FAILSAFE)
        expect("hittable == 1", forObject: failsafe, andWait: 5)
        
    }
    
}
