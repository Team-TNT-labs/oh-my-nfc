# oh-my-nfc

A modern NFC tag reader & writer for iOS, built with SwiftUI.

Read, write, save, and manage NFC tags — all in one clean interface.

## Features

- **Read** — Scan any NDEF-compatible NFC tag and view its records instantly
- **Write** — Write text or URL data to writable NFC tags
- **Save** — Bookmark frequently used tags for quick one-tap writing
- **History** — Automatically logs every scan with timestamps
- **12 Languages** — English, Korean, Japanese, Chinese (Simplified/Traditional), German, Spanish, French, Italian, Portuguese (BR), Russian, Arabic

## Requirements

- iOS 18.0+
- iPhone 7 or later (NFC-capable device)
- Xcode 16+

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| NFC | CoreNFC (NDEF) |
| State | `@Observable` (Observation framework) |
| Persistence | UserDefaults (JSON) |
| Dependencies | None — pure Apple frameworks |

## Project Structure

```
oh-my-nfc/
├── oh_my_nfcApp.swift          # Entry point
├── ContentView.swift           # Tab navigation (NFC / Saved / History)
├── NFCManager.swift            # Core NFC read/write logic
├── SavedTagStore.swift         # Saved tags persistence
├── Models/
│   ├── NFCRecord.swift         # Scanned record model
│   └── SavedTag.swift          # Saved tag model
├── Views/
│   ├── NFCView.swift           # Combined read & write screen
│   ├── SavedTagsView.swift     # Saved tags management
│   ├── HistoryView.swift       # Scan history
│   └── SectionTitle.swift      # Shared UI components
└── Localizable.xcstrings       # 12-language localization
```

## Getting Started

```bash
git clone https://github.com/Team-TNT-labs/oh-my-nfc.git
```

Open `oh-my-nfc.xcodeproj` in Xcode, select a physical device, and run.

> NFC requires a physical iPhone — the Simulator does not support CoreNFC.

## License

MIT
