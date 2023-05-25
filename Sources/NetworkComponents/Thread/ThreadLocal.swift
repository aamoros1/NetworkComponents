//
//  ThreadLocal.swift
//
//
//
//

import Foundation

/**
 This class provides thread-local variables. These variables differ from their normal counterparts in that each 
 thread that accesses one (via its value property) has its own, independently initialized copy of the variable. 
 ThreadLocal instances are typically private static fields in classes that wish to associate state with a thread 
 (e.g., a user ID or Transaction ID).
 */
public class ThreadLocal<T: Any> {
    private lazy var key: String = "\(String(reflecting: self))<\(UUID())>"
    private var initialValue: (() -> T?)?

    public required init() {}

    /**
     Initialize an instance with the specified value
     */
    public convenience init(value: T?) {
        self.init()
        self.value = value
    }

    /**
     Initialize an instance with the specified initialValue block. initialValue is invoked when the value is
     first requested, or after the remove method has been called and the value is requested subsequently.
     */
    public convenience init(initialValue: @escaping () -> T?) {
        self.init()
        self.initialValue = initialValue
    }

    deinit {
        remove()
    }

    /**
     -- Get: Returns the value in the current thread's copy of this thread-local variable. If the variable
     has no value for the current thread, it is first initialized to the value returned by an invocation
     of the optional initialValue() block.
 
     -- Set: Sets the current thread's copy of this thread-local variable to the specified value. When specified, 
        initialValue() black is used to set the local value in first request, or on reuqest after calling remove().
     */
    public var value: T? {
        get {
            // No localValue means that either remove() has been called, or this is the
            // first time the value is being retrieved.
            guard let localValue = Thread.current.threadDictionary[key] as? LocalValue<T> else {
                if let initialValue = self.initialValue {
                    // This lock is required to provide thread safety for initialValue
                    defer {
                        objc_sync_exit(key)
                    }
                    objc_sync_enter(key)

                    let value = initialValue()
                    Thread.current.threadDictionary[key] = LocalValue(value: value)
                    return value
                }
                return nil
            }
            return localValue.value
        }
        set {
            Thread.current.threadDictionary[key] = LocalValue(value: newValue)
        }
    }

    /**
     Removes the current thread's value for this thread-local variable. If this thread-local 
     value property is subsequently read by the current thread, its value will be reinitialized 
     by invoking its optional initialValue() block, unless its value is set by the current 
     thread in the interim. This may result in multiple invocations of the initialValue() block 
     in the current thread.
    */
    public func remove() {
        Thread.current.threadDictionary.removeObject(forKey: key)
    }

    /**
      Helper used for storing local values in the thread dictionary
     */
    private struct LocalValue<T: Any> {
        public var value: T?
    }
}
