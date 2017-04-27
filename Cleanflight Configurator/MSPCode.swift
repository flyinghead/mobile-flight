//
//  MSPCode.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 12/12/15.
//  Copyright © 2015 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

enum MSP_code : Int {
    case MSP_UNKNOWN =               -1     // Used internally for unknown/unsupported messages
    
    case MSP_API_VERSION =            1
    case MSP_FC_VARIANT =             2
    case MSP_FC_VERSION =             3
    case MSP_BOARD_INFO =             4
    case MSP_BUILD_INFO =             5
    
    // MSP commands for Cleanflight original features
    case MSP_BATTERY_CONFIG =         32
    case MSP_SET_BATTERY_CONFIG =     33
    case MSP_MODE_RANGES =            34
    case MSP_SET_MODE_RANGE =         35
    case MSP_FEATURE =                36
    case MSP_SET_FEATURE =            37
    case MSP_BOARD_ALIGNMENT =        38
    case MSP_SET_BOARD_ALIGNMENT =    39
    case MSP_CURRENT_METER_CONFIG =   40
    case MSP_SET_CURRENT_METER_CONFIG = 41
    case MSP_MIXER_CONFIG =           42
    case MSP_SET_MIXER_CONFIG =       43
    case MSP_RX_CONFIG =              44
    case MSP_SET_RX_CONFIG =          45
    case MSP_LED_STRIP_CONFIG =       48
    case MSP_SET_LED_STRIP_CONFIG =   49
    case MSP_RSSI_CONFIG =            50
    case MSP_SET_RSSI_CONFIG =        51
    case MSP_ADJUSTMENT_RANGES =      52
    case MSP_SET_ADJUSTMENT_RANGE =   53
    case MSP_CF_SERIAL_CONFIG =       54
    case MSP_SET_CF_SERIAL_CONFIG =   55
    case MSP_VOLTAGE_METER_CONFIG =   56
    case MSP_SET_VOLTAGE_METER_CONFIG = 57
    case MSP_SONAR =                  58
    case MSP_PID_CONTROLLER =         59
    case MSP_SET_PID_CONTROLLER =     60
    case MSP_ARMING_CONFIG =          61
    case MSP_SET_ARMING_CONFIG =      62
    case MSP_DATAFLASH_SUMMARY =      70
    case MSP_DATAFLASH_READ =         71
    case MSP_DATAFLASH_ERASE =        72
    case MSP_LOOP_TIME =              73
    case MSP_SET_LOOP_TIME =          74
    case MSP_FAILSAFE_CONFIG =        75
    case MSP_SET_FAILSAFE_CONFIG =    76
    case MSP_RXFAIL_CONFIG =          77
    case MSP_SET_RXFAIL_CONFIG =      78
    case MSP_SDCARD_SUMMARY =         79
    case MSP_BLACKBOX_CONFIG =        80
    case MSP_SET_BLACKBOX_CONFIG =    81
    case MSP_TRANSPONDER_CONFIG =     82
    case MSP_SET_TRANSPONDER_CONFIG = 83
    
    // Betaflight Additional Commands
    case MSP_PID_ADVANCED_CONFIG =    90    // aka MSP_ADVANCED_CONFIG in bf code
    case MSP_SET_PID_ADVANCED_CONFIG = 91   // aka ...
    case MSP_FILTER_CONFIG =          92
    case MSP_SET_FILTER_CONFIG =      93
    case MSP_ADVANCED_TUNING =        94    // aka MSP_PID_ADVANCED in bf code
    case MSP_SET_ADVANCED_TUNING =    95    // aka ...
    case MSP_SENSOR_CONFIG =          96
    case MSP_SET_SENSOR_CONFIG =      97
    
    // Multiwii MSP commands
    case MSP_IDENT =              100
    case MSP_STATUS =             101
    case MSP_RAW_IMU =            102
    case MSP_SERVO =              103
    case MSP_MOTOR =              104
    case MSP_RC =                 105
    case MSP_RAW_GPS =            106
    case MSP_COMP_GPS =           107
    case MSP_ATTITUDE =           108
    case MSP_ALTITUDE =           109
    case MSP_ANALOG =             110
    case MSP_RC_TUNING =          111
    case MSP_PID =                112
    case MSP_BOX =                113
    case MSP_MISC =               114
    case MSP_MOTOR_PINS =         115
    case MSP_BOXNAMES =           116
    case MSP_PIDNAMES =           117
    case MSP_WP =                 118
    case MSP_BOXIDS =             119
    case MSP_SERVO_CONFIGURATIONS = 120
    case MSP_RC_DEADBAND =        125
    case MSP_MOTOR_CONFIG =       131
    case MSP_GPS_CONFIG =         132
    case MSP_COMPASS_CONFIG =     133
    
    case MSP_SET_RAW_RC =         200
    case MSP_SET_RAW_GPS =        201
    case MSP_SET_PID =            202
    case MSP_SET_BOX =            203
    case MSP_SET_RC_TUNING =      204
    case MSP_ACC_CALIBRATION =    205
    case MSP_MAG_CALIBRATION =    206
    case MSP_SET_MISC =           207
    case MSP_RESET_CONF =         208
    case MSP_SET_WP =             209
    case MSP_SELECT_SETTING =     210
    case MSP_SET_HEAD =           211
    case MSP_SET_SERVO_CONFIGURATION = 212
    case MSP_SET_MOTOR =          214
    case MSP_SET_RC_DEADBAND =    218
    case MSP_SET_RESET_CURR_PID = 219
    case MSP_SET_MOTOR_CONFIG =   222
    case MSP_SET_GPS_CONFIG =     223
    case MSP_SET_COMPASS_CONFIG = 224
    // case MSP_BIND =               240
    
    case MSP_EEPROM_WRITE =       250
    
    case MSP_DEBUGMSG =           253
    case MSP_DEBUG =              254
    
    // Additional baseflight commands that are not compatible with MultiWii
    case MSP_STATUS_EX =          150 // same as STATUS plus CPU load
    case MSP_UID =                160 // Unique device ID
    case MSP_ACC_TRIM =           240 // get acc angle trim values
    case MSP_SET_ACC_TRIM =       239 // set acc angle trim values
    case MSP_GPSSVINFO =          164 // get Signal Strength
    
    // Additional private MSP for baseflight configurator (yes thats us \o/)
    case MSP_RX_MAP =              64 // get channel map (also returns number of channels total)
    case MSP_SET_RX_MAP =          65 // set rc map numchannels to set comes from MSP_RX_MAP
    case MSP_BF_CONFIG =             66 // baseflight-specific settings that aren't covered elsewhere
    case MSP_SET_BF_CONFIG =         67 // baseflight-specific settings save
    case MSP_SET_REBOOT =         68 // reboot settings
    case MSP_BF_BUILD_INFO =          69  // build date as well as some space for future expansion
    
    // 3DR Radio RSSI (SIK-multiwii firmware)
    case MSP_SIKRADIO =            199
}

