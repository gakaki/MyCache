//
//  GenericCache.swift
//  CloneWeChat
//
//  Created by g on 2019/12/29.
//  Copyright © 2019 g. All rights reserved.
//

import Foundation

protocol ProtocolGenericCache {

    func lock()
    func unlock()
    
}

public class Cache: ProtocolGenericCache {
    
    let _semaphoreLock: DispatchSemaphore = DispatchSemaphore(value: 1)

    func lock() {
        _ = _semaphoreLock.wait(timeout: DispatchTime.distantFuture)
    }
    func unlock() {
        _ = _semaphoreLock.signal()
    }

    
}


