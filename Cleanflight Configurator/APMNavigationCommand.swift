//
//  APMNavigationCommand.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 18/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum APMNavigationCommand {
    case NavigateToWaypoint(position: Position3D, delay: Double)
    case TakeOff(altitude: Double)
    case LoiterUnlimited(position: Position3D)
    case LoiterTurns(position: Position3D, turns: Int, radius: Double)
    case Loiter(position: Position3D, delay: Double)
    case ReturnToLaunch
    case Land(position: Position)
    case NavigateSplineWaypoint(position: Position3D, delay: Double)
    case GuidedEnable(enable: Bool)
    
    case Jump(index: Int, times: Int)
    
    case Delay(delay: Double)
    case ChangeAltitude(altitude: Double, vspeed: Double)
    case WaypointDistance(distance: Double)
    case Yaw(degrees: Double, relative: Bool, clockwise: Bool)
    case SetFlightMode(mode: ArduCopterFlightMode)
    case ChangeSpeed(speed: Double)
    case SetHome(currentLocation: Bool, location: Position3D?)
    
    case SetRelay(relayNumber: Int, on: Bool)
    case RepeatRelay(relayNumber: Int, times: Int, delay: Double)
    case SetServo(servoNumber: Int, value: Int)
    case RepeatServo(servoNumber: Int, value: Int, times: Int, delay: Double)
    
    case SetRegionOfInterest(position: Position3D)
    
    // Digicam, mount, cam, parachute; gripper...
    
    static func decodeCommand(item: mavlink_mission_item_t) -> APMNavigationCommand? {
        let position2d = Position(latitude: Double(item.x), longitude: Double(item.y))
        let position3d = Position3D(position2d: position2d, altitude: Double(item.z))
        
        switch MAV_CMD(UInt32(item.command)) {
        case MAV_CMD_NAV_WAYPOINT:
            return NavigateToWaypoint(position: position3d, delay: Double(item.param1))
        case MAV_CMD_NAV_TAKEOFF:
            return TakeOff(altitude: Double(item.z))
        case MAV_CMD_NAV_LOITER_UNLIM:
            return LoiterUnlimited(position: position3d)
        case MAV_CMD_NAV_LOITER_TURNS:
            return LoiterTurns(position: position3d, turns: Int(item.param1), radius: Double(item.param3))
        case MAV_CMD_NAV_LOITER_TIME:
            return Loiter(position: position3d, delay: Double(item.param1))
        case MAV_CMD_NAV_RETURN_TO_LAUNCH:
            return ReturnToLaunch
        case MAV_CMD_NAV_LAND:
            return Land(position: position2d)
        case MAV_CMD_NAV_SPLINE_WAYPOINT:
            return NavigateSplineWaypoint(position: position3d, delay: Double(item.param1))
        case MAV_CMD_NAV_GUIDED_ENABLE:
            return GuidedEnable(enable: item.param1 > 0.5)
        
        case MAV_CMD_DO_JUMP:
            return Jump(index: Int(item.param1), times: Int(item.param2))
        case MAV_CMD_CONDITION_DELAY:
            return Delay(delay: Double(item.param1))
        case MAV_CMD_CONDITION_CHANGE_ALT:
            return ChangeAltitude(altitude: Double(item.z), vspeed: Double(item.param1))
        case MAV_CMD_CONDITION_DISTANCE:
            return WaypointDistance(distance: Double(item.param1))
        case MAV_CMD_CONDITION_YAW:
            return Yaw(degrees: Double(item.param1), relative: item.param4 == 1, clockwise: item.param3 == 1)
        case MAV_CMD_DO_SET_MODE:
            return SetFlightMode(mode: ArduCopterFlightMode(rawValue: Int(item.param1)) ?? .UNKNOWN)
        case MAV_CMD_DO_CHANGE_SPEED:
            return ChangeSpeed(speed: Double(item.param2))
        case MAV_CMD_DO_SET_HOME:
            return SetHome(currentLocation: item.param1 == 1, location: position3d)
            
        case MAV_CMD_DO_SET_RELAY:
            return SetRelay(relayNumber: Int(item.param1), on: item.param2 == 1)
        case MAV_CMD_DO_REPEAT_RELAY:
            return RepeatRelay(relayNumber: Int(item.param1), times: Int(item.param2), delay: Double(item.param3))
        case MAV_CMD_DO_SET_SERVO:
            return SetServo(servoNumber: Int(item.param1), value: Int(item.param2))
        case MAV_CMD_DO_REPEAT_SERVO:
            return RepeatServo(servoNumber: Int(item.param1), value: Int(item.param2), times: Int(item.param3), delay: Double(item.param4))

        default:
            return nil
        }
    }
    
    private func value(value: Double, withDefault: Double) -> Double {
        return value == 0 ? withDefault : value
    }
    
    func targetAltitude(current: Double) -> Double {
        switch self {
        case NavigateToWaypoint(let position, _):
            return value(position.altitude, withDefault: current)
        case TakeOff(let altitude):
            return altitude
        case LoiterUnlimited(let position):
            return value(position.altitude, withDefault: current)
        case LoiterTurns(let position, _, _):
            return value(position.altitude, withDefault: current)
        case Loiter(let position, _):
            return value(position.altitude, withDefault: current)
        case ReturnToLaunch, Land:
            return 0
        case .NavigateSplineWaypoint(let position, _):
            return value(position.altitude, withDefault: current)
        case ChangeAltitude(let altitude, _):
            return altitude
        default:
            return current
        }
    }
    
    // Returns nil if the target position is home
    func targetPosition(currentTarget: Position3D) -> Position3D? {
        var targetPosition: Position3D
        let targetAlt = targetAltitude(currentTarget.altitude)
        
        switch self {
        case NavigateToWaypoint(let position, _):
            targetPosition = position
        case LoiterUnlimited(let position):
            targetPosition = position
        case LoiterTurns(let position, _, _):
            targetPosition = position
        case Loiter(let position, _):
            targetPosition = position
        case Land(let position):
            targetPosition = Position3D(position2d: position, altitude: 0)
        case ReturnToLaunch:
            return nil
        case .NavigateSplineWaypoint(let position, _):
            targetPosition = position
        default:
            return currentTarget
        }
        targetPosition = Position3D(position2d: Position(latitude: value(targetPosition.position2d.latitude, withDefault: currentTarget.position2d.latitude), longitude: value(targetPosition.position2d.longitude, withDefault: currentTarget.position2d.longitude)), altitude: targetAlt)

        return targetPosition
    }
}