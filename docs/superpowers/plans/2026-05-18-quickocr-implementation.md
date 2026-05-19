# QuickOCR Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete macOS menu-bar screenshot OCR app (QuickOCR) with global hotkey capture, Apple Vision offline OCR, clipboard auto-copy, history, and settings.

**Architecture:** SwiftUI + AppKit hybrid. LSUIElement=YES for pure menu-bar app. Overlay NSWindow for capture region selection. Vision Framework for local OCR. UserDefaults for history/settings persistence.

**Tech Stack:** Swift 5, SwiftUI, AppKit, Vision Framework, Carbon Hotkey API, macOS 14+

---

## File Structure

```
QuickOCR/
├── QuickOCR.xcodeproj/
│   └── project.pbxproj
└── QuickOCR/
    ├── App/
    │   ├── QuickOCRApp.swift
    │   └── AppDelegate.swift
    ├── MenuBar/
    │   ├── MenuBarController.swift
    │   ├── StatusBarView.swift
    │   └── HistoryPopover.swift
    ├── OCR/
    │   ├── OCRService.swift
    │   ├── RecognitionManager.swift
    │   └── LanguageManager.swift
    ├── Capture/
    │   ├── CaptureService.swift
    │   ├── ScreenOverlayView.swift
    │   └── RegionSelector.swift
    ├── Views/
    │   ├── HistoryListView.swift
    │   ├── SettingsView.swift
    │   └── ToastView.swift
    ├── Models/
    │   ├── OCRResult.swift
    │   ├── CaptureHistory.swift
    │   └── AppSettings.swift
    ├── Utils/
    │   ├── KeyboardShortcutManager.swift
    │   ├── ClipboardManager.swift
    │   └── Formatters.swift
    ├── Assets.xcassets/
    │   ├── Contents.json
    │   └── AccentColor.colorset/
    │       └── Contents.json
    └── Info.plist
```

---

### Task 1: Create Project Directory Structure

**Files:**
- Create: `QuickOCR/` directory
- Create: `QuickOCR/QuickOCR.xcodeproj/` directory
- Create: `QuickOCR/QuickOCR/App/` directory
- Create: `QuickOCR/QuickOCR/MenuBar/` directory
- Create: `QuickOCR/QuickOCR/OCR/` directory
- Create: `QuickOCR/QuickOCR/Capture/` directory
- Create: `QuickOCR/QuickOCR/Views/` directory
- Create: `QuickOCR/QuickOCR/Models/` directory
- Create: `QuickOCR/QuickOCR/Utils/` directory
- Create: `QuickOCR/QuickOCR/Assets.xcassets/` directory
- Create: `QuickOCR/QuickOCR/Assets.xcassets/AccentColor.colorset/` directory

- [ ] **Create all directories**

```bash
mkdir -p QuickOCR/QuickOCR.xcodeproj
mkdir -p QuickOCR/QuickOCR/App
mkdir -p QuickOCR/QuickOCR/MenuBar
mkdir -p QuickOCR/QuickOCR/OCR
mkdir -p QuickOCR/QuickOCR/Capture
mkdir -p QuickOCR/QuickOCR/Views
mkdir -p QuickOCR/QuickOCR/Models
mkdir -p QuickOCR/QuickOCR/Utils
mkdir -p QuickOCR/QuickOCR/Assets.xcassets/AccentColor.colorset
```

---

### Task 2: Create Xcode Project File (project.pbxproj)

**Files:**
- Create: `QuickOCR/QuickOCR.xcodeproj/project.pbxproj`

The pbxproj file defines:
- 20 Swift source files + 1 asset catalog + 1 Info.plist
- macOS 14.0 deployment target
- LSUIElement support (AppDelegate-based, no SwiftUI WindowGroup)
- Debug & Release configurations
- Bundle ID: `com.quickocr.app`

---

### Task 3: Create Info.plist + Assets

**Files:**
- Create: `QuickOCR/QuickOCR/Info.plist` — LSUIElement=YES, permissions descriptions
- Create: `QuickOCR/QuickOCR/Assets.xcassets/Contents.json`
- Create: `QuickOCR/QuickOCR/Assets.xcassets/AccentColor.colorset/Contents.json`

---

### Task 4: Create Model Layer

**Files:**
- Create: `QuickOCR/QuickOCR/Models/OCRResult.swift`
- Create: `QuickOCR/QuickOCR/Models/CaptureHistory.swift`
- Create: `QuickOCR/QuickOCR/Models/AppSettings.swift`

**OCRResult.swift:** Codable struct with id (UUID), text (String), timestamp (Date), sourceImageRect (CGRect encoded as dictionary), language (String).

**CaptureHistory.swift:** ObservableObject with @Published entries array, max 20 items, save/load from UserDefaults.

**AppSettings.swift:** ObservableObject with @Published properties for shortcut, languages, autoCopy, notificationMode, launchAtLogin + UserDefaults persistence.

---

### Task 5: Create Utility Layer

**Files:**
- Create: `QuickOCR/QuickOCR/Utils/KeyboardShortcutManager.swift`
- Create: `QuickOCR/QuickOCR/Utils/ClipboardManager.swift`
- Create: `QuickOCR/QuickOCR/Utils/Formatters.swift`

