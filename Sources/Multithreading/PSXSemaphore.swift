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

public enum PSXSemaphoreValue: UInt8 {
    case zero = 0
    case one  = 1
}

public class PSXSemaphore {

    /// Mutex for avoid the race condition.
    fileprivate let mutex = PSXMutex()
    
    /// Condition variable for notify threads.
    fileprivate let condition = PSXCondition()
    
    /// The value of the semaphore.
    fileprivate(set) var value: PSXSemaphoreValue
    
    /// Initialization.
    ///
    /// - Parameter value: An initial value to set the semaphore to.
    ///
    public init(value: PSXSemaphoreValue) {
        self.value = value
    }
    
}

extension PSXSemaphore {
    
    /// Waits on semaphore until semaphore has value 0.
    ///
    public func wait() {
        mutex.lock()
        while value != .one { condition.wait(mutex: mutex) }
        value = .zero
        mutex.unlock()
    }
    
    /// Increments the value of the semaphore and wakes up
    /// at least one blocked thread waiting on the semaphore, if any.
    ///
    public func post() {
        mutex.lock()
        value = .one
        condition.signal()
        mutex.unlock()
    }
    
    /// Increments the value of the semaphore and wakes up
    /// all blocked threads waiting on the semaphore, if any.
    ///
    public func postAll() {
        mutex.lock()
        value = .one
        condition.broadcast()
        mutex.unlock()
    }
    
    /// Resets semaphore to 0.
    ///
    public func reset() {
        value = .zero
    }

}
