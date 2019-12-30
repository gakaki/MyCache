//
//  Cache.swift
//  CloneWeChat
//
//  Created by g on 2019/12/30.
//  Copyright © 2019 g. All rights reserved.
//

import Foundation

class CacheManager {
    
    public let memCache: MemCache
    public let diskCache: DiskCache
    public static let `default` = CacheManager()
    
    public init?() {
        self.diskCache = DiskCache()
        self.memCache = MemCache()
    }

    func set(k:String , v:Data) {
       memCache.set(k: k, v: v )
//       diskCache.set(k: k, v: v)
    }
    func get(k:String) -> Data? {
        if let v = memCache.get(k: k) {
            return v
        }else{
            if let v = diskCache.get(k: k){
                memCache.set(k: k, v: v)
                return v
            }
        }
        return nil
    }
    
    func remove( k: String ) {
        memCache.remove(key: k)
        diskCache.remove(key:k)
    }
    
    func removeAll() {
        memCache.removeAll()
        diskCache.removeAll()
    }
}
