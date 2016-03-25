//
//  ByteArrayUtils.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 24/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

func fromByteArray<T>(value: [UInt8], _: T.Type, offset: Int = 0) -> T {
    return value.withUnsafeBufferPointer {
        return UnsafePointer<T>($0.baseAddress + offset).memory
    }
}

func toByteArray<T>(var value: T) -> [UInt8] {
    return withUnsafePointer(&value) {
        Array(UnsafeBufferPointer(start: UnsafePointer<UInt8>($0), count: sizeof(T)))
    }
}

