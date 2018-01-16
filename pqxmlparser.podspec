#
#  Be sure to run `pod spec lint pod-auth-swift.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name         = "pqxmlparser"
  s.version      = "1.0.0"
  s.summary      = "Convenient XML parser/wrapper for Objective-C based on libxml2"
  s.homepage     = "https://github.com/plexteq/PQXMLParser.git"
  s.license      = { :type => "BSD", :file => "LICENSE" }
  s.author             = { "Plexteq" => "github@plexteq.com" }
  
  s.source       = { 
  :git => "https://github.com/plexteq/PQXMLParser.git", 
  :tag => "1.0.0" 
  }
  
  s.platform     = :ios, '9.0'
  s.vendored_frameworks = 'bin/PQXMLParserFramework.framework'
  s.requires_arc = true

end
