Pod::Spec.new do |s|

  s.name         = "SwSelect"
  s.version      = "0.0.1"
  s.summary      = "This framework could be used for parsing HTML easily with jQuery style queries."

  s.description  = <<-DESC
# SwSelect
This Swift framework provides similar selector implementation to [jQuery](http://jquery.com). It could be used for parsing HTML easily with jQuery style queries. Currently, it supports only tag queries but no content manipulations. Most codes are ported from an Golang project called ["Cascadia"](https://github.com/andybalholm/cascadia).

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

                   DESC

  s.homepage     = "https://github.com/julianshen/SwSelect"
  s.license      = "MIT"
  s.author             = { "Julian Shen" => "julianshen@gmail.com" }
  s.source       = { :git => "https://github.com/julianshen/SwSelect.git", :tag => "0.0.1" }

  s.source_files  = "**/*.swift"
  s.library = "xml2"
  s.requires_arc = true
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'
end
