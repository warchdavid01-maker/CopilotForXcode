### GitHub Copilot for Xcode 0.36.0

**🚀 Highlights**

* Introduced a new chat setting "**Response Language**" under **Advanced** settings to customize the natural language used in chat replies.
* Enabled support for custom instructions defined in _.github/copilot-instructions.md_ within your workspace.
* Added support for premium request handling.

**💪 Improvements**

* Performance: Improved UI responsiveness by lazily restoring chat history.
* Performance: Fixed lagging issue when pasting large text into the chat input.
* Performance: Improved project indexing performance.

**🛠️ Bug Fixes**

* Don't trigger / (slash) commands when pasting a file path into the chat input.
* Adjusted terminal text styling to align with Xcode’s theme.
