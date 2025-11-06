#
# Be sure to run `pod lib lint McccAlarm.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'McccAlarm'
  s.version          = '0.1.0'
  s.summary          = 'A short description of McccAlarm.'

  s.homepage         = 'https://github.com/iAmMccc/McccAlarm'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'iAmMccc' => 'Mccc' }
  s.source           = { :git => 'https://github.com/iAmMccc/McccAlarm.git', :tag => s.version.to_s }

  s.ios.deployment_target = '26.0'

  s.source_files = 'McccAlarm/Classes/**/*'

end
