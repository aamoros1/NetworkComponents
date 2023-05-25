//
//  AsyncToken.swift
//  
//
//
//

import Foundation

/**
 Enumeration of task states
 */
private enum TaskState {
    case running
    case finished
    case cancelled
}

/**
 Token used to track the state of asynchronous operations.
 By convention, a caller of an asynchronous method will receive
 a token as the return value. The caller can choose to cancel
 the operation or wait for it to complete.
 */
open class AsyncToken: NSObject {
    /**
     Lock used to synchronize critical sections.
    */
    private let lock = DispatchSemaphore(value: 1)

    /**
     DispatchGroup used to wait on task completion.
    */
    private let task = DispatchGroup()

    /**
     Task state. Starts off as running until either
     completed or cancelled.
    */
    private var taskState: TaskState

    /**
     Completion result set internally 
    */
    private var completionResult: Any?

    /**
     Optional completion result.
    */
    public var result: Any? {
        defer {
            lock.signal()
        }
        lock.wait()

        return completionResult
    }

    /**
     The time stamp of when the token was created.
     */
    @objc public let timeStamp: Date

    /**
     Test whether the operation has completed. This flag
     will also be true if the operation was cancelled.
     */
    @objc open var isCompleted: Bool {
        defer {
            lock.signal()
        }
        lock.wait()

        return taskState != .running
    }

    /**
     Test whether the operation was cancelled.
     */
    @objc open var isCancelled: Bool {
        defer {
            lock.signal()
        }
        lock.wait()

        return taskState == .cancelled
    }

    @objc override public init() {
        self.timeStamp = Date()

        // Set initial task state to .running
        self.taskState = .running
        self.task.enter()

        super.init()
    }

    /**
     Cancel the operation before it is completed. If the operation
     has completed, then this call does nothing. Cancelling an
     operation will also mark it as completed with no result.
     */
    @objc open func cancel() {
        setTaskState(.cancelled)
    }

    /**
     Mark the operation as completed with out a result.
     This method should only be called by the producer
     of this token.
     */
    @objc public func completed() {
        setTaskState(.finished)
    }

    /**
     Mark the operation as completed with an optional result.
     This method should only be called by the producer of
     this token.
     */
    @objc public func complete(with result: Any?) {
        setTaskState(.finished, with: result)
    }

    /**
     Wait for the operation to complete or cancelled.
     - param millis: the number of milliseconds to wait.
     
     - returns true if the operation was completed
     on or before the specified wait duration.
     */
    @objc open func waitForCompletion(for millis: Int) -> Bool {
        return self.task.wait(timeout: DispatchTime.now() + .milliseconds(millis)) == .success
    }

    /**
     Set the task state and result
     */
    private func setTaskState(_ taskState: TaskState, with result: Any? = nil) {
        defer {
            lock.signal()
        }
        lock.wait()

        // Task state can only be changed from running to
        // the next state once.
        guard self.taskState == .running && self.taskState != taskState else {
            return
        }

        // Update completion result and task state
        self.completionResult = result
        self.taskState = taskState

        // Signal that the task is completed. Either it finished,
        // or was cancelled.
        self.task.leave()
    }
}
