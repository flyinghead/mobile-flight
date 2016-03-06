//
//  Observable.swift
//  Cleanflight Configurator
//
//  Created by Raphael Jean-Leconte on 06/03/16.
//  Copyright © 2016 Raphael Jean-Leconte. All rights reserved.
//

import Foundation

class Observable<T> {
    typealias Listener = (newValue: T) -> ()
    
    var value: T {
        didSet {
            if !areEqual(oldValue, value) {
                for (_, listener) in observers {
                    listener(newValue: value)
                }
            }
        }
    }
    private var observers = [(target: AnyObject, listener: Listener)]()
    
    init(_ value: T) {
        self.value = value
    }
    
    func addObserver(target: AnyObject, listener: Listener) {
        observers.append((target, listener))
        listener(newValue: value)
    }
    
    func removeObserver(target: AnyObject) {
        observers = observers.filter({ $0.target !== target })
    }
    
    func areEqual(o1: T, _ o2: T) -> Bool {
        return false
    }
}

class ObservableBool : Observable<Bool> {
    override init(_ value: Bool) {
        super.init(value)
    }
    override func areEqual(o1: Bool, _ o2: Bool) -> Bool {
        return o1 == o2
    }
}

class ObservableDouble : Observable<Double> {
    override init(_ value: Double) {
        super.init(value)
    }
    override func areEqual(o1: Double, _ o2: Double) -> Bool {
        return o1 == o2
    }
}

class ObservableInt : Observable<Int> {
    override init(_ value: Int) {
        super.init(value)
    }
    override func areEqual(o1: Int, _ o2: Int) -> Bool {
        return o1 == o2
    }
}

class ObservableString : Observable<String> {
    override init(_ value: String) {
        super.init(value)
    }
    override func areEqual(o1: String, _ o2: String) -> Bool {
        return o1 == o2
    }
}

