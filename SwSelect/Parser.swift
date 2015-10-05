//
//  Parser.swift
//  SwSelect
//
//  Created by Julian Shen on 2015/10/5.
//  Copyright © 2015年 cowbay.wtf. All rights reserved.
//

import Foundation

public enum SelectorParseErrorType:ErrorType {
    case UnknownHTML
    case InvalidEscapeSeq
    case ExpectedIdentifier
    case ExpectedName
    case ExpectedString
    case ExpectedNumber
    case UnexpectedToken
    case UnexpectedEOF
}

func hexDigit(c:Character)->Bool {
    return "0" <= c && c <= "9" || "a" <= c && c <= "f" || "A" <= c && c <= "F"
}

func nameStart(c:Character)->Bool {
    return "a" <= c && c <= "z" || "A" <= c && c <= "Z" || c == "_" || c > Character(UnicodeScalar(127))
}

func nameChar(c:Character)->Bool {
    return "a" <= c && c <= "z" || "A" <= c && c <= "Z" || c == "_" || c > Character(UnicodeScalar(127)) || c=="-" || "0" <= c && c<="9"
}

struct Parser {
    var src:String
    var pos:Int
    
    mutating func parseEscape() throws -> String {
        if(src.length < pos+2 || src[pos] != "\\") {
            throw SelectorParseErrorType.UnexpectedToken
        }
        
        let start = pos + 1
        let c:Character = src[start]
        
        switch c {
        case "\r", "\n", "\u{0014}":
            throw SelectorParseErrorType.InvalidEscapeSeq
        case _ where hexDigit(c):
            var i:Int
            for i = start; i < pos+6 && i < src.length && hexDigit(src[i]); i++ {
                // empty
            }
            
            var val:Int
            if let v:Int = Int(src[start..<i], radix: 16) {
                val = v
            } else {
                throw SelectorParseErrorType.InvalidEscapeSeq
            }
            
            if(src.length > i) {
                let a:Character = src[i]
                switch(a) {
                case "\r":
                    i++
                    if(src.length > i && src[i]=="\n") {
                        i++
                    }
                case " ", "\t", "\n", "\u{0014}":
                    i++
                default:
                    break
                }
            }
            
            
            pos = i
            return String(UnicodeScalar(val))
            
        default:
            let result = src[start, start+1]
            pos += 2
            return result
        }
    }
    
    mutating func parseName() throws -> String {
        var result:String = ""
        var i = pos
        
        loop:
            while(i<src.length) {
                let c:Character = src[i]
                switch c {
                case _ where nameChar(c):
                    let start = i
                    while(i < src.length && nameChar(Character(src[i]))) {
                        i++
                    }
                    result += src[start..<i]
                case "\\":
                    pos = i
                    let val = try parseEscape()
                    i = pos
                    result += val
                default:
                    break loop
                }
        }
        
        if result == "" {
            throw SelectorParseErrorType.ExpectedName
        }
        
        pos = i
        return result
    }
    
    mutating func parseIdentifier() throws -> String {
        var startingDash = false
        if src.length > pos && src[pos] == "-" {
            startingDash = true
            pos++
        }
        
        if src.length <= pos {
            throw SelectorParseErrorType.ExpectedIdentifier
        }
        
        let c:Character = src[pos]
        if(!(nameStart(c) || c ==  "\\")) {
            throw SelectorParseErrorType.ExpectedIdentifier
        }
        
        var result:String = try parseName()
        if startingDash {
            result = "-" + result
        }
        return result
    }
    
    // parseString parses a single- or double-quoted string.
    mutating func parseString() throws -> String {
        var result:String = ""
        var i = pos
        if src.length < pos+2 {
            throw SelectorParseErrorType.ExpectedString
        }
        
        let quote:Character = src[i]
        i++
        
        loop:
            while(i < src.length) {
                let c:Character = src[i]
                switch c {
                case "\\":
                    if src.length > i+1 {
                        switch src[i+1] as Character {
                        case "\r\n", "\r", "\n", "\u{0014}":
                            i += 2
                            continue loop
                        default:
                            //Do nothing
                            break
                        }
                    }
                    pos = i
                    let val:String = try parseEscape()
                    i = pos
                    result += val
                case quote:
                    break loop
                case "\r", "\n", "\u{0014}":
                    throw SelectorParseErrorType.UnexpectedToken
                default:
                    let start = i
                    while(i < src.length) {
                        let c:Character = src[i]
                        if(c == quote || c == "\\" || c == "\r" || c == "\n" || c == "\u{0014}") {
                            break
                        }
                        i++
                    }
                    result += src[start..<i]
                }
        }
        
        if i >= src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        // Consume the final quote.
        i++
        
        pos = i
        return result
    }
    
