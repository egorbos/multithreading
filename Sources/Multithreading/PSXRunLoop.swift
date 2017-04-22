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

internal class PSXRunLoop {
    
    /// A thread to run jobs from the it private queue.
    fileprivate let thread: PSXThread

    /// Status of the run loop.
    fileprivate(set) var active = false
    
    /// Initialization
    ///
    /// Parameter thread: A thread to run jobs from the private queue in it.
    ///
    internal init(for thread: PSXThread) {
        self.thread = thread
    }
    
    /// Begins the process of waiting for new jobs to a private queue and have them executed.
    ///
    internal func start() {
        active = true
        thread.status = .waiting
        
        while active == true {
            thread.privateQueue.hasJobs.wait()
            
            if let job = thread.privateQueue.pull() {
                thread.status = .working
                job.block()
                thread.status = .waiting
                
                if thread is PSXWorkerThread {
                    let workerThread = thread as! PSXWorkerThread
                    let pool = workerThread.pool
                    let working = pool.workingThreads
                    if pool.waiting == true && working.count == 0 {
                        pool.jobsHasFinished.signal()
                    }
                }
            }
        }
    }

    /// Stops run jobs process
    ///
    internal func stop() {
        active = false
    }

}
