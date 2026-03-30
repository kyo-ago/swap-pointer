cask "swap-pointer" do
  version :latest
  sha256 :no_check

  url "https://github.com/kyo-ago/swap-pointer/releases/latest/download/SwapPointer-latest-macOS.zip"
  name "SwapPointer"
  desc "Multi-mouse cursor switching utility for macOS"
  homepage "https://github.com/kyo-ago/swap-pointer"

  binary "SwapPointer"

  zap trash: [
    "~/Library/Preferences/com.kyo-ago.SwapPointer.plist",
  ]
end
