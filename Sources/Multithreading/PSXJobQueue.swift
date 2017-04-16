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

internal class PSXJobQueue {
    
    /// Jobs queue.
    fileprivate var jobs: [PSXJob] = []
    
    /// Mutex for queue r/w access.
    fileprivate var rwmutex = PSXMutex()
    
    /// Flag as binary semaphore.
    fileprivate(set) var hasJobs = PSXSemaphore(value: .zero)
    
    /// Returns count of jobs in queue.
    internal var jobsCount: Int {
        rwmutex.lock()
        let jbscount = jobs.count
        rwmutex.unlock()
        return jbscount
    }
    
    /// Returns first job from queue, if exist.
    ///
    internal func pull() -> PSXJob? {
        rwmutex.lock()
        var job: PSXJob?
        if jobs.count > 0 {
            job = jobs.remove(at: 0)
            if jobs.count > 0 {
                hasJobs.post()
            }
        }
        rwmutex.unlock()
        
        return job
    }
    
    /// Adds job to queue.
    ///
    /// - Parameter newJob: The job to be performed.
    ///
    internal func put(newJob: PSXJob) {
        rwmutex.lock()
        jobs.append(newJob)
        hasJobs.post()
        rwmutex.unlock()
    }
    
    /// Clears the queue.
    ///
    internal func clear() {
        rwmutex.lock()
        jobs.removeAll()
        hasJobs.reset()
        rwmutex.unlock()
    }
    
}
