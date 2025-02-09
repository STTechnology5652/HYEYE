Pod::Spec.new do |spec|

  spec.name         = "HYPlayModule"
  spec.version      = "0.0.1"
  spec.summary      = "HYPlayModule 说明."
  spec.description      = <<-DESC
  HYPlayModule long description of the pod here.
  DESC

  spec.homepage         = 'http://github.com/defualt_author/HYPlayModule'
  spec.license      = { :type => "MIT", :file => "FILE_LICENSE" }
  spec.author             = { "defualt_author" => "defualt_email" }
  spec.ios.deployment_target = '12.0'

  spec.source       = { :git => "http://github/defualt_author/HYPlayModule.git", :tag => "#{spec.version}" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  spec.source_files = 'HYPlayModule/{Public,Private}/**/*.{h,m,mm,c,cpp,swift}'
  # spec.exclude_files = "HYPlayModule/Exclude" #排除文件

  spec.project_header_files = 'HYPlayModule/Private/**/*.{h}'
  spec.public_header_files = 'HYPlayModule/Public/**/*.h' #此处放置组件的对外暴漏的头文件

  # ――― binary framework/lib ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #spec.vendored_frameworks = 'HYPlayModule/Private/**/*.framework'
  #spec.vendored_libraries = 'HYPlayModule/Private/**/*.a'

  # ――― Resources ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  # 放置 json,font,jpg,png等资源
  #  spec.resources = ["HYPlayModule/{Public,Private}/**/*.{xib}"]
  #  spec.resource_bundles = {
  #    'HYPlayModule' => ['HYPlayModule/Assets/*.xcassets', "HYPlayModule/{Public,Private}/**/*.{png,jpg,font,json}"]
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

#   spec.subspec 'WithLoad' do |ss|
#       ss.source_files = 'YKHawkeye/Src/MethodUseTime/**/*{.h,.m}'
#       ss.pod_target_xcconfig = {
#         'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) YKHawkeyeWithLoad'
#       }
#       ss.dependency 'YKHawkeye/Core'
#       ss.vendored_frameworks = 'YKHawkeye/Framework/*.framework'
#     end

spec.dependency "STComponentTools/STRouter"
spec.dependency "STModuleService.swift"  #swift 服务中间件
spec.dependency 'HYAllBase'
end
