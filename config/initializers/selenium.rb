# We use the `webdrivers` gem to install and manage the web drivers for us. However, this doesn't
# support Linux on ARM64, but Chromium installs it by default, so we just use that. Otherwise we
# enable the gem.
# if RUBY_PLATFORM == "aarch64-linux"
#   unless File.file?("/usr/bin/chromedriver")
#     raise "Chromedriver missing, make sure you have Chromium installed"
#   end

#   Selenium::WebDriver::Chrome::Service.driver_path = "/usr/bin/chromedriver"
# else
#   require "webdrivers/chromedriver"
# end
