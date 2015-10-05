//
//  Selector.swift
//  SwSelect
//
//  Created by Julian Shen on 2015/10/5.
//  Copyright © 2015年 cowbay.wtf. All rights reserved.
//

import Foundation

typealias Selector = (SwHTMLNode) -> Bool

func _matchAll(s: Selector, _ node: SwHTMLNode, _ included:Bool) -> [SwHTMLNode] {
    var nodes = [SwHTMLNode]()
    
    if s(node) && included {
        nodes.append(node)
    }
    
    for c in node.children {
        let matched = _matchAll(s, c, true)
        nodes += matched
    }
    
    return nodes
}

func _match(s: Selector, _ node:SwHTMLNode) -> Bool {
    return s(node)
}

func _matchFirst(s: Selector, _ node:SwHTMLNode) -> SwHTMLNode? {
    if _match(s, node) {
        return node
    }
    
    for c in node.children {
        if let matched = _matchFirst(s, c) {
            return matched
        }
    }
    
    return nil
}

func _filter(s: Selector, _ nodes:[SwHTMLNode]) -> [SwHTMLNode] {
    var results:[SwHTMLNode] = [SwHTMLNode]()
    for n in nodes {
        if s(n) {
            results.append(n)
        }
    }
    return results
}

func _not(s: Selector, _ nodes:[SwHTMLNode]) -> [SwHTMLNode] {
    var results:[SwHTMLNode] = [SwHTMLNode]()
    for n in nodes {
        if !s(n) {
            results.append(n)
        }
    }
    return results
}

func typeSelector(tag:String) -> Selector {
    let tagLower = tag.lowercaseString
    
    return {
        (node:SwHTMLNode) -> Bool in
        return node.tag?.lowercaseString == tagLower
    }
}

func hasChildMatch(node:SwHTMLNode, _ selector:Selector) -> Bool {
    for c in node.children {
        if selector(c) {
            return true
        }
    }
    
    return false
}

func hasDescendantMatch(node:SwHTMLNode, _ selector:Selector) -> Bool {
    for c in node.children {
        if selector(c) || (c.type == .ElementNode && hasDescendantMatch(c, selector)) {
            return true
        }
    }
    
    return false
}

func attributeSelector(key:String, f:(String)->Bool)->Selector {
    let keyLower = key.lowercaseString
    
    return {
        (node:SwHTMLNode)->Bool in
        if node.type != .ElementNode {
            return false
        }
        
        
        for attribute in node.attributes {
            if attribute.name.lowercaseString == keyLower && f(attribute.val) {
                return true
            }
        }
        return false
    }
}

func attributeExistsSelector(key:String) -> Selector {
    return attributeSelector(key, f:  { (String)->Bool in return true})
}

func attributeEqualsSelector(key:String, _ val:String) -> Selector {
    return attributeSelector(key, f:  {$0==val})
}

func attributeIncludesSelector(key:String, _ val:String) -> Selector {
    return attributeSelector(key, f:  {
        (str:String) -> Bool in
        if str == "" {
            return false
        }
        
        let splitted = str.characters.split(isSeparator:
            {
                (s:Character)->Bool in
                let b = (s == " " || s == "\r" || s == "\n" || s == "\u{0014}")
                return b
        })
        
        for s in splitted {
            if(String(s) == val) {
                return true
            }
        }
        
        return false
    })
}

func attributeDashmatchSelector(key:String, _ val:String) -> Selector {
    return attributeSelector(key, f:  {
        (str:String) -> Bool in
        if str == val {
            return true
        }
        
        let s = val + "-"
        if str.hasPrefix(s) {
            return true
        }
        return false
    })
}

func attributePrefixSelector(key:String, _ val:String) -> Selector {
    return attributeSelector(key, f:  {
        $0.hasPrefix(val)
    })
}

func attributeSuffixSelector(key:String, _ val:String) -> Selector {
    return attributeSelector(key, f:  {
        $0.hasSuffix(val)
    })
}

