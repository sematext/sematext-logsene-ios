#
# Be sure to run `pod lib lint Logsene.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'Logsene'
  s.version          = '1.1.0'
  s.summary          = 'Sematext Cloud Logs is ELK as a Service. This library lets you collect mobile analytics and log data from your iOS applications.'

  s.description      = <<-DESC
  Sematext Cloud Logs is ELK as a Service. This library lets you collect mobile analytics and log data from your iOS applications using Sematext Cloud Logs. If you don't have a Sematext Cloud account, you can register for free to get your app token.

  The focus of the library is mobile analytics, but it can be used for centralized logging as well.
                       DESC
  
  s.homepage         = 'https://github.com/sematext/sematext-logsene-ios'
  s.license          = { :type => 'Apache 2.0', :file => 'LICENSE.md' }
  s.author           = { 'Sematext Group, Inc.' => 'pods@sematext.com' }
  s.source           = { :git => 'https://github.com/sematext/sematext-logsene-ios.git', :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/sematext'

  s.ios.deployment_target = '8.0'
  s.source_files = 'Logsene/Classes/**/*'
  
  s.swift_versions = ['4.0', '4.1', '4.2', '5.0', '5.1', '5.2']
  
  s.dependency 'SQLite.swift', '~> 0.12.2'
end
