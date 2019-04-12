##
# 1. Step
# Tapkey provides the app sdk pods via a private PodSpec repository.
# Add the tapkey podspec and cocoapods podspec repo as source to your Podfile
source 'https://github.com/tapkey/TapkeyCocoaPods'
source 'https://github.com/CocoaPods/Specs.git'
#
###

project 'SdkSample'
platform :ios, '9.0'
use_frameworks!

target 'SdkSample' do
    
    ##
    # 2. Step
    # Add the 'TapkeyMobileLib' as dependency to the target app
    pod 'TapkeyMobileLib', '1.15.12.0'

    #
    ##
    
    pod 'Auth0', '1.14.2'
    
end
