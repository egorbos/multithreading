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
    
    /// Starts the job assigning process.
    ///
    /// Note: Main routine of the assigning thread.
    ///
    fileprivate func startAssigningJobs() {
        while pool.aliveThreads.count > 0 {
            pool.globalQueue.hasJobs.wait()
            
            if let job = pool.globalQueue.pull() {
                let waiting = pool.waitingThreads
                let working = pool.workingThreads
                
                if waiting.count > 0 {
                    let upper = waiting.count
                    #if os(macOS) || os(iOS)
                        let idx = Int(arc4random_uniform(UInt32(upper)))
                    #elseif os(Linux) || CYGWIN
                        let idx = Int(random() % upper)
                    #endif
                    waiting[idx].addJob(job)
                } else {
                    let min = working.withMinJobs()
                    min.addJob(job)
                }
            }
        }
    }
    
    /// Terminates the assigning thread.
    ///
    internal func destroy() {
        assigningThread.exit()
    }
    
}
