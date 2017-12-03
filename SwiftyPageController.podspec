#
# Be sure to run `pod lib lint SwiftyPageController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SwiftyPageController'
  s.version          = '0.1.2'
  s.summary          = 'SwiftyPageController will be helpful to use in many pages controller.'
  s.description      = 'SwiftyPageController is a full customizable pages controller

Advantages:
 - customizable animation transition;
 - customizable selecting buttons (you can implement them by your own)'

  s.homepage         = 'https://github.com/alkhokhlov/SwiftyPageController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'alkhokhlov' => 'alkhokhlovv@gmail.com' }
  s.source           = { :git => 'https://github.com/alkhokhlov/SwiftyPageController.git', :tag => s.version.to_s }

  s.ios.deployment_target = '11.0'

  s.source_files = 'SwiftyPageController/Classes/**/*'
  
end
