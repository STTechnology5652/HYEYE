Pod::Spec.new do |spec|

  spec.name         = "HYEYE"
  spec.version      = "0.0.1"
  spec.summary      = "HYEYE 说明."
  spec.description      = <<-DESC
  HYEYE long description of the pod here.
  DESC

  spec.homepage         = 'http://github.com/stephenchen/HYEYE'
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author             = { "stephenchen" => "stephen.chen@hellotalk.cn" }
  spec.ios.deployment_target = '12.0'

  spec.source       = { :git => "http://github/stephenchen/HYEYE.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source_files = 'HYEYE/{Public,Private}/**/*.{h,m,mm,c,cpp,swift}'
  # spec.exclude_files = "HYEYE/Exclude" #排除文件

  spec.project_header_files = 'HYEYE/Private/**/*.{h}'
  spec.public_header_files = 'HYEYE/Public/**/*.h' #此处放置组件的对外暴漏的头文件

  # ――― binary framework/lib ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #spec.vendored_frameworks = 'HYEYE/Private/**/*.framework'
  #spec.vendored_libraries = 'HYEYE/Private/**/*.a'

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # 放置 json,font,jpg,png等资源
  #  spec.resources = ["HYEYE/{Public,Private}/**/*.{xib}"]
  #  spec.resource_bundles = {
  #    'HYEYE' => ['HYEYE/Assets/*.xcassets', "HYEYE/{Public,Private}/**/*.{png,jpg,font,json}"]
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
   spec.dependency "IJKMediaFramework"
   spec.dependency "RxSwift", '6.8.0'
   spec.dependency "RxCocoa", '6.8.0'
   spec.dependency "SnapKit"


#   spec.subspec 'WithLoad' do |ss|
#       ss.source_files = 'YKHawkeye/Src/MethodUseTime/**/*{.h,.m}'
#       ss.pod_target_xcconfig = {
#         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YKHawkeyeWithLoad'
#       }
#       ss.dependency 'YKHawkeye/Core'
#       ss.vendored_frameworks = 'YKHawkeye/Framework/*.framework'
#     end

end
