//
//  MSPCode.swift
//  Mobile Flight
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
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

enum MSP_code : Int {
    case msp_UNKNOWN =               -1     // Used internally for unknown/unsupported messages
    
    case msp_API_VERSION =            1
    case msp_FC_VARIANT =             2
    case msp_FC_VERSION =             3
    case msp_BOARD_INFO =             4
    case msp_BUILD_INFO =             5
    
    case msp_NAME =                   10
    case msp_SET_NAME =               11
    
    // MSP commands for Cleanflight original features
    case msp_BATTERY_CONFIG =         32
    case msp_SET_BATTERY_CONFIG =     33
    case msp_MODE_RANGES =            34
    case msp_SET_MODE_RANGE =         35
    case msp_FEATURE =                36
    case msp_SET_FEATURE =            37
    case msp_BOARD_ALIGNMENT =        38
    case msp_SET_BOARD_ALIGNMENT =    39
    case msp_CURRENT_METER_CONFIG =   40
    case msp_SET_CURRENT_METER_CONFIG = 41
    case msp_MIXER_CONFIG =           42
    case msp_SET_MIXER_CONFIG =       43
    case msp_RX_CONFIG =              44
    case msp_SET_RX_CONFIG =          45
    case msp_LED_STRIP_CONFIG =       48
    case msp_SET_LED_STRIP_CONFIG =   49
    case msp_RSSI_CONFIG =            50
    case msp_SET_RSSI_CONFIG =        51
    case msp_ADJUSTMENT_RANGES =      52
    case msp_SET_ADJUSTMENT_RANGE =   53
    case msp_CF_SERIAL_CONFIG =       54
    case msp_SET_CF_SERIAL_CONFIG =   55
    case msp_VOLTAGE_METER_CONFIG =   56
    case msp_SET_VOLTAGE_METER_CONFIG = 57
    case msp_SONAR =                  58
    case msp_PID_CONTROLLER =         59
    case msp_SET_PID_CONTROLLER =     60
    case msp_ARMING_CONFIG =          61
    case msp_SET_ARMING_CONFIG =      62
    case msp_DATAFLASH_SUMMARY =      70
    case msp_DATAFLASH_READ =         71
    case msp_DATAFLASH_ERASE =        72
    case msp_LOOP_TIME =              73
    case msp_SET_LOOP_TIME =          74
    case msp_FAILSAFE_CONFIG =        75
    case msp_SET_FAILSAFE_CONFIG =    76
    case msp_RXFAIL_CONFIG =          77
    case msp_SET_RXFAIL_CONFIG =      78
    case msp_SDCARD_SUMMARY =         79
    case msp_BLACKBOX_CONFIG =        80
    case msp_SET_BLACKBOX_CONFIG =    81
    case msp_TRANSPONDER_CONFIG =     82
    case msp_SET_TRANSPONDER_CONFIG = 83
    
    // Betaflight Additional Commands
    case msp_OSD_CONFIG =             84
    case msp_SET_OSD_CONFIG =         85
    case msp_OSD_CHAR_READ =          86
    case msp_OSD_CHAR_WRITE =         87
    case msp_VTX_CONFIG =             88
    case msp_SET_VTX_CONFIG =         89
    case msp_ADVANCED_CONFIG =        90
    case msp_SET_ADVANCED_CONFIG =    91
    case msp_FILTER_CONFIG =          92
    case msp_SET_FILTER_CONFIG =      93
    case msp_ADVANCED_TUNING =        94    // aka MSP_PID_ADVANCED in bf code
    case msp_SET_ADVANCED_TUNING =    95    // aka ...
    case msp_SENSOR_CONFIG =          96
    case msp_SET_SENSOR_CONFIG =      97
    case msp_CAMERA_CONTROL =         98
    case msp_ARMING_DISABLE =         99    // Disable arming
    
