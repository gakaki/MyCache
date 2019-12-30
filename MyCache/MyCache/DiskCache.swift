//
//  Memory.swift
//  CloneWeChat
//
//  Created by g on 2019/12/29.
//  Copyright © 2019 g. All rights reserved.
//

import Foundation
import UIKit

class DiskObj: LRUObject{
    var size: UInt  = 0
    var key: String = ""
    var time: TimeInterval = CACurrentMediaTime()
    var date: Date
    var path: String = ""
    
    init( key: String, size: UInt , date:Date){
     self.key = key
     self.date = date
     self.size = size
    }
    
}
class DiskCache: Cache {
    
    let _cache: LRU = LRU<DiskObj>()
    let dirURL:URL  = URL(fileURLWithPath: NSHomeDirectory() + "/Library/Caches/ImageCache")
    let path        = NSSearchPathForDirectoriesInDomains(.cachesDirectory, .userDomainMask, true)[0]
    var totalSize: UInt {
        get {
            lock()
            let size = _cache.size
            unlock()
            return size
        }
    }
    
    var _limitCount:UInt =  20
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
    
    var _limitSize:UInt =  10 * 1024
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
        if let _: DiskObj = _cache.last() {
            while ( _cache.count > limitCount ) {
                _cache.removeLast()
                if _cache.last() == nil { break }
            }
        }
    }
    
    func urlToCustomKey(_ url: String) -> String {
        var newKey = ""
        for char in url {
            if let asc = char.asciiValue {
                if (asc >= 48 && asc <= 57)||(asc >= 65 && asc <= 9 )||( asc >= 97 && asc <= 122 ){
                    newKey.append(char)
                }
            }
        }
        return newKey
    }
    
    //获取沙箱缓存文件路径
    func getFileUrl(_ url: String ) -> URL {
        let pathBase = NSHomeDirectory() + "/Library/Caches/ImageCache"
        let diskPath = pathBase + "/" + urlToCustomKey(url)
        let pathURL  = URL.init(fileURLWithPath: diskPath)
        return pathURL
    }

    func set( k: String, v: Data ){
        
        let filePath = getFileUrl(k)
        lock()
              
        do {
            try v.write(to: filePath, options: Data.WritingOptions.atomic)
            print("缓存数据写入了磁盘v2", filePath.absoluteString)
            
            //获得文件size 和 修改时间
            let date: Date = Date()
            try FileManager.default.setAttributes([FileAttributeKey.modificationDate : date], ofItemAtPath: filePath.path)
            let info: [URLResourceKey : AnyObject] = try (filePath as NSURL).resourceValues(forKeys: [URLResourceKey.totalFileAllocatedSizeKey]) as [URLResourceKey : AnyObject]
            var fileSize: UInt = 0
            if let fileSizeNumber = info[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                fileSize = fileSizeNumber.uintValue
            }
            _cache.set( k: k, v: DiskObj(key: k, size: fileSize, date: date))
        } catch let error {
               print("缓存数据写入出错 \(error.localizedDescription)")
        }
    
        if _cache.size > _limitSize {
            trim()
        }
        
        unlock()
    }
    
    func trim() {
        if self.totalSize <= _limitSize {
            return
        }
        if _limitSize == 0 {
            trimLast()
            return
        }
        lock()
        trimLast()
        unlock()
    }
    
    func trimLast() {
        if var lastObject: DiskObj = _cache.last() {
            while (_cache.size > _limitSize ) {
                let fileURL = getFileUrl(lastObject.key)
                do {
                    try FileManager.default.removeItem(atPath: fileURL.path)
                    _cache.removeLast()
                    guard let newLastObject = _cache.last() else { break }
                    lastObject = newLastObject
                } catch {}
            }
        }
    }
  
    
    
    
    func get( k:String) -> Data? {
        lock()
        let diskObj = _cache._get(k: k)
        unlock()
        
        var data:Data?
        if let url = diskObj?.key {
            let diskUrl = getFileUrl(url)
            
            do {
                data = try Data(contentsOf: diskUrl , options: Data.ReadingOptions.alwaysMapped)
            }
            catch {
                data = nil
            }
        }
        return data
    }
       
     
    func remove(key:String) {
        lock()
        let _ = _cache.remove(k: key)
        let diskUrl = getFileUrl( key)
        if FileManager.default.fileExists(atPath: diskUrl.path) {
        do {
          try FileManager.default.removeItem(atPath: diskUrl.path)
          _ =  _cache.remove(k: key)
        } catch {}
        }
        unlock()
   }
       

   func removeAll() {
        lock()
        _cache.removeAll()
        if FileManager.default.fileExists(atPath: self.dirURL.path) {
            do {
                try FileManager.default.removeItem(atPath: self.dirURL.path)
                _cache.removeAll()
            } catch {}
        }
        unlock()
   }
       
    public override init() {
        super.init()

        self.lock()
        let _ = self.createDir()
        let _ = self.loadFilesInfo()
        self.unlock()
    }
    
    func createDir() -> Bool {
        if FileManager.default.fileExists(atPath: dirURL.path) {
            return false
        }
        do {
            try FileManager.default.createDirectory(atPath: dirURL.path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return false
        }
        return true
    }
    
    func loadFilesInfo() -> Bool {
        var fileInfos: [DiskObj] = [DiskObj]()
        let fileInfoKeys: [URLResourceKey] = [URLResourceKey.contentModificationDateKey, URLResourceKey.totalFileAllocatedSizeKey]
        do {
            let filesURL: [URL] = try FileManager.default.contentsOfDirectory(at: dirURL, includingPropertiesForKeys: fileInfoKeys, options: .skipsHiddenFiles)
            for fileURL: URL in filesURL {
                do {
                    let info: [URLResourceKey : AnyObject] = try (fileURL as NSURL).resourceValues(forKeys: fileInfoKeys) as [URLResourceKey : AnyObject]
                    
                    if let k = fileURL.lastPathComponent as String?,
                        let date = info[URLResourceKey.contentModificationDateKey] as? Date,
                        let size = info[URLResourceKey.totalFileAllocatedSizeKey] as? NSNumber {
                        fileInfos.append(DiskObj(key: k , size: size.uintValue, date: date))
                    }
                }
                catch {
                    return false
                }
            }
            fileInfos.sort { $0.date.timeIntervalSince1970 < $1.date.timeIntervalSince1970 }
            fileInfos.forEach {
                _cache.set( k: $0.key , v: $0 )
            }
        } catch {
            return false
        }
        return true
    }
       
}


