# LOG AI for iPhone 7

An original iOS 15+ SwiftUI chat app with live AI completions from OpenRouter's free model router.

Features:
- Actual network chat completions, not simulated responses
- Chat history stored locally on iPhone (UserDefaults)
- API key stored in iOS Keychain (never included in source code or committed)
- OpenRouter model hard-set to `openrouter/free`; provider can enforce rate limits
- Error messages for network/API failures
- New conversation button and settings panel

**To use:** Obtain your own free API key from https://openrouter.ai/settings/keys (parental help where appropriate). Open app → gear → paste key → Save. Never post the key in issues or chats.

**Build:** GitHub Actions macOS job packages an unsigned `LOGAI-unsigned.ipa` under the `LOGAI-IPA` artifact. Use Sideloadly to sign/install on the iPhone. 

The app is not operated by or affiliated with OpenAI, and it does not use ChatGPT's model or account. OpenRouter sends prompts to third-party AI providers. Free capacity may be limited.
