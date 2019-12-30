//
//  Memory.swift
//  CloneWeChat
//
//  Created by g on 2019/12/29.
//  Copyright © 2019 g. All rights reserved.
//

import Foundation
import UIKit

class MemObj: LRUObject{
    var size: UInt  = 1
    var key: String = ""
    var time: TimeInterval = CACurrentMediaTime()
    var value: Data

    init( key: String, v: Data , size:UInt = 0){
     self.key = key
     self.value = v
     self.size = 1
    }
    
}
class MemCache: Cache {
    
    let _cache: LRU = LRU<MemObj>()

    var totalCount: UInt {
        get {
            lock()
            let count = _cache.count
            unlock()
            return count
        }
    }
    var totalSize: UInt {
        get {
            lock()
            let size = _cache.size
            unlock()
            return size
        }
    }
    
    // 内存限制其实无限吧
    var _limitCount:UInt =  1
    var limitCount: UInt {
        set {
            lock()
            _limitCount = newValue
            cleanData()
            unlock()
        }
        get {
            return _limitCount
        }
    }
    var _limitSize :UInt =  1
    var limitSize: UInt {
        set {
            lock()
            _limitSize = newValue
            cleanData()
            unlock()
        }
        get {
            return _limitSize
        }
    }
    
    func cleanData(){
        if _cache.count < limitCount { return }
        
        if limitCount == 0 {
            _cache.removeAll()
            return
        }
        if let _: MemObj = _cache.last() {
            while ( _cache.count > limitCount ) {
                _cache.removeLast()
                if _cache.last() == nil { break }
            }
        }
    }
    
    
    func set( k:String , v: Data ) {
        lock()
        _cache.set( k: k, v: MemObj(key: k, v: v))
        unlock()
        if _cache.count > limitCount {
            cleanData()
        }
    }
    
    func get( k:String) -> Data? {
        lock()
        let memObj = _cache._get(k: k)
        memObj?.time = CACurrentMediaTime()
        let data = memObj?.value
        unlock()
        print(_cache.count,_cache.size,limitCount)
        
        if _cache.count > limitCount {
             cleanData()
        }
        return data
    }
       
     
    func remove(key:String) {
       lock()
       let _ = _cache.remove(k: key)
       unlock()
   }
       

   func removeAll() {
        lock()
        _cache.removeAll()
        unlock()
   }
       
     
       
}


