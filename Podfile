platform :ios, '8.0'
use_frameworks!
plugin 'cocoapods-acknowledgements', :settings_bundle => true

target 'Cleanflight Configurator' do
  post_install do | installer |
  #    require 'fileutils'
  #    FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Cleanflight Configurator/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
    # Fix for "does not contain bitcode. You must rebuild it with bitcode enabled (Xcode setting ENABLE_BITCODE), obtain an updated library from the vendor, or disable bitcode for this target. for architecture arm64"
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end
    end
  end
  # FIXME
  class ::Pod::Generator::Acknowledgements
    def footnote_text
      "Icons designed by Freepik\nIcons made by Yannick, SimpleIcon, Daniel Bruce and Picol from www.flaticon.com licensed under CC BY 3.0\nStaticDataTableViewController Copyright 2015 Peter Paulis - min60 s.r.o. (min60.com)\nInAppSettingsKit Copyright (c) 2009-2014: Luc Vandal, Edovia Inc., http://www.edovia.com\nOrtwin Gentz, FutureTap GmbH, http://www.futuretap.com\nAll rights reserved.\nThis code is licensed under the BSD license that is available at: http://www.opensource.org/licenses/bsd-license.php"
    end
  end

  pod "DownPicker"
  pod "Charts", "2.3.1"
  pod "SVProgressHUD"
  #pod "InAppSettingsKit"
  pod "SwiftSVG"
  pod 'Firebase/Core'

  target 'KIFTests' do
    pod 'KIF', '~> 3.0', :configurations => ['Debug']
    pod 'KIF/IdentifierTests', :configurations => ['Debug']
  end
end