    // Multiwii MSP commands
    case msp_IDENT =              100
    case msp_STATUS =             101
    case msp_RAW_IMU =            102
    case msp_SERVO =              103
    case msp_MOTOR =              104
    case msp_RC =                 105
    case msp_RAW_GPS =            106
    case msp_COMP_GPS =           107
    case msp_ATTITUDE =           108
    case msp_ALTITUDE =           109
    case msp_ANALOG =             110
    case msp_RC_TUNING =          111
    case msp_PID =                112
    case msp_ACTIVEBOXES =        113   // INAV 1.7.3: to use when more than 32 modes are available (not yet in 1.7.3)
    case msp_MISC =               114
    case msp_MOTOR_PINS =         115
    case msp_BOXNAMES =           116
    case msp_PIDNAMES =           117
    case msp_WP =                 118
    case msp_BOXIDS =             119
    case msp_SERVO_CONFIGURATIONS = 120
    case msp_RC_DEADBAND =        125
    case msp_MOTOR_CONFIG =       131
    case msp_GPS_CONFIG =         132
    case msp_COMPASS_CONFIG =     133
    case msp_ESC_SENSOR_DATA =    134   // Extra ESC data from 32-bit ESCs (Temperature, RPM)
    
    case msp_DISPLAYPORT =        182

    case msp_COPY_PROFILE =       183
    
    case msp_BEEPER_CONFIG =      184
    case msp_SET_BEEPER_CONFIG =  185
    
    case msp_SET_RAW_RC =         200
    case msp_SET_RAW_GPS =        201
    case msp_SET_PID =            202
    case msp_SET_BOX =            203
    case msp_SET_RC_TUNING =      204
    case msp_ACC_CALIBRATION =    205
    case msp_MAG_CALIBRATION =    206
    case msp_SET_MISC =           207
    case msp_RESET_CONF =         208
    case msp_SET_WP =             209
    case msp_SELECT_SETTING =     210
    case msp_SET_HEAD =           211
    case msp_SET_SERVO_CONFIGURATION = 212
    case msp_SET_MOTOR =          214
    case msp_SET_RC_DEADBAND =    218
    case msp_SET_RESET_CURR_PID = 219
    case msp_SET_MOTOR_CONFIG =   222
    case msp_SET_GPS_CONFIG =     223
    case msp_SET_COMPASS_CONFIG = 224
    // case MSP_BIND =               240
    
    case msp_EEPROM_WRITE =       250
    
    case msp_DEBUGMSG =           253
    case msp_DEBUG =              254
    
    // Additional baseflight commands that are not compatible with MultiWii
    case msp_STATUS_EX =          150 // same as STATUS plus CPU load
    case msp_UID =                160 // Unique device ID
    case msp_ACC_TRIM =           240 // get acc angle trim values
    case msp_SET_ACC_TRIM =       239 // set acc angle trim values
    case msp_GPSSVINFO =          164 // get Signal Strength
    
    // Additional private MSP for baseflight configurator (yes thats us \o/)
    case msp_RX_MAP =              64 // get channel map (also returns number of channels total)
    case msp_SET_RX_MAP =          65 // set rc map numchannels to set comes from MSP_RX_MAP
    case msp_BF_CONFIG =             66 // baseflight-specific settings that aren't covered elsewhere
    case msp_SET_BF_CONFIG =         67 // baseflight-specific settings save
    case msp_SET_REBOOT =         68 // reboot settings
    case msp_BF_BUILD_INFO =          69  // build date as well as some space for future expansion
    
    // 3DR Radio RSSI (SIK-multiwii firmware)
    case msp_SIKRADIO =            199
    
    // INav
    case msp_NAV_POSHOLD =          12
    case msp_SET_NAV_POSHOLD =      13
    case msp_WP_MISSION_LOAD =      18
    case msp_WP_MISSION_SAVE =      19
    case msp_WP_GETINFO =           20  // INav 1.7
    case msp_RTH_AND_LAND_CONFIG =  21  // INav 1.7.1
    case msp_SET_RTH_AND_LAND_CONFIG = 22 // INav 1.7.1
    case msp_FW_CONFIG =            23  // INav 1.7.1
    case msp_SET_FW_CONFIG =        24  // INav 1.7.1
    case msp_NAV_STATUS =          121
    case msp_SENSOR_STATUS =       151
}

