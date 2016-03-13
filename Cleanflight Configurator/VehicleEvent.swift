//
//  VehicleEvent.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 13/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class VehicleEvent<T> {
    typealias Listener = (event: T) -> ()
    
    private var listeners = [(target: AnyObject, listener: Listener)]()
    
    func addListener(target: AnyObject, listener: Listener) {
        synchronized(self) {
            self.listeners.append((target, listener))
        }
    }
    
    func removeListener(target: AnyObject) {
        synchronized(self) {
            self.listeners = self.listeners.filter({ $0.target !== target })
        }
    }

    func newEvent(event: T) {
        dispatch_async(dispatch_get_main_queue(), {
            var listeners: [(target: AnyObject, listener: Listener)]!
            synchronized(self) {
                listeners = [(target: AnyObject, listener: Listener)](self.listeners)
            }
            for (_, listener) in listeners {
                listener(event: event)
            }
        })
        
    }
}