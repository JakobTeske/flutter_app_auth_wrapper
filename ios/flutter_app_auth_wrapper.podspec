#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#
Pod::Spec.new do |s|
  s.name             = 'flutter_app_auth_wrapper'
  s.version          = '0.0.1'
  s.summary          = 'App-Auth wrapper for flutter.'
  s.description      = <<-DESC
App-Auth wrapper for flutter.
                       DESC
  s.homepage         = 'http://example.com'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Your Company' => 'email@example.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.dependency 'Flutter'
  s.dependency 'AppAuth'

  s.ios.deployment_target = '10.0'

end