func attributeSubstringSelector(key:String, _ val:String) -> Selector {
    return attributeSelector(key, f:  {
        $0.containsString(val)
    })
}

func attributeRegexSelector(key:String, _ regex:NSRegularExpression) -> Selector {
    return attributeSelector(key, f:  {
        regex.numberOfMatchesInString($0, options: [], range: NSMakeRange(0, $0.length)) > 0
    })
}

func intersectionSelector(a:Selector, _ b:Selector) -> Selector {
    return {
        a($0) && b($0)
    }
}

func unionSelector(a:Selector, _ b:Selector) -> Selector {
    return {
        a($0) || b($0)
    }
}

func negatedSelector(a:Selector) -> Selector {
    return {
        !a($0)
    }
}

func nodeText(n:SwHTMLNode) -> String {
    switch n.type {
    case .ElementNode:
        var result:String = ""
        for c in n.children {
            result += nodeText(c)
        }
        return result
    case .TextNode:
        fallthrough
    default:
        return n.data ?? ""
    }
}

func nodeOwnText(n:SwHTMLNode) -> String {
    var result:String = ""
    
    for c in n.children {
        if c.type == .TextNode {
            result += c.data ?? ""
        }
    }
    
    return result
}

func textSubstrSelector(val:String) -> Selector {
    return {
        (node:SwHTMLNode)->Bool in
        let text = nodeText(node).lowercaseString
        return text.containsString(val)
    }
}

func ownTextSubstrSelector(val:String) -> Selector {
    return {
        (node:SwHTMLNode)->Bool in
        let text = nodeOwnText(node).lowercaseString
        return text.containsString(val)
    }
}

func textRegexSelector(regex:NSRegularExpression) -> Selector {
    return {
        (node:SwHTMLNode)->Bool in
        let text = nodeText(node)
        return regex.numberOfMatchesInString(text, options: [], range: NSMakeRange(0, text.length)) > 0
    }
}

func ownTextRegexSelector(regex:NSRegularExpression) -> Selector {
    return {
        (node:SwHTMLNode)->Bool in
        let text = nodeOwnText(node)
        return regex.numberOfMatchesInString(text, options: [], range: NSMakeRange(0, text.length)) > 0
    }
}

func hasChildSelector(s:Selector) -> Selector {
    return {
        (node:SwHTMLNode) -> Bool in
        if node.type != .ElementNode {
            return false
        }
        return hasChildMatch(node, s)
    }
}

func hasDescendantSelector(s:Selector) -> Selector {
    return {
        (node:SwHTMLNode) -> Bool in
        if node.type != .ElementNode {
            return false
        }
        return hasDescendantMatch(node, s)
    }
}

func nthChildSelector(a:Int, b:Int, last:Bool, ofType:Bool) -> Selector {
    return {
        (node:SwHTMLNode) -> Bool in
        if node.type != .ElementNode {
            return false
        }
        
        if let parent = node.parent {
            var i:Int = -1
            var count:Int = 0
            
            for c in parent.children {
                if (c.type != .ElementNode) || (ofType && c.data != node.data) {
                    continue
                } else {
                    count++
                    if c == node {
                        i = count
                        if !last {
                            break
                        }
                    }
                }
            }
            
            if i == -1 {
                return false
            }
            
            if last {
                i = count - i + 1
            }
            
            i -= b
            if a == 0 {
                return i == 0
            }
            
            return i%a == 0 && i/a >= 0
        }
        
        return false
    }
}

func onlyChildSelector(ofType:Bool) -> Selector {
    return {
        (node:SwHTMLNode) -> Bool in
        if node.type != .ElementNode {
            return false
        }
        
        if let parent = node.parent {
            var count:Int = 0
            for c in parent.children {
                if (c.type != .ElementNode) || (ofType && c.data != node.data) {
                    continue
                } else {
                    count++
                    if count > 1 {
                        return false
                    }
                }
            }
            
            return count == 1
        }
        
        return false
    }
}

