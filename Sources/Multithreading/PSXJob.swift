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

public enum PSXJobPriority: UInt8 {
    case normal = 0
    case high   = 1
}

internal class PSXJob {
    
    /// A block of code to be performed.
    fileprivate let block: () -> Void
    
    /// Initialization.
    ///
    /// - Parameter block: A block of code that will be performed.
    ///
    internal init(block: @escaping () -> Void) {
        self.block = { _ in block() }
    }
    
}

extension PSXJob {

    /// Performs a block of code.
    ///
    internal func make() {
        block()
    }
    
}
