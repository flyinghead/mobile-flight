//
//  Event.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 10/05/17.
//  Copyright © 2017 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

public class Event<T> {
    
    public typealias EventHandler = T -> ()
    
    private var eventHandlers = [Invocable]()
    
    public func raise(data: T) {
        for handler in self.eventHandlers {
            handler.invoke(data)
        }
    }
    
    public func raiseDispatch(data: T) {
        dispatch_async(dispatch_get_main_queue()) {
            self.raise(data)
        }
    }
    
    public func addHandler<U: AnyObject>(target: U,
                           handler: (U) -> EventHandler) -> Disposable {
        let wrapper = EventHandlerWrapper(target: target,
                                          handler: handler, event: self)
        eventHandlers.append(wrapper)
        return wrapper
    }
}

private protocol Invocable: class {
    func invoke(data: Any)
}

private class EventHandlerWrapper<T: AnyObject, U> : Invocable, Disposable {
    weak var target: T?
    let handler: T -> U -> ()
    let event: Event<U>
    
    init(target: T?, handler: T -> U -> (), event: Event<U>) {
        self.target = target
        self.handler = handler
        self.event = event;
    }
    
    func invoke(data: Any) -> () {
        if let t = target {
            handler(t)(data as! U)
        }
    }
    
    func dispose() {
        event.eventHandlers =
            event.eventHandlers.filter { $0 !== self }
    }
}

public protocol Disposable {
    func dispose()
}
