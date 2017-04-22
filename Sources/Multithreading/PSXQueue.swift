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

public enum PSXQueueType {
    case concurrent
    case serial
}

public class PSXQueue {
    
    /// A thread pool in which jobs are performed.
    fileprivate let pool: PSXThreadPool
    
    /// Initialization.
    ///
    /// - Parameters:
    ///   - name: The name of the queue.
    ///   - type: The type of the queue (concurrent or serial).
    ///
    /// - Note: Serial queues guarantee that only one job runs at any given time.
    ///         Concurrent queues allow multiple jobs to run at the same time.
    ///
    public init(name: String, type: PSXQueueType) {
        if type == .concurrent {
            pool = PSXThreadPool(count: 4)
        } else {
            pool = PSXThreadPool(count: 1)
        }
        pool.threadsNamePrefix = name
    }
    
    /// Performs the block of code.
    ///
    /// - Parameter block: A block of code that will be performed.
    ///
    public func perform(_ block: @escaping () -> Void) {
        pool.addJob(block)
    }
 
    deinit { pool.destroy() }

}
