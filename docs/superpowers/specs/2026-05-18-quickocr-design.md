# QuickOCR - macOS Menu Bar Screen Text Extractor

## Overview

A lean macOS menu bar application that captures screen regions and extracts text via on-device OCR. Press a global shortcut, select an area, and the recognized text is automatically copied to the clipboard.

**Target price**: $3.99 one-time purchase (launch promo $2.99)

---

## Architecture

### Technology Stack

| Component | Choice |
|-----------|--------|
| Framework | SwiftUI + AppKit |
| OCR Engine | Apple Vision Framework (`VNRecognizeTextRequest`) |
| Deployment Target | macOS 14 Sonoma |
| Distribution | Mac App Store |
| Target Bundle Size | < 3MB |
| Target Memory | < 30MB |

### Project Structure

```
QuickOCR/
├── App/
│   ├── QuickOCRApp.swift          // @main entry, LSUIElement menu-bar app
│   └── AppDelegate.swift          // NSApplicationDelegate lifecycle
├── MenuBar/
│   ├── MenuBarController.swift    // Menu bar icon + dropdown management
│   ├── StatusBarView.swift        // SwiftUI status icon view
│   └── HistoryPopover.swift       // History popover panel
├── OCR/
│   ├── OCRService.swift           // Vision framework recognition
│   ├── RecognitionManager.swift   // Recognition queue and dedup
│   └── LanguageManager.swift      // Multi-language config (zh, en, ja, ko)
├── Capture/
│   ├── CaptureService.swift       // Screen capture via CGDisplay + overlay window
│   ├── ScreenOverlayView.swift    // Full-screen dim overlay with crosshair
│   └── RegionSelector.swift       // Drag-select region controller
├── Views/
│   ├── HistoryListView.swift      // History list view
│   ├── SettingsView.swift         // Settings panel (shortcut, language, auto-start, notification mode)
│   └── ToastView.swift            // Transient toast overlay
├── Models/
│   ├── OCRResult.swift            // Recognition result model
│   ├── CaptureHistory.swift       // History persistence model
│   └── AppSettings.swift          // UserDefaults-backed settings
└── Utils/
    ├── KeyboardShortcutManager.swift  // Global hotkey via Carbon API
    ├── ClipboardManager.swift         // Clipboard read/write
    └── Formatters.swift               // Text formatting helpers
```

---

## Core Flow

```
Global shortcut (⌘+⇧+O or custom)
    │
    ▼
CaptureService.captureRegion()
    │  Creates overlay window (dim alpha 0.3, crosshair cursor)
    ▼
User drags to select → region coordinates captured
    │
    ▼
CaptureService.captureRect(rect) → NSImage
    │
    ▼
OCRService.recognize(image) → async, Vision framework
    │
    ▼
ClipboardManager.copy(text)
    │
    ▼
Status bar toast: "✅ Copied: {text preview}"
    │
    ▼
History persisted to UserDefaults (max 20 entries)
```

---

## V1.0 Feature Set

### P0 (MVP)
- [x] Global shortcut triggers screen capture
- [x] Dim overlay + crosshair cursor + drag-select region
- [x] Apple Vision OCR (offline, local)
- [x] Auto-copy to clipboard on recognition
- [x] Menu bar icon + status toast
- [x] Language settings (Chinese + English)

### P1 (V1.0 includes)
- [x] History (last 20 entries, persisted)
- [x] Launch at login
- [x] Customizable shortcut
- [x] Notification/sound/silent mode toggle

### P2 (Post-V1.0 — NOT in scope)
- [x] Batch recognition (drag multiple images)
- [x] Post-recognition text editing
- [x] Auto-detect selected Finder images

### Explicitly excluded from V1.0
- Image editing/annotation
- Translation
- AI summarization
- Cloud sync

---

## UI/UX Design

### Design Language
- **Style**: Minimal, native macOS feel — consistent with system Screenshot.app
- **Color**: Follows system light/dark appearance
- **Font**: SF Pro (system default)
- **Icon**: SF Symbol `text.viewfinder`
- **LSUIElement**: YES (pure menu bar app, no Dock icon)

### Capture Region Interaction
- Shortcut → full-screen dim overlay (alpha 0.3)
- Cursor changes to crosshair
- Drag to select → release → recognition starts
- Selection border uses system blue (`NSColor.keyboardFocusColor`)
- Corner label shows region dimensions (e.g. "320 × 240")
- Press Escape to cancel

### Notification Modes
| Mode | Behavior | Default |
|------|----------|---------|
| Silent | Copy to clipboard + menu bar flash | ✅ Default |
| Notification | macOS notification with first 50 chars | Optional |
| Sound | Short system sound | Optional |

### Animations
- Selection rectangle follows cursor in real-time
- Menu bar icon briefly rotates/flashes during recognition (< 2s)
- Toast fades in/out on completion

---

## Data Models

### OCRResult
```
- id: UUID
- text: String
- timestamp: Date
- sourceImageRect: CGRect
- language: String
```

### CaptureHistory
```
- entries: [OCRResult]
- maxCount: 20
- persistence: UserDefaults (JSON-encoded)
```

### AppSettings
```
- shortcutKeyCode: Int (default kVK_ANSI_O)
- shortcutModifiers: Int (default cmd+shift)
- recognitionLanguages: [String] (default ["zh-Hans", "en-US"])
- autoCopy: Bool (default true)
- notificationMode: enum { silent, notification, sound }
- launchAtLogin: Bool (default false)
```

---

## Permissions

| Permission | Purpose | Required |
|------------|---------|----------|
| Screen Recording | Capture screen region for OCR | ✅ First-launch prompt |
| Accessibility | Register global hotkey | ✅ First-launch prompt |

Both permissions are guided via a first-launch dialog with clear instructions.

**Note**: No network permission, no file access permission. All OCR runs on-device.

---

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| OCR Engine | Apple Vision Framework | Free, offline, multi-language, excellent accuracy |
| Capture Method | CGDisplay + NSWindow overlay | Native, smooth, no external dependencies |
| Hotkey Registration | Carbon API (CGEventHotKey) | Industry standard, reliable |
| History Storage | UserDefaults + JSON | Simple, reliable, no database needed |
| Default Notification | Silent mode + menu bar flash | Non-intrusive, respects user workflow |
| Deployment Target | macOS 14 Sonoma | Latest Vision API features, modern SwiftUI |

---

## Pricing

- **Launch promo**: $2.99 (first 7 days)
- **Standard price**: $3.99 one-time purchase
- **Anchor comparison**: TextSniper at $7.99 — QuickOCR at half the price

---

## Development Order

1. Day 1: Project structure + menu bar framework + global shortcut
2. Day 2: Capture overlay (dim, crosshair, region selection)
3. Day 3: Apple Vision OCR integration
4. Day 4: Clipboard copy + menu bar toast animation
5. Day 5: History panel + persistence
6. Day 6: Settings panel (shortcut, language, auto-start, notification mode)
7. Day 7: Permission guidance dialogs
8. Day 8: UI polish + animation + multi-language testing
9. Day 9: Bug fixes + edge cases (empty region, recognition failure)
10. Day 10: Screenshots + metadata + App Store submission
