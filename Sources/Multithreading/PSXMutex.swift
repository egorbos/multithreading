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

public class PSXMutex {
    
    /// POSIX mutex.
    internal var mutex = pthread_mutex_t()
    
    /// Initialization.
    ///
    public init() {
        pthread_mutex_init(&mutex, nil)
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    /// Locks the mutex object. If the mutex is already locked, the calling thread shall block
    /// until the mutex becomes available. This operation shall return with the mutex
    /// object referenced by mutex in the locked state with the calling thread as its owner.
    ///
    public func lock() {
        pthread_mutex_lock(&mutex)
    }
    
    /// Releases the mutex object. If there are threads blocked on the mutex object,
    /// resulting in the mutex becoming available, the scheduling policy shall determine
    /// which thread shall acquire the mutex.
    ///
    public func unlock() {
        pthread_mutex_unlock(&mutex)
    }

}