    mutating func parseRegex() throws -> NSRegularExpression {
        var i:Int = pos
        if(src.length < pos+2) {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        // number of open parens or brackets;
        // when it becomes negative, finished parsing regex
        var open:Int = 0
        
        loop:
            for(;i < src.length;i++) {
                let c:Character = src[i]
                switch c {
                case "(", "[":
                    open++
                case ")", "]":
                    open--
                    if(open < 0) {
                        break loop
                    }
                default:
                    break
                }
        }
        
        if(i >= src.length) {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        let pattern:String = src[pos..<i]
        let regex =  try NSRegularExpression(pattern: pattern, options: [])
        
        pos = i
        return regex
    }
    
    mutating func skipWhitespace() -> Bool {
        var i:Int = pos
        while(i < src.length) {
            let c:Character = src[i]
            switch c {
            case " ", "\u{0014}", "\r", "\n":
                i++
                continue
            case "/":
                if(src.substringFromIndex(src.startIndex.advancedBy(i)).hasPrefix("/*")) {
                    let end:Int = src.substringFromIndex(src.startIndex.advancedBy(i + 2)).indexOf("*/")
                    if(end != -1) {
                        i += end + 4//len("/**/")
                        continue
                    }
                }
            default:
                break
            }
            break
        }
        
        if i > pos {
            pos = i
            return true
        }
        
        return false
    }
    
    mutating func consumeParenthesis() -> Bool {
        if(pos < src.length && src[pos] == "(") {
            pos++
            skipWhitespace()
            return true
        }
        return false
    }
    
    mutating func consumeClosingParenthesis() -> Bool {
        let i:Int = pos
        skipWhitespace()
        if(pos < src.length && src[pos] == ")") {
            pos++
            return true
        }
        pos = i
        return false
    }
    
    
    // parseInteger parses a decimal integer.
    mutating func parseInteger() throws -> Int {
        var i = pos
        let start = i
        while(i < src.length && "0" <= src[i] && src[i] <= "9") {
            i++
        }
        
        if(i == start) {
            throw SelectorParseErrorType.ExpectedNumber
        }
        
        pos = i
        
        var val:Int
        if let v:Int = Int(src[start..<i]) {
            val = v
        } else {
            throw SelectorParseErrorType.ExpectedNumber
        }
        
        return val
    }
    
    mutating func parseNth() throws-> (Int, Int) {
        var a:Int = 0
        var b:Int = 0
        
        if pos > src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        let readN = {
            () throws -> Void in
            self.skipWhitespace()
            if self.pos >= self.src.length {
                throw SelectorParseErrorType.UnexpectedEOF
            }
            let c:Character = self.src[self.pos]
            
            switch(c) {
            case "+", "-":
                self.pos++
                self.skipWhitespace()
                b = try self.parseInteger()
                if c=="-" {
                    b = -b
                }
                return
            default:
                b = 0
            }
            return
        }
        
        let readA = {
            () throws -> Void in
            if self.pos >= self.src.length {
                throw SelectorParseErrorType.UnexpectedEOF
            }
            
            let c:Character = self.src[self.pos]
            switch(c) {
            case "n", "N":
                self.pos++
                try readN()
            default:
                b = a
                a = 0
            }
            return
        }
        
        let signA = {
            (sign:Int) throws -> Void in
            if self.pos >= self.src.length {
                throw SelectorParseErrorType.UnexpectedEOF
            }
            
            let c:Character = self.src[self.pos]
            switch(c) {
            case "0"..."9":
                a = try self.parseInteger()
                a = sign * a
                try readA()
            case "n", "N":
                a = sign * 1
                self.pos++
                try readN()
            default:
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            return
        }
        
        let c:Character = src[pos]
        switch(c) {
        case "-":
            pos++
            try signA(-1)
        case "+":
            pos++
            try signA(1)
        case "0"..."9":
            try signA(1)
        case "n", "N":
            a = 1
            pos++
            try readN()
        case "o", "O", "e", "E":
            let id = try parseName().lowercaseString
            
            if id == "odd" {
                return (2, 1)
            }
            
            if id == "even" {
                return (2, 0)
            }
            throw SelectorParseErrorType.UnexpectedToken
        default:
            throw SelectorParseErrorType.UnexpectedToken
        }
        return (a,b)
    }
    
    mutating func parseTypeSelector() throws-> Selector {
        let tag = try parseIdentifier()
        return typeSelector(tag)
    }
    
    mutating func parseIDSelector() throws-> Selector {
        if pos > src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        if src[pos] != "#" {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        pos++
        
        let id = try parseName()
        return attributeEqualsSelector("id", id)
    }
    
    mutating func parseClassSelector() throws-> Selector {
        if pos > src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        if src[pos] != "." {
            throw SelectorParseErrorType.UnexpectedToken
        }
        
        pos++
        
        let className = try parseName()
        return attributeIncludesSelector("class", className)
    }
    
    mutating func parseAttributeSelector() throws -> Selector {
        if pos > src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        if src[pos] != "[" {
            throw SelectorParseErrorType.UnexpectedToken
        }
        
        pos++
        skipWhitespace()
        let key = try parseIdentifier()
        
        skipWhitespace()
        if pos > src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        if src[pos] == "]" {
            pos++
            return attributeExistsSelector(key)
        }
        
        if pos+2 >= src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        var op = src[pos, pos+2]
        if op[0] == "=" {
            op = "="
        } else if op[1] != "=" {
            throw SelectorParseErrorType.UnexpectedToken
        }
        
        pos += op.length
        
        skipWhitespace()
        if pos > src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        var val:String?
        var rx:NSRegularExpression?
        
        if op == "#=" {
            rx = try parseRegex()
        } else {
            switch src[pos] as Character {
            case "'", "\"":
                val = try parseString()
            default:
                val = try parseIdentifier()
            }
        }
        
        skipWhitespace()
        if pos > src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        if src[pos] != "]" {
            throw SelectorParseErrorType.UnexpectedToken
        }
        pos++
        
        switch op {
        case "=":
            return attributeEqualsSelector(key, val!)
        case "~=":
            return attributeIncludesSelector(key, val!)
        case "|=":
            return attributeDashmatchSelector(key, val!)
        case "^=":
            return attributePrefixSelector(key, val!)
        case "$=":
            return attributeSuffixSelector(key, val!)
        case "*=":
            return attributeSubstringSelector(key, val!)
        case "#=":
            return attributeRegexSelector(key, rx!)
        default:
            throw SelectorParseErrorType.UnexpectedToken
        }
    }
    
    mutating func parsePseudoclassSelector() throws -> Selector {
        if pos > src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        if src[pos] != ":" {
            throw SelectorParseErrorType.UnexpectedToken
        }
        
        pos++
        let name = try parseIdentifier().lowercaseString
        
        switch name {
        case "not", "has", "haschild":
            if !consumeParenthesis() {
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            let sel = try parseSelectorGroup()
            if !consumeClosingParenthesis() {
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            switch name {
            case "not":
                return negatedSelector(sel)
            case "has":
                return hasDescendantSelector(sel)
            case "haschild":
                return hasChildSelector(sel)
            default:
                throw SelectorParseErrorType.UnexpectedToken
            }
        case "contains", "containsown":
            if !consumeParenthesis() {
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            if pos == src.length {
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            var val:String?
            switch src[pos] as Character {
            case "'","\"":
                val = try parseString()
            default:
                val = try parseIdentifier()
            }
            val = val?.lowercaseString
            skipWhitespace()
            if pos > src.length {
                throw SelectorParseErrorType.UnexpectedEOF
            }
            
            if !consumeClosingParenthesis() {
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            switch(name) {
            case "contains":
                return textSubstrSelector(val!)
            case "containsown":
                return ownTextSubstrSelector(val!)
            default:
                throw SelectorParseErrorType.UnexpectedToken
            }
        case "matches", "matchesown":
            if !consumeParenthesis() {
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            if pos == src.length {
                throw SelectorParseErrorType.UnexpectedEOF
            }
            
            let rx = try parseRegex()
            if pos == src.length {
                throw SelectorParseErrorType.UnexpectedEOF
            }
            
            if !consumeClosingParenthesis() {
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            switch name {
            case "matches":
                return textRegexSelector(rx)
            case "matchesown":
                return ownTextRegexSelector(rx)
            default:
                throw SelectorParseErrorType.UnexpectedToken
            }
        case "nth-child", "nth-last-child", "nth-of-type", "nth-last-of-type":
            if !consumeParenthesis() {
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            let (a, b) = try parseNth()
            
            if !consumeClosingParenthesis() {
                throw SelectorParseErrorType.UnexpectedToken
            }
            
            return nthChildSelector(a, b: b, last: name == "nth-last-child" || name == "nth-last-of-type", ofType: name == "nth-of-type" || name == "nth-last-of-type")
        case "first-child":
            return nthChildSelector(0, b:1, last:false, ofType:false)
        case "last-child":
            return nthChildSelector(0, b:1, last:true, ofType:false)
        case "first-of-type":
            return nthChildSelector(0, b:1, last:false, ofType:true)
        case "last-of-type":
            return nthChildSelector(0, b:1, last:true, ofType:true)
        case "only-child":
            return onlyChildSelector(false)
        case "only-of-type":
            return onlyChildSelector(true)
        case "input":
            return inputSelector()
        case "empty":
            return emptyElementSelector()
        default:
            throw SelectorParseErrorType.UnexpectedToken
        }
    }
    
    mutating func parseSimpleSelectorSequence() throws -> Selector {
        var result:Selector?
        if pos > src.length {
            throw SelectorParseErrorType.UnexpectedEOF
        }
        
        switch src[pos] as Character {
        case "*":
            pos++
        case "#", ".", "[", ":":
            break
        default:
            result = try parseTypeSelector()
        }
        
        loop:
            while(pos < src.length) {
                var ns:Selector?
                switch src[pos] as Character {
                case "#":
                    ns = try parseIDSelector()
                case ".":
                    ns = try parseClassSelector()
                case "[":
                    ns = try parseAttributeSelector()
                case ":":
                    ns = try parsePseudoclassSelector()
                default:
                    break loop
                }
                
                if(ns != nil) {
                    if result == nil {
                        result = ns
                    } else {
                        result = intersectionSelector(result!, ns!)
                    }
                }
        }
        
        if result == nil {
            result = {
                (_:SwHTMLNode) -> Bool in
                return true
            }
        }
        
        return result!
    }
    
    
    //TODO: review
    mutating func parseSelector() throws -> Selector {
        skipWhitespace()
        var result = try parseSimpleSelectorSequence()
        
        while(true) {
            var combinator:Character?
            
            if skipWhitespace() {
                combinator = " "
            }
            
            if pos >= src.length {
                return result
            }
            
            switch src[pos] as Character {
            case "+", ">", "~":
                combinator = src[pos]
                pos++
                skipWhitespace()
            case ",", ")":
                return result
            default:
                break
            }
            
            if combinator == nil {
                return result
            }
            
            let c = try parseSimpleSelectorSequence()
            switch combinator! {
            case " ":
                result = descendantSelector(result, c)
            case ">":
                result = childSelector(result, c)
            case "+":
                result = siblingSelector(result, c, adjacent: true)
            case "~":
                result = siblingSelector(result, c, adjacent: false)
            default:
                break
            }
        }
    }
    
    mutating func parseSelectorGroup() throws -> Selector {
        var result = try parseSelector()
        
        while pos < src.length {
            if src[pos] != "," {
                return result
            }
            
            pos++
            let c = try parseSelector()
            result = unionSelector(result, c)
        }
        
        return result
    }
}