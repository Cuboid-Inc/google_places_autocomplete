#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint google_places_autocomplete.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'google_places_autocomplete'
  s.version          = '1.0.0'
  s.summary          = 'Google Places Autocomplete for Flutter'
  s.description      = <<-DESC
Seamlessly integrate Google Places API into your Flutter app with this package.
                       DESC
  s.homepage         = 'https://github.com/Cuboid-Inc/google_places_autocomplete'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Cuboid Inc' => 'info@cuboid.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.dependency 'GooglePlaces', '9.2.0'
  s.platform = :ios, '14.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.static_framework = true
  s.swift_version = '5.0'
end
