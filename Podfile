platform :ios, '8.0'
use_frameworks!

post_install do | installer |
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Cleanflight Configurator/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
class ::Pod::Generator::Acknowledgements
  def footnote_text
    "Icons designed by Freepik\nIcons made by Yannick, SimpleIcon, Daniel Bruce and Picol from www.flaticon.com licensed under CC BY 3.0"
  end
end

pod "DownPicker"
pod "Charts"
pod "SVProgressHUD"

target 'KIFTests', :exclusive => true do
    pod 'KIF', '~> 3.0', :configurations => ['Debug']
    pod 'KIF/IdentifierTests', :configurations => ['Debug']
end
