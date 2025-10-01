# Uncomment the next line to define a global platform for your project
platform :ios, '18.5'

target 'Scan OCR KTP' do
  use_frameworks! :linkage => :static

  # Pods for Scan OCR KTP
  pod 'GoogleMLKit/TextRecognition'

  target 'Scan OCR KTPTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'Scan OCR KTPUITests' do
    # Pods for testing
  end

end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.5'
      config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '15.5'
      config.build_settings['XROS_DEPLOYMENT_TARGET'] = '2.5'

      # For Apple Silicon development, exclude x86_64 from simulator builds
      # This ensures consistency between main app and pod architectures
      config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'x86_64'
      config.build_settings['EXCLUDED_ARCHS[sdk=xrsimulator*]'] = 'x86_64'

      # Ensure we only build for active architecture in debug for faster builds
      if config.name == 'Debug'
        config.build_settings['ONLY_ACTIVE_ARCH'] = 'YES'
      end

      # Fix potential linking issues with GoogleMLKit
      config.build_settings['ENABLE_BITCODE'] = 'NO'
      config.build_settings['BUILD_LIBRARY_FOR_DISTRIBUTION'] = 'NO'

      # Additional GoogleMLKit simulator fixes
      if target.name.include?('MLKit') || target.name.include?('GoogleMLKit')
        config.build_settings['EXCLUDED_ARCHS[sdk=iphonesimulator*]'] = 'i386 x86_64'
        config.build_settings['VALID_ARCHS[sdk=iphonesimulator*]'] = 'arm64'
      end
    end
  end

  # Fix CocoaPods embed frameworks script unbound variable issue
  installer.pods_project.targets.each do |target|
    if target.respond_to?(:product_type) and target.product_type == "com.apple.product-type.bundle"
      target.build_configurations.each do |config|
        config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
      end
    end
  end

  # Fix unbound variable error in frameworks script
  frameworks_script_path = 'Pods/Target Support Files/Pods-Scan OCR KTP/Pods-Scan OCR KTP-frameworks.sh'
  if File.exist?(frameworks_script_path)
    script_content = File.read(frameworks_script_path)
    # Fix: initialize source variable and add else clause
    fixed_content = script_content.gsub(
      /install_framework\(\)\n\{\n  if \[ -r "\$\{BUILT_PRODUCTS_DIR\}\/\$1" \]; then\n    local source=/,
      "install_framework()\n{\n  local source=\"\"\n  if [ -r \"\${BUILT_PRODUCTS_DIR}/\$1\" ]; then\n    source="
    ).gsub(
      /  elif \[ -r "\$\{BUILT_PRODUCTS_DIR\}\/\$\(basename "\$1"\)" \]; then\n    local source=/,
      "  elif [ -r \"\${BUILT_PRODUCTS_DIR}/\$(basename \"\$1\")\" ]; then\n    source="
    ).gsub(
      /  elif \[ -r "\$1" \]; then\n    local source="([^"]+)"\n  fi\n\n  local destination=/,
      "  elif [ -r \"\$1\" ]; then\n    source=\\1\n  else\n    echo \"error: framework not found: \$1\"\n    return 1\n  fi\n\n  local destination="
    )
    File.write(frameworks_script_path, fixed_content)
  end
end