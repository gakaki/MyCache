//
//  LRU.swift
//  CloneWeChat
//
//  Created by g on 2019/12/26.
//  Copyright © 2019 g. All rights reserved.
//

import Foundation


class LRU<T : LRUObject> {
    
    private(set) var size: UInt = 0
    
    var _dic:Dictionary<String, Node<T>> = Dictionary<String, Node<T>>()
    
    let _doubleLinkedList: DoubleLinkedList = DoubleLinkedList<T>()
    
    var count: UInt {
        return _doubleLinkedList.size
    }
    
    func set( k: String , v: T ) {
        
        if let node: Node<T> = _dic[k] {
            size -= node.data?.size ?? 0
            size += v.size
            node.data = v
            _doubleLinkedList.move_to_head( node )
        }else{
            let node = Node(v)
            size += v.size
            _dic[k] = node
            _doubleLinkedList.add(node)
        }
    }
    func _get( k: String  ) -> T? {
      if let node: Node<T> = _dic[k] {
          _doubleLinkedList.move_to_head( node )
        return node.data
      }
      return nil
    }
     
    func remove( k: String ) -> T? {
        
        if let node: Node<T> = _dic[k] {
            _dic.removeValue(forKey: k)
            _doubleLinkedList.remove(node)
            size -= node.data?.size ?? 0
            return node.data
        }
        return nil
    }

    func removeAll() {
        _dic.removeAll()
        _doubleLinkedList.removeAll()
        size = 0
    }
    
    func removeLast() {
        if let last_node: Node<T> = _doubleLinkedList.tail.prev {
            if let key = last_node.data?.key {
                _dic.removeValue(forKey: key)
                _doubleLinkedList.remove(last_node)
                size -= last_node.data?.size ?? 0
                return
            }
        }
    }
    
    func last() -> T? {
        return _doubleLinkedList.tail.prev?.data
    }
    
    subscript(key: String) -> T? {
        get {
            return _get(k:key)
        }
        set {
            if let newValue = newValue{
                set(k: key, v: newValue)
            } else {
                _ = remove(k: key)
            }
        }
    }
    
}


protocol  LRUObject {
    var key: String { get }
    var size: UInt { get set }
}

class Node<T> {
    
    weak var prev: Node<T>?
    weak var next: Node<T>?
    
    var isFake  = false
    
    var data:T?
    
    init(_ data: T){
        self.data = data
    }
    init( isFake:Bool = true ){
        self.isFake = true
    }
}

class DoubleLinkedList<T>{

    private(set) var size:UInt = 0

    // 虚节点2个 TODO weak refrence
    var head : Node<T>
    var tail : Node<T>

    init(){

        head =  Node(isFake: true)
        tail =  Node(isFake: true)
        
        head.next = tail
        tail.prev = head
    }
    
    func add(_ node: Node<T>){
        node.prev = head
        node.next = head.next
        
        head.next?.prev = node
        head.next = node
    }
    
    func remove(_ node: Node<T>){
        let prev = node.prev
        let next = node.next
        prev?.next = next
        next?.prev = prev
    }
    
    func move_to_head(_ node: Node<T>){
        remove(node)
        add(node)
    }
    
    func pop_tail(_ node: Node<T>) -> Node<T>{
        if let node = tail.prev {
            remove(node)
        }
        return node
    }
    
    func removeAll(){
        size = 0 //TODO
    }
    


}
