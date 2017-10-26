//
//  Units.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 13/05/17.
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

import Foundation

let FEET_PER_METER = 100.0 / 2.54 / 12
let METER_PER_MILE = 1609.344
let METER_PER_NM = 1852.0

func formatNumber(_ n: Double, precision: Int) -> String {
    let formatter = NumberFormatter()
    formatter.locale = Locale.current
    formatter.usesGroupingSeparator = false
    formatter.minimumFractionDigits = precision
    formatter.maximumFractionDigits = precision
    formatter.minimumIntegerDigits = 1
    
    return formatter.string(from: NSNumber(value: n))!
}

// Easy formatting of a double value with 1 decimal if < 10, no decimal otherwise. Unit appended to the result.
func formatWithUnit(_ reading: Double, unit: String) -> String {
    let suffix = unit.isEmpty ? "" : " " + unit
    if reading < 10 {
        return String(format: "%@%@", formatNumber(reading, precision: 1), suffix)
    } else {
        return String(format: "%@%@", formatNumber(reading, precision: 0), suffix)
    }
}

func formatDistance(_ meters: Double) -> String {
    switch selectedUnitSystem() {
    case .imperial:
        if meters >= METER_PER_MILE {
            // Statute mile
            return formatWithUnit(meters / METER_PER_MILE, unit: "mi")
        } else {
            // Feet
            return formatWithUnit(meters * FEET_PER_METER, unit: "ft")
        }
        
    case .aviation:
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

func formatAltitude(_ meters: Double, appendUnit: Bool = true) -> String {
    if selectedUnitSystem() != .metric {
        // Feet
        return formatWithUnit(meters * FEET_PER_METER, unit: appendUnit ? "ft" : "")
    } else {
        // Meters
        return formatWithUnit(meters, unit: appendUnit ? "m" : "")
    }
}

func formatSpeed(_ kmh: Double) -> String {
    switch selectedUnitSystem() {
    case .imperial:
        // mile/h
        return formatWithUnit(kmh * 1000 / METER_PER_MILE, unit: speedUnit())
    case .aviation:
        // Knots
        return formatWithUnit(kmh * 1000 / METER_PER_NM, unit: speedUnit())
    default:
        // km/h
        return formatWithUnit(kmh, unit: speedUnit())
    }
}

func formatTemperature(_ celsius: Double) -> String {
    if selectedUnitSystem() == .imperial {
        return String(format: "%@° F", formatNumber(celsius * 1.8 + 32, precision: 0))
    } else {
        return String(format: "%@° C", formatNumber(celsius, precision: 0))
    }
}

func msToLocaleSpeed(_ speed: Double) -> Double {
    let speedKmh = speed * 3600 / 1000
    
    switch selectedUnitSystem() {
    case .imperial:
        // mile/h
        return speedKmh * 1000 / METER_PER_MILE
    case .aviation:
        // Knots
        return speedKmh * 1000 / METER_PER_NM
    default:
        // km/h
        return speedKmh
    }
}

func localeSpeedToMs(_ speed: Double) -> Double {
    let kmhSpeed: Double
    switch selectedUnitSystem() {
    case .imperial:
        // mile/h
        kmhSpeed = speed / 1000 * METER_PER_MILE
    case .aviation:
        // Knots
        kmhSpeed = speed / 1000 * METER_PER_NM
    default:
        // km/h
        kmhSpeed = speed
    }
    return kmhSpeed / 3600 * 1000
}

func msToLocaleVerticalSpeed(_ d: Double) -> Double {
    switch selectedUnitSystem() {
    case .imperial, .aviation:
        return d * FEET_PER_METER
    default:
        return d
    }
}

func localeVerticalSpeedToMs(_ d: Double) -> Double {
    switch selectedUnitSystem() {
    case .imperial, .aviation:
        return d / FEET_PER_METER
    default:
        return d
    }
}

func mToLocaleDistance(_ d: Double) -> Double {
    switch selectedUnitSystem() {
    case .imperial, .aviation:
        return d * FEET_PER_METER
    default:
        return d
    }
}

func localeDistanceToM(_ d: Double) -> Double {
    switch selectedUnitSystem() {
    case .imperial, .aviation:
        return d / FEET_PER_METER
    default:
        return d
    }
}

func speedUnit() -> String {
    switch selectedUnitSystem() {
    case .imperial:
        return "mph"
    case .aviation:
        return "kn"
    default:
        return "km/h"
    }
}

func verticalSpeedUnit() -> String {
    switch selectedUnitSystem() {
    case .imperial, .aviation:
        return "ft/s"
    default:
        return "m/s"
    }
}

func distanceUnit() -> String {
    switch selectedUnitSystem() {
    case .imperial, .aviation:
        return "ft"
    default:
        return "m"
    }
}