**KeyboardShortcutManager.swift:** Carbon CGEventHotKey registration, callback mechanism, support for custom key codes and modifiers.

**ClipboardManager.swift:** NSPasteboard read/write, clear and copy text.

**Formatters.swift:** Text truncation (first N chars), date formatting for history display, size formatting for region dimensions.

---

### Task 6: Create OCR Layer

**Files:**
- Create: `QuickOCR/QuickOCR/OCR/OCRService.swift`
- Create: `QuickOCR/QuickOCR/OCR/RecognitionManager.swift`
- Create: `QuickOCR/QuickOCR/OCR/LanguageManager.swift`

**OCRService.swift:** Async function recognizeText(in: NSImage) -> String using VNRecognizeTextRequest. Configurable recognition level (.accurate), languages, language correction.

**RecognitionManager.swift:** Actor/class that manages recognition queue, prevents concurrent runs, reports progress via callback/closure.

**LanguageManager.swift:** Available language definitions (zh-Hans, en-US, ja-JP, ko-KR), display names, loading/saving selection.

---

### Task 7: Create Capture Layer

**Files:**
- Create: `QuickOCR/QuickOCR/Capture/CaptureService.swift`
- Create: `QuickOCR/QuickOCR/Capture/ScreenOverlayView.swift`
- Create: `QuickOCR/QuickOCR/Capture/RegionSelector.swift`

**CaptureService.swift:** Creates overlay window, manages capture lifecycle (start/end/cancel), captures selected region as NSImage via CGWindowListCreateImage.

**ScreenOverlayView.swift:** NSView subclass. Full-screen dim (alpha 0.3 black background). Draws selection rectangle with system blue border. Shows region dimensions label. Crosshair cursor.

**RegionSelector.swift:** NSView subclass handling mouseDown/mouseDragged/mouseUp. Tracks drag start/end points, notifies delegate on selection complete.

---

### Task 8: Create App Entry Point + Menu Bar

**Files:**
- Create: `QuickOCR/QuickOCR/App/QuickOCRApp.swift`
- Create: `QuickOCR/QuickOCR/App/AppDelegate.swift`
- Create: `QuickOCR/QuickOCR/MenuBar/MenuBarController.swift`
- Create: `QuickOCR/QuickOCR/MenuBar/StatusBarView.swift`
- Create: `QuickOCR/QuickOCR/MenuBar/HistoryPopover.swift`

**QuickOCRApp.swift:** @main entry using NSApplicationDelegateAdaptor. No WindowGroup scene (menu-bar only).

**AppDelegate.swift:** NSApplicationDelegate. Initializes MenuBarController; handles permissions dialog on first launch; connects all services.

**MenuBarController.swift:** NSStatusBar item with SF Symbol (text.viewfinder). Menu/popover management. Starts KeyboardShortcutManager on launch. Coordinates capture → OCR → clipboard → history → toast flow.

**StatusBarView.swift:** SwiftUI view for status bar button content. Adapts to dark/light mode.

**HistoryPopover.swift:** SwiftUI view for history popover. Shows list of recent OCR results in a small panel.

---

### Task 9: Create Views

**Files:**
- Create: `QuickOCR/QuickOCR/Views/HistoryListView.swift`
- Create: `QuickOCR/QuickOCR/Views/SettingsView.swift`
- Create: `QuickOCR/QuickOCR/Views/ToastView.swift`

**HistoryListView.swift:** List of OCRResult entries, each showing truncated text + timestamp. Click to re-copy. Clear all button.

**SettingsView.swift:** Form with sections: Shortcut (key recorder), Language (multi-select), General (launch at login, auto-copy toggle, notification mode picker).

**ToastView.swift:** Animated HUD-style overlay showing "Copied: {text}" with fade-in/out animation.

---

### Task 10: Wire Everything Together

- [ ] Verify all file references in project.pbxproj match actual files
- [ ] Verify all import statements across files
- [ ] Verify type/method consistency across all files
- [ ] Final review of the complete project

---

## Spec Coverage Check

| Spec Requirement | Task(s) |
|-----------------|---------|
| Global shortcut (⌘+⇧+O) | Task 5 (KeyboardShortcutManager), Task 8 (MenuBarController) |
| Dim overlay + crosshair + region select | Task 7 (ScreenOverlayView, RegionSelector, CaptureService) |
| Apple Vision OCR | Task 6 (OCRService) |
| Auto-copy to clipboard | Task 5 (ClipboardManager), Task 8 (flow coordination) |
| Menu bar icon + toast | Task 8 (MenuBarController, StatusBarView), Task 9 (ToastView) |
| Language settings | Task 6 (LanguageManager), Task 9 (SettingsView) |
| History (last 20) | Task 4 (CaptureHistory), Task 9 (HistoryListView) |
| Launch at login | Task 4 (AppSettings), Task 9 (SettingsView) |
| Custom shortcut | Task 4 (AppSettings), Task 5 (KeyboardShortcutManager) |
| Notification mode | Task 4 (AppSettings), Task 8 (flow coordination) |
| Permission guidance | Task 2 (Info.plist descriptions), Task 8 (AppDelegate) |
