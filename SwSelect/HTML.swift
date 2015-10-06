//
//  HTML.swift
//  SwSelect
//
//  Created by Julian Shen on 2015/10/5.
//  Copyright © 2015年 cowbay.wtf. All rights reserved.
//

import Foundation
import libxml2

public enum SwHTMLNodeType {
    case ErrorNode
    case TextNode
    case DocumentNode
    case ElementNode
    case CommentNode
    case DoctypeNode
}

public typealias SwHTMLAttribute = (name:String, val:String)


public struct SwHTMLNode:CustomStringConvertible {
    let _node: xmlNodePtr
    
    public var tag:String? {
        let _tag = String.fromCString(UnsafePointer<CChar>(_node.memory.name))
        return _tag
    }
    
    public var data:String {
        if _node.memory.type == XML_ELEMENT_NODE {
            return tag!
        }
        
        let _data = String.fromCString(UnsafePointer<CChar>(_node.memory.content)) ?? ""
        return _data
    }
    
    public var text:String {
        var result:String = ""
        for c in children {
            switch c.type {
                case .TextNode:
                    result += c.data
                case .ElementNode:
                    result += c.text
                default:
                    break
            }
        }
        return result
    }
    
    public var type:SwHTMLNodeType {
        switch(_node.memory.type.rawValue) {
        case XML_ELEMENT_NODE.rawValue:
            return .ElementNode
        case XML_TEXT_NODE.rawValue:
            return .TextNode
        case XML_COMMENT_NODE.rawValue:
            return .CommentNode
        case XML_DOCUMENT_NODE.rawValue:
            return .DocumentNode
        case XML_DOCUMENT_TYPE_NODE.rawValue:
            return .DoctypeNode
        default:
            return .ErrorNode
        }
    }
    
    public var ns:String? {
        let _ns = String.fromCString(UnsafePointer<CChar>(_node.memory.ns))
        return _ns
    }
    
    public var attributes:AnySequence<SwHTMLAttribute> {
        let properties = _node.memory.properties
        if(properties != nil) {
            return AnySequence<SwHTMLAttribute> {
                _ -> AnyGenerator<SwHTMLAttribute> in
                var cursor = properties
                return anyGenerator {
                    if cursor == nil {
                        return nil
                    }
                    
                    let current = cursor //Assign current
                    cursor = cursor.memory.next //Move cursor to next
                    let name = String.fromCString(UnsafePointer<CChar>(current.memory.name)) ?? ""
                    let v = xmlGetProp(self._node, current.memory.name)
                    let val = String.fromCString(UnsafePointer<CChar>(v)) ?? ""
                    
                    if v != nil {
                        xmlFree(v)
                    }
                    
                    return SwHTMLAttribute(name, val)
                }
            }
        } else {
            return AnySequence<SwHTMLAttribute> {
                _ -> EmptyGenerator<SwHTMLAttribute> in
                return EmptyGenerator<SwHTMLAttribute>()
            }
        }
    }
    
    public func attr(name: String) -> String? {
        let v = xmlGetProp(self._node, name)
        
        defer {
            if v != nil {
                xmlFree(v)
            }
        }
        
        if let val = String.fromCString(UnsafePointer<CChar>(v)) {
            return val
        }
        
        return nil
    }
    
    public var children:AnySequence<SwHTMLNode> {
        let _children = _node.memory.children
        
        if _children == nil {
            return AnySequence<SwHTMLNode> {
                _ -> EmptyGenerator<SwHTMLNode> in
                return EmptyGenerator<SwHTMLNode>()
            }
        }
        
        return AnySequence<SwHTMLNode> {
            _ -> AnyGenerator<SwHTMLNode> in
            var cursor = _children
            return anyGenerator {
                if cursor == nil {
                    return nil
                }
                
                let current = cursor
                cursor = cursor.memory.next
                
                return SwHTMLNode(_node: current)
            }
        }
    }
    
    public var firstChild:SwHTMLNode? {
        for c in children {
            return c
        }
        
        return nil
    }
    
    public var lastChild:SwHTMLNode? {
        var n:SwHTMLNode?
        
        for c in children {
            n = c
        }
        
        return n
    }
    
    public var nextSibling:SwHTMLNode? {
        let next = _node.memory.next
        
        if(next == nil) {
            return nil
        }
        
        return SwHTMLNode(_node: next)
    }
    
    public var prevSibling:SwHTMLNode? {
        let prev = _node.memory.prev
        
        if(prev == nil) {
            return nil
        }
        
        return SwHTMLNode(_node: prev)
    }
    
    public var parent:SwHTMLNode? {
        let p = _node.memory.parent
        
        if(p == nil) {
            return nil
        }
        
        return SwHTMLNode(_node: p)
    }
    
    public var description:String {
        if type == .ElementNode {
            var str:String = "<"
            str += self.tag ?? ""
            
            for attr in self.attributes {
                str += " " + attr.name + "=\"" + attr.val + "\""
            }
            
            str += ">"
            
            return str
        } else {
            return self.data ?? ""
        }
    }
}

extension SwHTMLNode: Equatable {}

public func ==(lhs: SwHTMLNode, rhs: SwHTMLNode) -> Bool {
    return lhs._node == rhs._node
}
