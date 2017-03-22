#
# Be sure to run `pod lib lint Logsene.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "Logsene"
  s.version          = "1.0.1"
  s.summary          = "Logsene is ELK as a Service. This library lets you collect mobile analytics and log data from your iOS applications using Logsene."

  s.description      = <<-DESC
  Logsene is ELK as a Service. This library lets you collect mobile analytics and log data from your iOS applications using Logsene. If you don't have a Logsene account, you can register for free to get your app token.

  The focus of the library is mobile analytics, but it can be used for centralized logging as well.
                       DESC

  s.homepage         = "https://github.com/sematext/sematext-logsene-ios"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'Apache 2.0'
  s.author           = { "Sematext Group, Inc." => "pods@sematext.com" }
  s.source           = { :git => "https://github.com/sematext/sematext-logsene-ios.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/sematext'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  # s.resource_bundles = {
  #   'Logsene' => ['Pod/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.dependency 'SQLite.swift', '~> 0.11.2'
end
