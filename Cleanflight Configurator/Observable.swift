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
                notifyListeners()
            }
        }
    }
    private var observers = [(target: AnyObject, listener: Listener)]()
    
    init(_ value: T) {
        self.value = value
    }
    
    func addObserver(target: AnyObject, listener: Listener) {
        objc_sync_enter(self)
        observers.append((target, listener))
        objc_sync_exit(self)
        listener(newValue: value)
    }
    
    func removeObserver(target: AnyObject) {
        objc_sync_enter(self)
        observers = observers.filter({ $0.target !== target })
        objc_sync_exit(self)
    }
    
    func areEqual(o1: T, _ o2: T) -> Bool {
        return false
    }
    
    func hasObservers() -> Bool {
        objc_sync_enter(self)
        let ret = observers.count > 0
        objc_sync_exit(self)
        return ret
    }
    
    func notifyListeners() {
        dispatch_async(dispatch_get_main_queue(), {
            objc_sync_enter(self)
            let observers = [(target: AnyObject, listener: Listener)](self.observers)
            objc_sync_exit(self)
            for (_, listener) in observers {
                listener(newValue: self.value)
            }
        })
    }
}

class EquatableObservable<T : Equatable> : Observable<T> {
    override init(_ value: T) {
        super.init(value)
    }
    override func areEqual(o1: T, _ o2: T) -> Bool {
        return o1 == o2
    }
}

class ObservableBool : EquatableObservable<Bool> {
    override init(_ value: Bool) {
        super.init(value)
    }
}

class ObservableDouble : EquatableObservable<Double> {
    override init(_ value: Double) {
        super.init(value)
    }
}

class ObservableInt : EquatableObservable<Int> {
    override init(_ value: Int) {
        super.init(value)
    }
}

class ObservableString : EquatableObservable<String> {
    override init(_ value: String) {
        super.init(value)
    }
}

class NillableObservable<T : Equatable> : Observable<T?> {
    init() {
        super.init(nil)
    }
    
    override func areEqual(o1: T?, _ o2: T?) -> Bool {
        return o1 == o2
    }
}

class NillableObservableBool : NillableObservable<Bool> {
}

class NillableObservableDouble : NillableObservable<Double> {
}

class NillableObservableInt : NillableObservable<Int> {
}

class NillableObservableString : NillableObservable<String> {
}

class NillableObservableArray<ET : Equatable> : Observable<Array<ET>?> {
    init() {
        super.init(nil)
    }
    override func areEqual(o1: Array<ET>?, _ o2: Array<ET>?) -> Bool {
        if o1 == nil {
            return o2 == nil
        } else if o2 == nil {
            return false
        } else {
            return o1! == o2!
        }
    }
}