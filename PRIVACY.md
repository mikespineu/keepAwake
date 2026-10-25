# keepAwake Privacy Policy

_Last updated: October 25, 2026_

keepAwake does not collect, store, transmit, or share any personal data.

- **No data collection.** The app has no accounts, analytics, crash reporting, advertising, or tracking.
- **No network access.** keepAwake never connects to the internet.
- **Local settings only.** Your preferences (battery threshold, display option, last custom duration) are saved on your Mac in the app's own sandboxed preferences and never leave your device.
- **Battery level.** The app reads the current battery level and power source locally to apply your "turn off when battery is low" rule. This information is not stored or sent anywhere.
- **Notifications.** If you allow notifications, they are created locally on your Mac.
- **AI agent integration.** If you connect Claude Code or Cursor, keepAwake adds its hooks and MCP server to those apps' settings files on your Mac. The hooks read only the event name and session id that the agent passes to them, never your prompts or tool input. What keepAwake is doing (whether it is on, and which agents hold it) is written to a local file, `~/Library/Application Support/keepAwake/status.json`, so the agent tools can read it. Nothing is sent anywhere.

If you have questions, open an issue at https://github.com/mikespineu/keepAwake/issues.
