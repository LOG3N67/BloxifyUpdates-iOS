# Bloxify Updates — iPhone 7 App

Native SwiftUI status app for iOS 15+.

- Check Now refreshes published updates from https://bloxify-updates.vercel.app/api/check
- Shows CapCut public status, Bloxify Studio health, and recent updates
- Does not read or expose Gmail

GitHub Actions builds an unsigned IPA with an Apple-hosted macOS runner. Download the workflow artifact, unzip it, and sideload the .ipa using Sideloadly (which signs it with your own Apple account). No credentials belong in this repository.
