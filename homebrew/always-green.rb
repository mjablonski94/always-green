cask "always-green" do
  version "1.0"
  # Replace :no_check with the real digest once a release DMG exists:
  #   shasum -a 256 AlwaysGreen-1.0.dmg
  sha256 :no_check

  url "https://github.com/mjablonski94/always-green/releases/download/v#{version}/AlwaysGreen-#{version}.dmg"
  name "Always Green"
  desc "Keeps your Mac active and your chat status green"
  homepage "https://github.com/mjablonski94/always-green"

  depends_on macos: ">= :sonoma"

  app "Always Green.app"
  binary "alwaysgreen"

  zap trash: [
    "~/Library/Application Support/Always Green"
  ]
end
