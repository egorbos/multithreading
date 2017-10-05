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

import XCTest
import Foundation

#if os(macOS) || os(iOS)
    import Darwin
#elseif os(Linux)
    import Glibc
    import LXPThread
#endif

@testable import Multithreading

class MultithreadingTests: XCTestCase {

    static var allTests : [(String, (MultithreadingTests) -> () throws -> Void)] {
        return [
            ("testStartThread", testStartThread),
            ("testThreadDoJob", testThreadDoJob),
            ("testThreadPoolAddJob", testThreadPoolAddJob),
            ("testThreadPoolWait", testThreadPoolWait),
            ("testThreadPoolNewThread", testThreadPoolNewThread),
            ("testThreadPoolNewThreadForKey", testThreadPoolNewThreadForKey),
            ("testThreadPoolDestroyThreadForKey", testThreadPoolDestroyThreadForKey),
            ("testThreadPoolSingletoneInstance", testThreadPoolSingletoneInstance),
            ("testQueuePerformCode", testQueuePerformCode),
            ("testSetThreadName", testSetThreadName),
            ("testPauseResumeThread", testPauseResumeThread)
        ]
    }
    
    // MARK: - Helpers
    
    internal func getThreadName() -> String {
        var buffer = [Int8](repeating: 0, count: 16)
        #if os(OSX) || os(iOS)
            pthread_getname_np(pthread_self(), &buffer, buffer.count)
        #elseif os(Linux)
            linux_pthread_getname_np(pthread_self(), &buffer, buffer.count)
        #endif
        return String(cString: &buffer)
    }
    
    // MARK: - Tests
    
    func testStartThread() {
        var started = false
        let condition = PSXCondition()
        let mutex = PSXMutex()
        
        let thread = PSXThread {
            mutex.lock()
            started = true
            condition.signal()
            mutex.unlock()
        }
        thread.start()
        
        mutex.lock()
        if !started {
            condition.wait(mutex: mutex)
        }
        mutex.unlock()
        XCTAssertTrue(started)
    }
    
    func testThreadDoJob() {
        var started = false
        let condition = PSXCondition()
        let mutex = PSXMutex()
        
        let thread = PSXThread()
        thread.start()
        thread.doJob {
            mutex.lock()
            started = true
            condition.signal()
            mutex.unlock()
        }
        
        mutex.lock()
        if !started {
            condition.wait(mutex: mutex)
        }
        mutex.unlock()
        XCTAssertTrue(started)
    }
    
    func testThreadPoolAddJob() {
        var started = false
        let condition = PSXCondition()
        let mutex = PSXMutex()
        
        let pool = PSXThreadPool(count: 2)
        pool.addJob {
            mutex.lock()
            started = true
            XCTAssertEqual(pool.aliveThreads.count, 2)
            XCTAssertEqual(pool.workingThreads.count, 1)
            XCTAssertEqual(pool.waitingThreads.count, 1)
            condition.signal()
            mutex.unlock()
        }
        
        mutex.lock()
        if !started {
            condition.wait(mutex: mutex)
        }
        mutex.unlock()
        XCTAssertTrue(started)
        XCTAssertEqual(pool.aliveThreads.count, 2)
        XCTAssertEqual(pool.workingThreads.count, 0)
        XCTAssertEqual(pool.waitingThreads.count, 2)
    }
    
    func testThreadPoolWait() {
        var started = false
        
        let pool = PSXThreadPool(count: 2)
        pool.addJob {
            started = true
        }
        
        pool.wait()
        XCTAssertTrue(started)
    }
    
    func testThreadPoolNewThread() {
        var started = false
        let condition = PSXCondition()
        let mutex = PSXMutex()
        
        let pool = PSXThreadPool(count: 1)
        XCTAssertEqual(pool.aliveThreads.count, 1)
        XCTAssertEqual(pool.workingThreads.count, 0)
        XCTAssertEqual(pool.waitingThreads.count, 1)
        
        let thread = pool.newThread()
        thread.doJob {
            mutex.lock()
            started = true
            XCTAssertEqual(pool.aliveThreads.count, 2)
            XCTAssertEqual(pool.workingThreads.count, 1)
            XCTAssertEqual(pool.waitingThreads.count, 1)
            condition.signal()
            mutex.unlock()
        }

        mutex.lock()
        if !started {
            condition.wait(mutex: mutex)
        }
        mutex.unlock()
        XCTAssertTrue(started)
        XCTAssertEqual(pool.aliveThreads.count, 2)
        XCTAssertEqual(pool.workingThreads.count, 0)
        XCTAssertEqual(pool.waitingThreads.count, 2)
    }
    
    func testThreadPoolNewThreadForKey() {
        var started = false
        let condition = PSXCondition()
        let mutex = PSXMutex()
        
        let pool = PSXThreadPool(count: 1)
        pool.newThread(forKey: "👻")
        if let thread = pool.getThread(forKey: "👻") {
            thread.doJob {
                mutex.lock()
                started = true
                condition.signal()
                mutex.unlock()
            }
        }
        
        mutex.lock()
        if !started {
            condition.wait(mutex: mutex)
        }
        mutex.unlock()
        XCTAssertTrue(started)
    }
    
    func testThreadPoolDestroyThreadForKey() {
        let pool = PSXThreadPool(count: 1)
        pool.newThread(forKey: "TEST")
        XCTAssertNotNil(pool.getThread(forKey: "TEST"))
        pool.destroyThread(forKey: "TEST")
        XCTAssertNil(pool.getThread(forKey: "TEST"))
    }
    
    func testThreadPoolSingletoneInstance() {
        var started = false

        let pool = PSXThreadPool.default
        pool.addJob {
            started = true
        }
        
        pool.wait()
        XCTAssertTrue(started)
    }
    
    func testQueuePerformCode() {
        var started = false
        let condition = PSXCondition()
        let mutex = PSXMutex()
        
        let queue = PSXQueue(name: "test", type: .serial)
        queue.perform {
            mutex.lock()
            started = true
            condition.signal()
            mutex.unlock()
        }
        
        mutex.lock()
        if !started {
            condition.wait(mutex: mutex)
        }
        mutex.unlock()
        XCTAssertTrue(started)
    }
    
    func testSetThreadName() {
        let condition = PSXCondition()
        let mutex = PSXMutex()
        
        let thread = PSXThread()
        XCTAssertNotEqual(thread.name, "abcdefghgfedcba")
        thread.name = "abcdefghgfedcba"
        XCTAssertEqual(thread.name, "abcdefghgfedcba")
        thread.doJob {
            XCTAssertEqual(self.getThreadName(), "abcdefghgfedcba")
            condition.signal()
        }
        thread.start()
        
        mutex.lock()
        condition.wait(mutex: mutex)
        mutex.unlock()
    }
    
    func testPauseResumeThread() {
        var resumed = false
        let condition = PSXCondition()
        let mutex = PSXMutex()
        
        let thread = PSXThread()
        thread.start()
        
        while thread.status != .waiting {}
        
        thread.pause()
        
        while thread.status != .paused {}
        
        thread.doJob {
            mutex.lock()
            resumed = true
            condition.signal()
            mutex.unlock()
        }

        thread.resume()
        
        mutex.lock()
        if !resumed {
            condition.wait(mutex: mutex)
        }
        mutex.unlock()
        XCTAssertTrue(resumed)
    }

}
