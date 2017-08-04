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

public class PSXWorkerThread: PSXThread {
    
    // MARK: Properties, initialization, deinitialization
    
    /// Thread pool.
    internal let pool: PSXThreadPool
    
    /// Friendly id
    public let id: Int
    
    // TODO: - NEW
    internal var lastActivity: Date
    
    /// Initialization.
    ///
    /// - Parameters:
    ///   - pool: A thread pool.
    ///   - id:   A friendly id of created thread.
    ///   
    internal init(pool: PSXThreadPool, id: Int) {
        self.id = id
        self.pool = pool
        self.lastActivity = Date()
        super.init()
    }
    
}

internal extension Array where Element: PSXWorkerThread {
    internal func withMinJobs() -> Element {
        let min = self.min { $0.privateQueue.jobsCount < $1.privateQueue.jobsCount }
        return min!
    }
    
    internal func lastActive() -> Element {
        let max = self.max { $0.lastActivity.timeIntervalSinceNow < $1.lastActivity.timeIntervalSinceNow }
        return max!
    }
}