func inputSelector() -> Selector {
    return {
        ($0.type == .ElementNode) && ($0.data.containedIn(["input", "select", "textarea", "button"]))
    }
}

func emptyElementSelector() -> Selector {
    return {
        (node:SwHTMLNode) -> Bool in
        if node.type != .ElementNode {
            return false
        }
        
        for c in node.children {
            switch c.type {
            case .ElementNode, .TextNode:
                return false
            default:
                break
            }
        }
        
        return true
    }
}

func descendantSelector(a: Selector, _ d: Selector) -> Selector {
    return {
        (node:SwHTMLNode) -> Bool in
        if !d(node) {
            return false
        }
        
        for(var p=node.parent; p != nil ; p=p?.parent) {
            if a(p!) {
                return true
            }
        }
        
        return false
    }
}

func childSelector(a: Selector, _ d: Selector) -> Selector {
    return {
        d($0) && ($0.parent != nil && a($0.parent!))
    }
}

func siblingSelector(s1:Selector, _ s2:Selector, adjacent:Bool) -> Selector {
    return {
        (node:SwHTMLNode) -> Bool in
        if !s2(node) {
            return false
        }
        
        
        //TODO: Refine logic
        if adjacent {
            for(var n=node.prevSibling; n != nil ; n=n?.prevSibling) {
                let type:SwHTMLNodeType = (n?.type)!
                if (type == .TextNode || type == .CommentNode) {
                    continue
                } else {
                    return s1(n!)
                }
            }
        }
        
        // Walk backwards looking for element that matches s1
        for(var n=node.prevSibling; n != nil ; n=n?.prevSibling) {
            if s1(n!) {
                return true
            }
        }
        
        return false
    }
}

func compileQuery(sel:String) throws -> Selector {
    var p = Parser(src: sel, pos:0)
    let compiled = try p.parseSelectorGroup()
    if p.pos < p.src.length {
        throw SelectorParseErrorType.UnexpectedToken
    }
    return compiled
}

public extension CollectionType where Self.Generator.Element == SwHTMLNode {
    public func find(sel:String) -> [Self.Generator.Element] {
        var results = [SwHTMLNode]()
        do {
            let s = try compileQuery(sel)
            for n in self {
                let nodes = _matchAll(s, n, false)
                results.appendContentsOf(nodes)
            }
        } catch {}
        
        return results
    }
    
    public var last:Self.Generator.Element? {
        return self[self.endIndex]
    }
    
    public func filter(sel:String) -> [Self.Generator.Element] {
        do {
            let s = try compileQuery(sel)
            return _filter(s, Array(self))
        } catch {
            return [SwHTMLNode]()
        }
    }

    public func not(sel:String) -> [Self.Generator.Element] {
        do {
            let s = try compileQuery(sel)
            return _not(s, Array(self))
        } catch {
            return [SwHTMLNode]()
        }
    }
    
    public func attrs(name:String) -> [String] {
        var results = [String]()
        
        for n in self {
            if let attrVal = n.attr(name) {
                results.append(attrVal)
            }
        }
        
        return results
    }
}

public extension SwHTMLNode {
    public func match(sel:String) -> Bool {
        do {
            let s = try compileQuery(sel)
            return _match(s, self)
        } catch {
            return false
        }
    }
    
    public func find(sel:String) -> [SwHTMLNode] {
        var results = [SwHTMLNode]()
        
        do {
            let s = try compileQuery(sel)
            let nodes = _matchAll(s, self, false)
            results.appendContentsOf(nodes)
        } catch {
        }
        
        return results
    }
    
    func matchAll(sel:String) -> [SwHTMLNode] {
        var results = [SwHTMLNode]()
        
        do {
            let s = try compileQuery(sel)
            let nodes = _matchAll(s, self, true)
            results.appendContentsOf(nodes)
        } catch {
        }
        
        return results
    }
}
