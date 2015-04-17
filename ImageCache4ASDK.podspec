Pod::Spec.new do |s|
  s.name         = "ImageCache4ASDK"
  s.version      = "0.0.1"
  s.summary      = "Yet another image cache for AsyncDisplayKit"
  s.homepage     = "https://github.com/Pikaurd/ImageCache4ASDK"
  s.license      = "MIT"
  s.author             = "Pikaurd"
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/Pikaurd/ImageCache4ASDK.git", :tag => "#{s.version}" }
  s.source_files  = "ImageCache4ASDK", "ImageCache4ASDK/**/*.{h, swift}"
  s.requires_arc = true

  s.dependency "AsyncDisplayKit", "~> 1.1"

end
