//
//  SwSelectTests.swift
//  SwSelectTests
//
//  Created by Julian Shen on 2015/10/5.
//  Copyright © 2015年 cowbay.wtf. All rights reserved.
//

import XCTest
@testable import SwSelect

struct SelectorTest {
    let html:String
    let selector:String
    let expected:[String]
}

class SwSelectTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testParseIdentifier() {
        let identifierTests:[String:String] = ["x":"x", "90":"", "-x":"-x", "r\\e9sumé":"résumé", "a\\\"b":"a\"b"]
        for (src, want) in identifierTests {
            var p = Parser(src: src, pos:0)
            do {
                let got = try p.parseIdentifier()
                print("parsing " + src)
                assert(want == got, "Wrong identifier: \"" + got + "\" expected \""  + want + "\"")
            } catch {
                if want != "" {
                    assertionFailure("Error parsing identifier")
                }
            }
        }
    }
    
    func testParseString() {
        let stringTests:[String:String] = ["\"x\"":"x", "'x'":"x", "'x":"", "'x\\\r\nx'":"xx", "\"r\\e9sumé\"":"résumé", "\"a\\\"b\"":"a\"b"]
        
        for (src, want) in stringTests{
            var p = Parser(src: src, pos:0)
            
            do {
                let got = try p.parseString()
                let a = "'x\\\r\nx'"
                
                for s in a.characters {
                    if s=="\r" {
                        print("got you")
                    }
                }
                assert(want != "" && got != "", "Expected error but got \"" + got + "\"")
                assert(want == got, "Wrong string: \"" + got + "\" expected \""  + want + "\"")
                
                assert(p.pos == p.src.length, "Something has been left behind")
            } catch {
                if want != "" {
                    assertionFailure("Error parsing string: " + src + ":" + want)
                }
            }
        }
    }
    
    func testSelector() {
        let selTests:[SelectorTest] = [
            SelectorTest(html:"<body><address>This address...</address></body>", selector:"address", expected:["<address>"]),
            SelectorTest(html:"<html><head></head><body></body></html>", selector:"*", expected:["<html>","<head>","<body>"]),
            SelectorTest(html:"<p id=\"foo\"><p id=\"bar\">", selector:"#foo", expected:["<p id=\"foo\">"]),
            SelectorTest(html:"<ul><li id=\"t1\"><p id=\"t1\">", selector:"li#t1", expected:["<li id=\"t1\">"]),
            SelectorTest(html:"<ol><li id=\"t4\"><li id=\"t44\">", selector:"*#t4", expected:["<li id=\"t4\">"]),
            SelectorTest(html:"<ul><li class=\"t1\"><li class=\"t2\">", selector:".t1", expected:["<li class=\"t1\">"]),
            SelectorTest(html:"<p class=\"t1 t2\">", selector:"p.t1", expected:["<p class=\"t1 t2\">"]),
            SelectorTest(html:"<div class=\"test\">", selector:"div.teST", expected:[]),
            SelectorTest(html:"<p class=\"t1 t2\">", selector:".t1.fail", expected:[]),
            SelectorTest(html:"<p class=\"t1 t2\">", selector:"p.t1.t2", expected:["<p class=\"t1 t2\">"]),
            SelectorTest(html:"<p><p title=\"title\">", selector:"p[title]", expected:["<p title=\"title\">"]),
            SelectorTest(html:"<address><address title=\"foo\"><address title=\"bar\">", selector:"address[title=\"foo\"]", expected:["<address title=\"foo\">"]),
            SelectorTest(html:"<p title=\"tot foo bar\">", selector:"[    title        ~=       foo    ]", expected:["<p title=\"tot foo bar\">"]),
            SelectorTest(html:"<p title=\"hello world\">", selector:"[title~=\"hello world\"]", expected:[]),
            SelectorTest(html:"<p lang=\"en\"><p lang=\"en-gb\"><p lang=\"enough\"><p lang=\"fr-en\">", selector:"[lang|=\"en\"]", expected:["<p lang=\"en\">", "<p lang=\"en-gb\">"]),
            SelectorTest(html:"<p title=\"foobar\"><p title=\"barfoo\">", selector:"[title^=\"foo\"]", expected:["<p title=\"foobar\">"]),
            SelectorTest(html:"<p title=\"foobar\"><p title=\"barfoo\">", selector:"[title$=\"bar\"]", expected:["<p title=\"foobar\">"]),
            SelectorTest(html:"<p title=\"foobarufoo\">", selector:"[title*=\"bar\"]", expected:["<p title=\"foobarufoo\">"]),
            SelectorTest(html:"<p class=\"t1 t2\">", selector:".t1:not(.t2)", expected:[]),
            SelectorTest(html:"<div class=\"t3\">", selector:"div:not(.t1)", expected:["<div class=\"t3\">"]),
            SelectorTest(html:"<ol><li id=1><li id=2><li id=3></ol>", selector:"li:nth-child(odd)", expected:["<li id=\"1\">", "<li id=\"3\">"]),
            SelectorTest(html:"<ol><li id=1><li id=2><li id=3></ol>", selector:"li:nth-child(even)", expected:["<li id=\"2\">"]),
            SelectorTest(html:"<ol><li id=1><li id=2><li id=3></ol>", selector:"li:nth-child(-n+2)", expected:["<li id=\"1\">", "<li id=\"2\">"]),
            SelectorTest(html:"<ol><li id=1><li id=2><li id=3></ol>", selector:"li:nth-child(3n+1)", expected:["<li id=\"1\">"]),
            SelectorTest(html:"<ol><li id=1><li id=2><li id=3><li id=4></ol>", selector:"li:nth-last-child(odd)", expected:["<li id=\"2\">","<li id=\"4\">"]),
            SelectorTest(html:"<ol><li id=1><li id=2><li id=3><li id=4></ol>", selector:"li:nth-last-child(even)", expected:["<li id=\"1\">","<li id=\"3\">"]),
            SelectorTest(html:"<ol><li id=1><li id=2><li id=3><li id=4></ol>", selector:"li:nth-last-child(-n+2)", expected:["<li id=\"3\">","<li id=\"4\">"]),
            SelectorTest(html:"<ol><li id=1><li id=2><li id=3><li id=4></ol>", selector:"li:nth-last-child(3n+1)", expected:["<li id=\"1\">","<li id=\"4\">"]),
            SelectorTest(html:"<p>some text <span id=\"1\">and a span</span><span id=\"2\"> and another</span></p>", selector:"span:first-child", expected:["<span id=\"1\">"]),
            SelectorTest(html:"<span>a span</span> and some text", selector:"span:last-child", expected:["<span>"]),
            SelectorTest(html:"<address></address><p id=1><p id=2>", selector:"p:nth-of-type(2)", expected:["<p id=\"2\">"]),
            SelectorTest(html:"<address></address><p id=1><p id=2>", selector:"p:nth-last-of-type(2)", expected:["<p id=\"1\">"]),
            SelectorTest(html:"<address></address><p id=1><p id=2>", selector:"p:last-of-type", expected:["<p id=\"2\">"]),
            SelectorTest(html:"<address></address><p id=1><p id=2>", selector:"p:first-of-type", expected:["<p id=\"1\">"]),
            SelectorTest(html:"<div><p id=\"1\"></p><a></a></div><div><p id=\"2\"></p></div>", selector:"p:only-child", expected:["<p id=\"2\">"]),
            SelectorTest(html:"<div><p id=\"1\"></p><a></a></div><div><p id=\"2\"></p><p id=\"3\"></p></div>", selector:"p:only-of-type", expected:["<p id=\"1\">"]),
            SelectorTest(html:"<p id=\"1\"><!-- --><p id=\"2\">Hello<p id=\"3\"><span>", selector:":empty", expected:["<p id=\"1\">", "<span>"]),
            SelectorTest(html:"<div><p id=\"1\"><table><tr><td><p id=\"2\"></table></div><p id=\"3\">", selector:"div p", expected:["<p id=\"1\">", "<p id=\"2\">"]),
            SelectorTest(html:"<div><p id=\"1\"><table><tr><td><p id=\"2\"></table></div><p id=\"3\">", selector:"div table p", expected:["<p id=\"2\">"]),
            SelectorTest(html:"<div><p id=\"1\"><div><p id=\"2\"></div><table><tr><td><p id=\"3\"></table></div>", selector:"div > p", expected:["<p id=\"1\">", "<p id=\"2\">"]),
            SelectorTest(html:"<p id=\"1\"><p id=\"2\"></p><address></address><p id=\"3\">", selector:"p ~ p", expected:["<p id=\"2\">", "<p id=\"3\">"]),
            SelectorTest(html:"<p id=\"1\"></p>\n<!--comment-->\n                <p id=\"2\"></p><address></address><p id=\"3\">", selector:"p + p", expected:["<p id=\"2\">"]),
            SelectorTest(html:"<ul><li></li><li></li></ul><p>", selector:"li, p", expected:["<li>", "<li>", "<p>"]),
            SelectorTest(html:"<p id=\"1\"><p id=\"2\"></p><address></address><p id=\"3\">", selector:"p +/*This is a comment*/ p", expected:["<p id=\"2\">"]),
            SelectorTest(html:"<p>Text block that <span>wraps inner text</span> and continues</p>", selector:"p:contains(\"that wraps\")", expected:["<p>"]),
            SelectorTest(html:"<p>Text block that <span>wraps inner text</span> and continues</p>", selector:"p:containsOwn(\"that wraps\")", expected:[]),
            SelectorTest(html:"<p>Text block that <span>wraps inner text</span> and continues</p>", selector:":containsOwn(\"inner\")", expected:["<span>"]),
            SelectorTest(html:"<p>Text block that <span>wraps inner text</span> and continues</p>", selector:"p:containsOwn(\"block\")", expected:["<p>"]),
            SelectorTest(html:"<div id=\"d1\"><p id=\"p1\"><span>text content</span></p></div><div id=\"d2\"/>", selector:"div:has(#p1)", expected:["<div id=\"d1\">"]),
            SelectorTest(html:"<div id=\"d1\"><p id=\"p1\"><span>contents 1</span></p></div>\n<div id=\"d2\"><p>contents <em>2</em></p></div>", selector:"div:has(:containsOwn(\"2\"))", expected:["<div id=\"d2\">"]),
            SelectorTest(html:"<p id=\"p1\">0123456789</p><p id=\"p2\">abcdef</p><p id=\"p3\">0123ABCD</p>", selector:"p:matches([\\d])", expected:["<p id=\"p1\">", "<p id=\"p3\">"]),
            SelectorTest(html:"<p id=\"p1\">0123456789</p><p id=\"p2\">abcdef</p><p id=\"p3\">0123ABCD</p>", selector:"p:matches([a-z])", expected:["<p id=\"p2\">"]),
            SelectorTest(html:"<p id=\"p1\">0123456789</p><p id=\"p2\">abcdef</p><p id=\"p3\">0123ABCD</p>", selector:"p:matches([a-zA-Z])", expected:["<p id=\"p2\">", "<p id=\"p3\">"]),
            SelectorTest(html:"<p id=\"p1\">0123456789</p><p id=\"p2\">abcdef</p><p id=\"p3\">0123ABCD</p>", selector:"p:matches([^\\d])", expected:["<p id=\"p2\">", "<p id=\"p3\">"]),
            SelectorTest(html:"<p id=\"p1\">0123456789</p><p id=\"p2\">abcdef</p><p id=\"p3\">0123ABCD</p>", selector:"p:matches(^(0|a))", expected:["<p id=\"p1\">", "<p id=\"p2\">", "<p id=\"p3\">"]),
            SelectorTest(html:"<p id=\"p1\">0123456789</p><p id=\"p2\">abcdef</p><p id=\"p3\">0123ABCD</p>", selector:"p:matches(^\\d+$)", expected:["<p id=\"p1\">"]),
            SelectorTest(html:"<p id=\"p1\">0123456789</p><p id=\"p2\">abcdef</p><p id=\"p3\">0123ABCD</p>", selector:"p:not(:matches(^\\d+$))", expected:["<p id=\"p2\">", "<p id=\"p3\">"]),
            SelectorTest(html:"<ul>\n" +
                "<li><a id=\"a1\" href=\"http://www.google.com/finance\"/>\n" +
                "<li><a id=\"a2\" href=\"http://finance.yahoo.com/\"/>\n" +
                "<li><a id=\"a2\" href=\"http://finance.untrusted.com/\"/>\n" +
                "<li><a id=\"a3\" href=\"https://www.google.com/news\"/>\n" +
                "<li><a id=\"a4\" href=\"http://news.yahoo.com\"/>\n" +
                "</ul>", selector:"[href#=(fina)]:not([href#=(\\/\\/[^\\/]+untrusted)])", expected:["<a id=\"a1\" href=\"http://www.google.com/finance\">", "<a id=\"a2\" href=\"http://finance.yahoo.com/\">"]),
            SelectorTest(html:"<form>\n" +
                "<label>Username <input type=\"text\" name=\"username\" /></label>\n" +
                "<label>Password <input type=\"password\" name=\"password\" /></label>\n" +
                "<label>Country\n" +
                "<select name=\"country\">\n" +
                "<option value=\"ca\">Canada</option>\n" +
                "<option value=\"us\">United States</option>\n" +
                "</select>\n" +
                "</label>" +
                "<label>Bio <textarea name=\"bio\"></textarea></label>" +
                "<button>Sign up</button>" +
                "</form>", selector:":input", expected:["<input type=\"text\" name=\"username\">", "<input type=\"password\" name=\"password\">", "<select name=\"country\">", "<textarea name=\"bio\">", "<button>"]),
            SelectorTest(html:"<ul>\n" +
                "<li><a id=\"a1\" href=\"http://www.google.com/finance\"/>\n" +
                "<li><a id=\"a2\" href=\"http://finance.yahoo.com/\"/>\n" +
                "<li><a id=\"a3\" href=\"https://www.google.com/news\"/>\n" +
                "<li><a id=\"a4\" href=\"http://news.yahoo.com\"/>\n" +
                "</ul>", selector:"[href#=(^https:\\/\\/[^\\/]*\\/?news)]", expected:["<a id=\"a3\" href=\"https://www.google.com/news\">"])
            
        ]
        
        for test in selTests {
            do {
                let $ = try SwSelect(test.html)
                
                let nodes = $(test.selector)
                
                assert(nodes.count == test.expected.count, "Wrong result count " + String(nodes.count) + " should be " + String(test.expected.count) + ":" + test.html + " selector:" + test.selector)
                var c = 0
                for n in nodes {
                    if(String(n).containedIn(test.expected)) {
                        c++
                    }
                }
                assert(nodes.count == c, "Wrong result count")
            } catch {
                assertionFailure("Error testing selector: " + test.selector)
            }
        }
    }
    
    func testFind() {
        let html:String = "<ul class=\"level-1\">" +
        "<li class=\"item-i\">I</li>" +
        "<li class=\"item-ii\">II" +
        "<ul class=\"level-2\">" +
        "<li class=\"item-a\">A</li>" +
        "<li class=\"item-b\">B" +
        "<ul class=\"level-3\">" +
        "<li class=\"item-1\">1</li>" +
        "<li class=\"item-2\">2</li>" +
        "<li class=\"item-3\">3</li>" +
        "</ul>" +
        "</li>" +
        "<li class=\"item-c\">C</li>" +
        "</ul>" +
        "</li>" +
        "<li class=\"item-iii\">III</li>" +
        "</ul>"
        
        do {
            let $ = try SwSelect(html)
        
            let nodes = $( "li.item-ii" ).find( "li" )
            
            assert(nodes.count == 6, "Testing find: Wrong count - " + String(nodes.count))
        } catch {
            assertionFailure("Error testing find")
        }
    }
    
    func testAttr() {
        let html:String = "<ul class=\"level-1\"><li>Test</li></ul>"
        do {
            let $ = try SwSelect(html)
            
            let nodes = $( "ul" )
            
            let n = nodes.first!
            if let a = n.attr("class") {
                assert(a == "level-1", "Wrong attribute: " + a)
            }
            
            let lis = nodes.find("li")
            let l = lis.first!
            if let _ = l.attr("class") {
                assert(false, "Attr class should not be existed")
            }
        } catch {
            assertionFailure("Error testing find")
        }
    }
    
    func testAttrs() {
        let html:String = "<ul class=\"level-1\"><li class=\"l2\">Test2</li><li class=\"l1\">Test</li><li>aaa</li></ul>"
        do {
            let $ = try SwSelect(html)
            
            let nodes = $( "li" )
            let aVals = nodes.attrs("class")
            assert(aVals.count == 2, "Wrong attrs got")
            
            for v in aVals {
                print(v)
            }
        } catch {
            assertionFailure("Error testing find")
        }
    }
    
    func testText() {
        let html:String = "<ul class=\"level-1\"><li class=\"l2\">Test2</li><li class=\"l1\">Test</li><li class=\"l1\">aaa</li></ul>"
        do {
            let $ = try SwSelect(html)
            
            var nodes = $( "ul" )
            assert(nodes.first!.text == "Test2Testaaa")
            
            nodes = $(".l1")
            assert(nodes.text == "Testaaa")
        } catch {
            assertionFailure("Error testing find")
        }
    }
}
