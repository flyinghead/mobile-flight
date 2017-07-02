//
//  Units.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 13/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

let FEET_PER_METER = 100.0 / 2.54 / 12
let METER_PER_MILE = 1609.344
let METER_PER_NM = 1852.0

func formatNumber(n: Double, precision: Int) -> String {
    let formatter = NSNumberFormatter()
    formatter.locale = NSLocale.currentLocale()
    formatter.usesGroupingSeparator = false
    formatter.minimumFractionDigits = precision
    formatter.maximumFractionDigits = precision
    formatter.minimumIntegerDigits = 1
    
    return formatter.stringFromNumber(n)!
}

// Easy formatting of a double value with 1 decimal if < 10, no decimal otherwise. Unit appended to the result.
func formatWithUnit(reading: Double, unit: String) -> String {
    let suffix = unit.isEmpty ? "" : " ".stringByAppendingString(unit)
    if reading < 10 {
        return String(format: "%@%@", formatNumber(reading, precision: 1), suffix)
    } else {
        return String(format: "%@%@", formatNumber(reading, precision: 0), suffix)
    }
}

func formatDistance(meters: Double) -> String {
    switch selectedUnitSystem() {
    case .Imperial:
        if meters >= METER_PER_MILE {
            // Statute mile
            return formatWithUnit(meters / METER_PER_MILE, unit: "mi")
        } else {
            // Feet
            return formatWithUnit(meters * FEET_PER_METER, unit: "ft")
        }
        
    case .Aviation:
        if meters >= METER_PER_NM {
            // Nautical mile
            return formatWithUnit(meters / METER_PER_NM, unit: "NM")
        } else {
            // Feet
            return formatWithUnit(meters * FEET_PER_METER, unit: "ft")
        }
    default:
        if meters >= 1000 {
            // Kilometer
            return formatWithUnit(meters / 1000, unit: "km")
        } else {
            // Meter
            return formatWithUnit(meters, unit: "m")
        }
    }
}

func formatAltitude(meters: Double, appendUnit: Bool = true) -> String {
    if selectedUnitSystem() != .Metric {
        // Feet
        return formatWithUnit(meters * FEET_PER_METER, unit: appendUnit ? "ft" : "")
    } else {
        // Meters
        return formatWithUnit(meters, unit: appendUnit ? "m" : "")
    }
}

func formatSpeed(kmh: Double) -> String {
    switch selectedUnitSystem() {
    case .Imperial:
        // mile/h
        return formatWithUnit(kmh * 1000 / METER_PER_MILE, unit: speedUnit())
    case .Aviation:
        // Knots
        return formatWithUnit(kmh * 1000 / METER_PER_NM, unit: speedUnit())
    default:
        // km/h
        return formatWithUnit(kmh, unit: speedUnit())
    }
}

func formatTemperature(celsius: Double) -> String {
    if selectedUnitSystem() == .Imperial {
        return String(format: "%@° F", formatNumber(celsius * 1.8 + 32, precision: 0))
    } else {
        return String(format: "%@° C", formatNumber(celsius, precision: 0))
    }
}

func msToLocaleSpeed(speed: Double) -> Double {
    let speedKmh = speed * 3600 / 1000
    
    switch selectedUnitSystem() {
    case .Imperial:
        // mile/h
        return speedKmh * 1000 / METER_PER_MILE
    case .Aviation:
        // Knots
        return speedKmh * 1000 / METER_PER_NM
    default:
        // km/h
        return speedKmh
    }
}

func localeSpeedToMs(speed: Double) -> Double {
    let kmhSpeed: Double
    switch selectedUnitSystem() {
    case .Imperial:
        // mile/h
        kmhSpeed = speed / 1000 * METER_PER_MILE
    case .Aviation:
        // Knots
        kmhSpeed = speed / 1000 * METER_PER_NM
    default:
        // km/h
        kmhSpeed = speed
    }
    return kmhSpeed / 3600 * 1000
}

func msToLocaleVerticalSpeed(d: Double) -> Double {
    switch selectedUnitSystem() {
    case .Imperial, .Aviation:
        return d * FEET_PER_METER
    default:
        return d
    }
}

func localeVerticalSpeedToMs(d: Double) -> Double {
    switch selectedUnitSystem() {
    case .Imperial, .Aviation:
        return d / FEET_PER_METER
    default:
        return d
    }
}

func mToLocaleDistance(d: Double) -> Double {
    switch selectedUnitSystem() {
    case .Imperial, .Aviation:
        return d * FEET_PER_METER
    default:
        return d
    }
}

func localeDistanceToM(d: Double) -> Double {
    switch selectedUnitSystem() {
    case .Imperial, .Aviation:
        return d / FEET_PER_METER
    default:
        return d
    }
}

func speedUnit() -> String {
    switch selectedUnitSystem() {
    case .Imperial:
        return "mph"
    case .Aviation:
        return "kn"
    default:
        return "km/h"
    }
}

func verticalSpeedUnit() -> String {
    switch selectedUnitSystem() {
    case .Imperial, .Aviation:
        return "ft/s"
    default:
        return "m/s"
    }
}

func distanceUnit() -> String {
    switch selectedUnitSystem() {
    case .Imperial, .Aviation:
        return "ft"
    default:
        return "m"
    }
}
