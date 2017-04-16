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
#elseif os(Linux) || CYGWIN
    import Glibc
#endif

import Foundation

public enum PSXThreadStatus: UInt8 {
    case inactive = 0
    case waiting  = 1
    case working  = 2
}

public class PSXThread {
    
    // MARK: Properties, initialization, deinitialization
    
    /// Friendly id
    public var id: Int?
    
    /// Thread name for profiling and debuging
    public var name = "psxthread"
    
    /// Status of the thread.
    internal(set) var status: PSXThreadStatus = .inactive

    /// POSIX pointer to thread
    internal var pthread: pthread_t?
    
    /// The queue from which the jobs are executed sequentially.
    internal var privateQueue = PSXJobQueue()
    
    /// Thread pool.
    internal var pool: PSXThreadPool?
    
    /// The infinite loop in which the job directed to the thread are executed.
    internal var runLoop: PSXRunLoop?
    
    /// Attributes with which the thread will be created.
    fileprivate var attributes = pthread_attr_t()
    
    /// Link to the self, that will be sended to the main routine to run in it run loop of the thread.
    fileprivate var current: PSXThread?

    /// Initialization.
    ///
    public init() {
        withUnsafeMutablePointer(to: &attributes) { attrib in
            pthread_attr_init(attrib)
            pthread_attr_setscope(attrib, PTHREAD_SCOPE_SYSTEM)
            pthread_attr_setdetachstate(attrib, PTHREAD_CREATE_DETACHED)
        }
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
    
    deinit {
        exit()
    }
    
    // MARK: Methods
    
    /// Creates a new thread.
    ///
    public func start() {
        pthread_create(&pthread, &attributes, runThread, &current)
    }
    
    /// Starts an infinite loop in which the job directed to the thread are executed.
    ///
    internal func run() {
        if let runLoop = runLoop {
            runLoop.start()
        }
    }

    /// Puts a block of code in a private queue.
    ///
    /// - Parameter block: A block of code that will be executed in the thread.
    ///
    public func doJob(_ block: @escaping () -> Void) {
        let job = PSXJob(block: block)
        privateQueue.put(newJob: job)
    }
    
    /// Puts a function in a private queue.
    ///
    /// - Parameters:
    ///   - function: Function that will be performed.
    ///   - argument: Function's argument.
    ///
    public func addJob(function: @escaping (UnsafeMutableRawPointer?) -> Void, argument: UnsafeMutableRawPointer?) {
        let job = PSXJob(function: function, arg: argument)
        privateQueue.put(newJob: job)
    }
    
    /// Puts a block of code in a private queue.
    ///
    /// - Parameter job: A job that will be executed in the thread.
    ///
    internal func addJob(_ job: PSXJob) {
        privateQueue.put(newJob: job)
    }
    
    /// Terminates the thread.
    ///
    public func exit() {
        doJob {
            if let runLoop = self.runLoop {
                runLoop.stop()
            }
            pthread_exit(nil)
        }
        status = .inactive
    }
    
    func pause() {
        /// Unimplemented
    }
    
    func resume() {
        /// Unimplemented
    }
    
}

/// Main routine of starting thread.
fileprivate func runThread(arg: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer? {
    
    /// Get an instance of the PSXThread class, to run the execution loop in a created thread.
    let thread = arg.assumingMemoryBound(to: PSXThread.self).pointee
    
    /// Set thread name for profiling and debuging 
    if let nameData = thread.name.cString(using: .utf8) {
        #if os(macOS) || os(iOS)
            pthread_setname_np(nameData)
        #elseif os(Linux) || CYGWIN
            prctl(PR_SET_NAME, nameData)
        #endif
    }

    /// Run the execution loop.
    thread.run()
    
    return nil
}
