//
//  SwSelect.swift
//  SwSelect
//
//  Created by Julian Shen on 2015/10/5.
//  Copyright © 2015年 cowbay.wtf. All rights reserved.
//

import Foundation
import libxml2

public enum SwSelectErrorType:ErrorType {
    case HTMLParseError
}

public func SwSelect(htmlNode:SwHTMLNode) -> (String) -> [SwHTMLNode] {
    return {
        htmlNode.matchAll($0)
    }
}

public func SwSelect(html:String) throws -> (String) -> [SwHTMLNode] {
    let htmlParseOptions : CInt = 1 << 0 | 1 << 5 | 1 << 6
    let c_str = (html as NSString).UTF8String
    let doc = htmlReadMemory(c_str, CInt(html.length), nil, nil, htmlParseOptions)
    
    guard(doc != nil) else {
        throw SwSelectErrorType.HTMLParseError
    }
    
    let xmlDocRootNode : xmlNodePtr = xmlDocGetRootElement(doc)
    let node = SwHTMLNode(_node: xmlDocRootNode)
    
    return SwSelect(node)
}