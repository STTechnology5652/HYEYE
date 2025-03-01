Pod::Spec.new do |spec|

  spec.name         = "HYAllBase"
  spec.version      = "0.0.1"
  spec.summary      = "HYAllBase 说明."
  spec.description      = <<-DESC
  HYAllBase long description of the pod here.
  DESC

  spec.homepage         = 'http://github.com/stephenchen/HYAllBase'
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "stephenchen" => "stephen.chen@hellotalk.cn" }
  spec.ios.deployment_target = '12.0'

  spec.source       = { :git => "http://github/stephenchen/HYAllBase.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source_files = 'HYAllBase/{Public,Private}/**/*.{h,m,mm,c,cpp,swift}'
  # spec.exclude_files = "HYAllBase/Exclude" #排除文件

  spec.project_header_files = 'HYAllBase/Private/**/*.{h}'
  spec.public_header_files = 'HYAllBase/Public/**/*.h' #此处放置组件的对外暴漏的头文件

  # ――― binary framework/lib ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #spec.vendored_frameworks = 'HYAllBase/Private/**/*.framework'
  #spec.vendored_libraries = 'HYAllBase/Private/**/*.a'

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # 放置 json,font,jpg,png等资源
  #  spec.resources = ["HYAllBase/{Public,Private}/**/*.{xib}"]
  #  spec.resource_bundles = {
  #    'HYAllBase' => ['HYAllBase/Assets/*.xcassets', "HYAllBase/{Public,Private}/**/*.{png,jpg,font,json}"]
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
   spec.dependency "RxSwift", '6.8.0'
   spec.dependency "RxCocoa", '6.8.0'
   spec.dependency "RxRelay", '6.8.0'
   spec.dependency "Then", '3.0.0'
   spec.dependency "SnapKit", '5.7.1'
   spec.dependency "Localize-Swift"
   spec.dependency "CYLTabBarController", '1.29.2'
   spec.dependency "MTCategoryComponent/UIKit/UIViewController"
   spec.dependency "MTCategoryComponent/UIKit/UIColor"
   spec.dependency "MTCategoryComponent/UIKit/UIImage"

   spec.dependency "HYBaseUI"
   spec.dependency "HYResource"
   
   spec.dependency "STComponentTools", '0.0.5'
   spec.dependency "HYRouterServiceDefine"
   

#   spec.subspec 'WithLoad' do |ss|
#       ss.source_files = 'YKHawkeye/Src/MethodUseTime/**/*{.h,.m}'
#       ss.pod_target_xcconfig = {
#         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YKHawkeyeWithLoad'
#       }
#       ss.dependency 'YKHawkeye/Core'
#       ss.vendored_frameworks = 'YKHawkeye/Framework/*.framework'
#     end

end
