#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_sequencer.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_sequencer'
  s.version          = '0.4.4'
  s.summary          = 'A Flutter plugin for sequencing audio with SFZ and SF2 sound fonts.'
  s.description      = <<-DESC
Use flutter_sequencer to build note sequences and play them back with SFZ or SF2 instruments.
                       DESC
  s.homepage         = 'https://github.com/mikeperri/flutter_sequencer'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Mike Perri' => 'michaeljperri@gmail.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.resource_bundles = {
    'flutter_sequencer' => ['prepare.sh']
  }
  s.dependency 'Flutter'
  s.static_framework = true
  s.platform = :ios, '13.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64,i386',
    'ENABLE_TESTABILITY' => 'YES',
    'STRIP_STYLE' => 'non-global',
    'HEADER_SEARCH_PATHS' => '$(PODS_TARGET_SRCROOT)/third_party/sfizz/src',
    'USER_HEADER_SEARCH_PATHS' => '"${PROJECT_DIR}/.."/Classes/CallbackManager/* "${PROJECT_DIR}/.."/Classes/Scheduler/* "${PROJECT_DIR}/.."/Classes/AudioUnit/Sfizz/SfizzDSPKernelAdapter.h',
    'CLANG_CXX_LANGUAGE_STANDARD' => 'c++2a',
    'CLANG_CXX_LIBRARY' => 'libc++'
  }
  s.user_target_xcconfig = { 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'arm64' }
  s.swift_version = '5.0'
  s.library = 'c++'
  s.prepare_command = './prepare.sh'
  s.vendored_libraries = 'third_party/sfizz/build/libsfizz_fat.a'
end
