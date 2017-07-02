platform :ios, '8.0'
use_frameworks!
plugin 'cocoapods-acknowledgements', :settings_bundle => true

def common_pods
    pod 'DownPicker'
    pod 'Charts', '~> 2.0'
    pod 'SVProgressHUD'
    pod 'SwiftSVG'
    pod 'Firebase/Core'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'CocoaAsyncSocket'
#pod "InAppSettingsKit"
end

target 'MobileFlight' do
  post_install do | installer |
    # Fix for "does not contain bitcode. You must rebuild it with bitcode enabled (Xcode setting ENABLE_BITCODE), obtain an updated library from the vendor, or disable bitcode for this target. for architecture arm64"
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
  end

  common_pods
end

target 'KIFTests' do
    pod 'KIF', '~> 3.0', :configurations => ['Debug']
    pod 'KIF/IdentifierTests', :configurations => ['Debug']
    common_pods
end

target 'MobileFlightTests' do
    common_pods
end

