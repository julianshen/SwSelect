# SwSelect
[![Build Status](https://travis-ci.org/julianshen/SwSelect.svg?branch=master)](https://travis-ci.org/julianshen/SwSelect)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

The Swift framework provides similar selector implementation to [jQuery](http://jquery.com). It could be used for parsing HTML easily with jQuery style queries. Currently, it supports only tag queries but no content manipulations. Most codes are ported from an Golang project called ["Cascadia"](https://github.com/andybalholm/cascadia).

## Installation
Add this to your carthage file:
`github "julianshen/SWPalette" "master"`

## Simple usage
```Swift
//Get image urls
let $ = SwSelect(html)
let imgUrls = $(”img”).attrs(”src”)
for url in imgUrls {
    print(url)
}

//get image urls inside tags with class=a1
let imgUrls2 = $(”.a1″).find(”img”).attrs(”src”)
```
Please check unit test codes for more usages
