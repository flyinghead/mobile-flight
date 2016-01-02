use_frameworks!

post_install do | installer |
    require 'fileutils'
    FileUtils.cp_r('Pods/Target Support Files/Pods/Pods-Acknowledgements.plist', 'Cleanflight Configurator/Settings.bundle/Acknowledgements.plist', :remove_destination => true)
end
class ::Pod::Generator::Acknowledgements
  def footnote_text
    "Icons designed by Freepik\nIcon made by Yannick from www.flaticon.com licensed under CC BY 3.0"
  end
end

pod "DownPicker"
pod "Charts"
pod "SVProgressHUD"
