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
#endif

import Foundation

internal class PSXScheduler {
    
    /// A thread pool for assigning jobs in it.
    fileprivate let pool: PSXThreadPool
    
    /// The thread for assigning jobs from global queue of thread pool to worker threads.
    fileprivate let assigningThread = PSXThread()
    
    /// Initialization.
    ///
    /// - Parameter pool: A thread pool for assigning jobs in it.
    ///
    internal init(forPool pool: PSXThreadPool) {
        self.pool = pool
        assigningThread.doJob { self.startAssigningJobs() }
        assigningThread.name = "com.swixbase.multithreading.psxscheduler"
        assigningThread.start()
    }
    
    deinit { destroy() }
    
}

extension PSXScheduler {

    /// Starts the job assigning process.
    ///
    /// Note: Main routine of the assigning thread.
    ///
    fileprivate func startAssigningJobs() {
        while true {
            pool.globalQueue.hasJobs.wait()
            
            if let job = pool.globalQueue.pull() {
                let alive = pool.aliveThreads
                let waiting = pool.waitingThreads
                let working = pool.workingThreads
                let paused = pool.pausedThreads
                
                let rnd: (Int) -> Int = { upper in
                    #if os(macOS) || os(iOS)
                        return Int(arc4random_uniform(UInt32(upper)))
                    #elseif os(Linux)
                        return Int(random() % upper)
                    #endif
                }
                
                let addToWaiting: (PSXJob) -> Void = { newJob in
                    let thread = waiting.lastActive()
                    thread.addJob(newJob)
                    thread.lastActivity = Date()
                }
                
                let addToPaused: (PSXJob) -> Void = { newJob in
                    let upper = paused.count
                    let idx = rnd(upper)
                    paused[idx].addJob(job)
                    paused[idx].resume()
                    paused[idx].lastActivity = Date()
                }
                
                
                if waiting.count > 0 {
                    addToWaiting(job)
                } else {
                    let min = working.withMinJobs()
                    guard min.privateQueue.jobsCount < pool.maxPrivateJobsCount else {
                        if paused.count > 0 {
                            addToPaused(job)
                        } else if alive.count < pool.maxThreadsCount {
                            let thread = pool.newThread()
                            thread.addJob(job)
                        } else {
                            while waiting.count < 0 {
                                addToWaiting(job)
                            }
                        }
                        return
                    }
                    min.addJob(job)
                    min.lastActivity = Date()
                }
            }
        }
    }
    
    
    /// Terminates the assigning thread.
    ///
    internal func destroy() {
        assigningThread.cancel()
    }
    
}
