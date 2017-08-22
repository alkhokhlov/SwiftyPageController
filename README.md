# SwiftyPageController

[![CI Status](http://img.shields.io/travis/alkhokhlov/SwiftyPageController.svg?style=flat)](https://travis-ci.org/alkhokhlov/SwiftyPageController)
[![Version](https://img.shields.io/cocoapods/v/SwiftyPageController.svg?style=flat)](http://cocoapods.org/pods/SwiftyPageController)
[![License](https://img.shields.io/cocoapods/l/SwiftyPageController.svg?style=flat)](http://cocoapods.org/pods/SwiftyPageController)
[![Platform](https://img.shields.io/cocoapods/p/SwiftyPageController.svg?style=flat)](http://cocoapods.org/pods/SwiftyPageController)

## Description

**SwiftyPageController** will be helpful to use in many pages controller.

Advantages:
 - **customizable** animation transition;
 - **customizable** selecting buttons (you can implement them by your own)

## How to use

 - Add contanier view from storyboard or programmatically
 - Choose class for conatiner controller "SwiftyPageController"
 - In ViewController where you added container controller implement delegate from "SwiftyPageController"
 - Setup viewController
 - For selecting needed tab user method 

 ```swift
 func selectController(atIndex index: Int, animated: Bool)
```


## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

SwiftyPageController is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "SwiftyPageController"
```

## Author

alkhokhlov, alkhokhlovv@gmail.com

## License

SwiftyPageController is available under the MIT license. See the LICENSE file for more info.
