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

public class PSXCondition {
    
    /// POSIX condition variable.
    internal var condition = pthread_cond_t()
    
    /// Initialization.
    ///
    public init() {
        pthread_cond_init(&condition, nil)
    }
    
    deinit {
        pthread_cond_destroy(&condition)
    }
    
}

extension PSXCondition {

    /// Blocks on a condition variable. It must be called with mutex locked by the calling thread,
    /// or undefined behavior will result.
    ///
    /// - Parameter mutex: The associated mutex with specified condition variable.
    ///
    /// - Note: A condition variable must always be associated with a mutex, to avoid the race condition
    ///         where a thread prepares to wait on a condition variable and another thread signals the condition
    ///         just before the first thread actually waits on it.
    ///
    public func wait(mutex: PSXMutex) {
        pthread_cond_wait(&condition, &mutex.mutex)
    }
    
    /// Unblocks at least one of the threads that are blocked on the specified condition variable.
    ///
    public func signal() {
        pthread_cond_signal(&condition)
    }

    /// Unblocks all threads currently blocked on the specified condition variable.
    ///
    public func broadcast() {
        pthread_cond_broadcast(&condition)
    }

}
