# SwSelect

The Swift framework provides similar selector implementation to [jQuery](http://jquery.com). It could be used for parsing HTML easily with jQuery style queries. Currently, it supports only tag queries but no content manipulations. Most codes are ported from an Golang project called ["Cascadia"](https://github.com/andybalholm/cascadia).

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
