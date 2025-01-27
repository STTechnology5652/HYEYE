Pod::Spec.new do |spec|

  spec.name         = "HYBaseUI"
  spec.version      = "0.0.1"
  spec.summary      = "HYBaseUI 说明."
  spec.description      = <<-DESC
  HYBaseUI long description of the pod here.
  DESC

  spec.homepage         = 'http://github.com/stephenchen/HYBaseUI'
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "stephenchen" => "stephen.chen@hellotalk.cn" }
  spec.ios.deployment_target = '9.0'

  spec.source       = { :git => "http://github/stephenchen/HYBaseUI.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source_files = 'HYBaseUI/{Public,Private}/**/*.{h,m,mm,c,cpp,swift}'
  # spec.exclude_files = "HYBaseUI/Exclude" #排除文件

  spec.project_header_files = 'HYBaseUI/Private/**/*.{h}'
  spec.public_header_files = 'HYBaseUI/Public/**/*.h' #此处放置组件的对外暴漏的头文件

  # ――― binary framework/lib ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #spec.vendored_frameworks = 'HYBaseUI/Private/**/*.framework'
  #spec.vendored_libraries = 'HYBaseUI/Private/**/*.a'

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # 放置 json,font,jpg,png等资源
  #  spec.resources = ["HYBaseUI/{Public,Private}/**/*.{xib}"]
  #  spec.resource_bundles = {
  #    'HYBaseUI' => ['HYBaseUI/Assets/*.xcassets', "HYBaseUI/{Public,Private}/**/*.{png,jpg,font,json}"]
  #  }


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.framework  = "SomeFramework"
  # spec.frameworks = "SomeFramework", "AnotherFramework"
  # spec.library   = "iconv"
  # spec.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # spec.requires_arc = true

  # spec.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }

  # 其他依赖pod
  # spec.dependency "XXXXXXXX"
  
  spec.dependency "Then"
  spec.dependency "SnapKit"
  spec.dependency "Localize-Swift"
  spec.dependency "CYLTabBarController"

#   spec.subspec 'WithLoad' do |ss|
#       ss.source_files = 'YKHawkeye/Src/MethodUseTime/**/*{.h,.m}'
#       ss.pod_target_xcconfig = {
#         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YKHawkeyeWithLoad'
#       }
#       ss.dependency 'YKHawkeye/Core'
#       ss.vendored_frameworks = 'YKHawkeye/Framework/*.framework'
#     end

end
