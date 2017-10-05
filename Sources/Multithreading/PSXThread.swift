/// Copyright 2017 Sergei Egorov
///
/// Licensed under the Apache License, Version 2.0 (the "License");
/// you may not use this file except in compliance with the License.
/// You may obtain a copy of the License at
///
/// http://www.apache.org/licenses/LICENSE-2.0
///
/// Unless required by applicable law or agreed to in writing, software
/// distributed under the License is distributed on an "AS IS" BASIS,
/// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
/// See the License for the specific language governing permissions and
/// limitations under the License.

#if os(macOS) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
    import LXPThread
#endif

import Foundation

public enum PSXThreadStatus: UInt8 {
    case inactive = 0
    case waiting  = 1
    case working  = 2
    case paused   = 3
}

public class PSXThread {
        
    /// POSIX thread
    #if os(OSX) || os(iOS)
        internal var pthread: pthread_t? = nil
    #elseif os(Linux)
        internal var pthread = pthread_t()
    #endif
    
    /// Attributes with which the thread will be created.
    fileprivate var attributes = pthread_attr_t()
    
    /// Link to the self, that will be sended to the main routine to run in it run loop of the thread.
    fileprivate var current: PSXThread?
    
    /// Blocked signal for resuming thread work.
    fileprivate var resumeSignal = sigset_t()
    
    /// The queue from which the jobs are executed sequentially.
    internal let privateQueue = PSXJobQueue()
    
    /// The infinite loop in which the job directed to the thread are executed.
    internal var runLoop: PSXRunLoop?
    
    /// Status of the thread.
    public internal(set) var status: PSXThreadStatus = .inactive
    
    /// Thread name for profiling and debuging
    public var name: String {
        set {
            if status == .inactive { _name = newValue }
        }
        get {
            return _name
        }
    }
    fileprivate var _name = "com.swixbase.multithreading.psxthread"
    
    /// Initialization.
    ///
    public init() {
        withUnsafeMutablePointer(to: &attributes) { attrib in
            pthread_attr_init(attrib)
            pthread_attr_setscope(attrib, Int32(PTHREAD_SCOPE_SYSTEM))
            pthread_attr_setdetachstate(attrib, Int32(PTHREAD_CREATE_DETACHED))
        }
        sigemptyset(&resumeSignal)
        sigaddset(&resumeSignal, SIGUSR1)
        pthread_sigmask(SIG_BLOCK, &resumeSignal, nil)
        current = self
        runLoop = PSXRunLoop(for: self)
    }
    
    /// Initialization.
    ///
    /// - Parameter block: A block of code that will be executed in the created thread.
    ///
    public convenience init(_ block: @escaping () -> Void) {
        self.init()
        let job = PSXJob(block: block)
        addJob(job)
    }
    
    deinit { cancel() }

}

extension PSXThread {
    
    /// Puts a block of code in a private queue.
    ///
    /// - Parameter job: A job that will be executed in the thread.
    ///
    internal func addJob(_ job: PSXJob) {
        privateQueue.put(newJob: job, priority: .normal)
    }

    /// Puts a block of code in a private queue.
    ///
    /// - Parameter block: A block of code that will be executed in the thread.
    ///
    public func doJob(_ block: @escaping () -> Void) {
        let job = PSXJob(block: block)
        privateQueue.put(newJob: job, priority: .normal)
    }

}

extension PSXThread {
    
    /// Creates a new thread.
    ///
    public func start() {
        pthread_create(&pthread, &attributes, runThread, &current)
    }
    
    /// Starts an infinite loop in which the job directed to the thread are executed.
    ///
    internal func run() {
        if let runLoop = runLoop { runLoop.run() }
    }
    
    /// Pause the execution of jobs by the thread.
    ///
    public func pause() {
        if status != .inactive && status != .paused {
            let job = PSXJob(block: { 
                if let runLoop = self.runLoop {
                    runLoop.stop()
                    self.status = .paused
                    var sig: Int32 = 0
                    sigwait(&self.resumeSignal, &sig)
                    runLoop.run()
                }
            })
            privateQueue.put(newJob: job, priority: .high)
        }
    }
    
    /// Resumes execution of jobs.
    ///
    public func resume() {
        #if os(OSX) || os(iOS)
            pthread_kill(pthread!, SIGUSR1)
        #elseif os(Linux)
            pthread_kill(pthread, SIGUSR1)
        #endif
    }
    
    /// Terminates the thread.
    ///
    public func cancel() {
        if let runLoop = self.runLoop { runLoop.stop() }
        #if os(OSX) || os(iOS)
            pthread_cancel(pthread!)
        #elseif os(Linux)
            pthread_cancel(pthread)
        #endif
        status = .inactive
    }
    
}

/// Main routine of starting thread.
fileprivate func runThread(argument: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
    return runThread(arg: argument)
}

fileprivate func runThread(arg: UnsafeMutableRawPointer?) -> UnsafeMutableRawPointer? {
    /// Get an instance of the PSXThread class, to run the execution loop in a created thread.
    if let thread = arg?.assumingMemoryBound(to: PSXThread.self).pointee {
        /// Set thread name for profiling and debugging
        if let nameChars = thread.name.cString(using: .utf8) {
            #if os(OSX) || os(iOS)
                pthread_setname_np(nameChars)
            #elseif os(Linux)
                linux_pthread_setname_np(thread.pthread, nameChars)
            #endif
        }
        /// Starts an infinite loop in which the job directed to the thread are executed.
        thread.run()
    }
    return nil
}
