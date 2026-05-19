# FindDup Implementation Plan

> **For agentic workers:** Steps use checkbox `- [ ]` syntax for tracking.

**Goal:** Build a macOS duplicate file finder app (FindDup) with folder scanning, MD5+SHA256 dedup, and batch trash deletion.

**Architecture:** SwiftUI + MVVM + Actors. Core layer uses Swift Actors for thread-safe file I/O and hashing. ViewModels are `@MainActor` ObservableObjects. Views observe ViewModels and render three states: idle/scanning/completed.

**Tech Stack:** SwiftUI, macOS 14+, CommonCrypto (via Bridging Header)

---

## File Structure

```
FindDup/
├── FindDup.xcodeproj/
│   └── project.pbxproj
└── FindDup/
    ├── FindDup.entitlements
    ├── Info.plist
    ├── Assets.xcassets/
    │   ├── Contents.json
    │   ├── AccentColor.colorset/
    │   │   └── Contents.json
    │   └── AppIcon.appiconset/
    │       └── Contents.json
    ├── App/
    │   ├── FindDupApp.swift
    │   └── ContentView.swift
    ├── Core/
    │   ├── FileInfo.swift
    │   ├── FileScanner.swift
    │   ├── HashCalculator.swift
    │   ├── DuplicateFinder.swift
    │   ├── DuplicateGroup.swift
    │   └── FileDeleter.swift
    ├── ViewModel/
    │   ├── ScanViewModel.swift
    │   ├── ResultViewModel.swift
    │   └── SettingsViewModel.swift
    └── View/
        ├── ScanPanelView.swift
        ├── ResultPanelView.swift
        ├── DuplicateGroupRow.swift
        ├── FileRowView.swift
        └── SettingsView.swift
```

---

### Task 1: Create Project Structure and Asset Catalog

**Files:**
- Create: `FindDup/FindDup/Assets.xcassets/Contents.json`
- Create: `FindDup/FindDup/Assets.xcassets/AccentColor.colorset/Contents.json`
- Create: `FindDup/FindDup/Assets.xcassets/AppIcon.appiconset/Contents.json`
- Create: `FindDup/FindDup/Info.plist`
- Create: `FindDup/FindDup/FindDup.entitlements`

- [ ] **Step 1: Create directory structure**

```bash
mkdir -p FindDup/FindDup/App FindDup/FindDup/Core FindDup/FindDup/ViewModel FindDup/FindDup/View
mkdir -p FindDup/FindDup/Assets.xcassets/AccentColor.colorset
mkdir -p FindDup/FindDup/Assets.xcassets/AppIcon.appiconset
mkdir -p FindDup/FindDup.xcodeproj
mkdir -p FindDup/docs/superpowers/specs
mkdir -p FindDup/docs/superpowers/plans
```

- [ ] **Step 2: Create Assets.xcassets/Contents.json**

```json
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 3: Create AccentColor.colorset/Contents.json**

```json
{
  "colors" : [
    {
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "1.000",
          "green" : "0.502",
          "red" : "0.000"
        }
      },
      "idiom" : "mac"
    },
    {
      "appearances" : [
        {
          "appearance" : "luminosity",
          "value" : "dark"
        }
      ],
      "color" : {
        "color-space" : "srgb",
        "components" : {
          "alpha" : "1.000",
          "blue" : "1.000",
          "green" : "0.600",
          "red" : "0.200"
        }
      },
      "idiom" : "mac"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 4: Create AppIcon.appiconset/Contents.json**

```json
{
  "images" : [
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

- [ ] **Step 5: Create Info.plist**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleDisplayName</key>
    <string>FindDup</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>$(MARKETING_VERSION)</string>
    <key>CFBundleVersion</key>
    <string>$(CURRENT_PROJECT_VERSION)</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSHumanReadableCopyright</key>
    <string>Copyright © 2026 FindDup. All rights reserved.</string>
</dict>
</plist>
```

- [ ] **Step 6: Create FindDup.entitlements**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
```

---

### Task 2: Create Xcode Project File (project.pbxproj)

**Files:**
- Create: `FindDup/FindDup.xcodeproj/project.pbxproj`

- [ ] **Step 1: Create project.pbxproj**

The project file uses generated UUIDs. Using the pattern `F0` prefix for all IDs (unique to FindDup):

```pbxproj
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {

/* Begin PBXBuildFile section */
		F0000001 /* FindDupApp.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000020 /* FindDupApp.swift */; };
		F0000002 /* ContentView.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000021 /* ContentView.swift */; };
		F0000003 /* FileInfo.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000022 /* FileInfo.swift */; };
		F0000004 /* FileScanner.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000023 /* FileScanner.swift */; };
		F0000005 /* HashCalculator.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000024 /* HashCalculator.swift */; };
		F0000006 /* DuplicateFinder.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000025 /* DuplicateFinder.swift */; };
		F0000007 /* DuplicateGroup.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000026 /* DuplicateGroup.swift */; };
		F0000008 /* FileDeleter.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000027 /* FileDeleter.swift */; };
		F0000009 /* ScanViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000028 /* ScanViewModel.swift */; };
		F000000A /* ResultViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = F0000029 /* ResultViewModel.swift */; };
		F000000B /* SettingsViewModel.swift in Sources */ = {isa = PBXBuildFile; fileRef = F000002A /* SettingsViewModel.swift */; };
		F000000C /* ScanPanelView.swift in Sources */ = {isa = PBXBuildFile; fileRef = F000002B /* ScanPanelView.swift */; };
		F000000D /* ResultPanelView.swift in Sources */ = {isa = PBXBuildFile; fileRef = F000002C /* ResultPanelView.swift */; };
		F000000E /* DuplicateGroupRow.swift in Sources */ = {isa = PBXBuildFile; fileRef = F000002D /* DuplicateGroupRow.swift */; };
		F000000F /* FileRowView.swift in Sources */ = {isa = PBXBuildFile; fileRef = F000002E /* FileRowView.swift */; };
		F0000010 /* SettingsView.swift in Sources */ = {isa = PBXBuildFile; fileRef = F000002F /* SettingsView.swift */; };
		F0000011 /* Assets.xcassets in Resources */ = {isa = PBXBuildFile; fileRef = F0000030 /* Assets.xcassets */; };
/* End PBXBuildFile section */

/* Begin PBXFileReference section */
		F0000020 /* FindDupApp.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FindDupApp.swift; sourceTree = "<group>"; };
		F0000021 /* ContentView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ContentView.swift; sourceTree = "<group>"; };
		F0000022 /* FileInfo.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileInfo.swift; sourceTree = "<group>"; };
		F0000023 /* FileScanner.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileScanner.swift; sourceTree = "<group>"; };
		F0000024 /* HashCalculator.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = HashCalculator.swift; sourceTree = "<group>"; };
		F0000025 /* DuplicateFinder.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DuplicateFinder.swift; sourceTree = "<group>"; };
		F0000026 /* DuplicateGroup.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DuplicateGroup.swift; sourceTree = "<group>"; };
		F0000027 /* FileDeleter.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileDeleter.swift; sourceTree = "<group>"; };
		F0000028 /* ScanViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ScanViewModel.swift; sourceTree = "<group>"; };
		F0000029 /* ResultViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ResultViewModel.swift; sourceTree = "<group>"; };
		F000002A /* SettingsViewModel.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SettingsViewModel.swift; sourceTree = "<group>"; };
		F000002B /* ScanPanelView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ScanPanelView.swift; sourceTree = "<group>"; };
		F000002C /* ResultPanelView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = ResultPanelView.swift; sourceTree = "<group>"; };
		F000002D /* DuplicateGroupRow.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = DuplicateGroupRow.swift; sourceTree = "<group>"; };
		F000002E /* FileRowView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = FileRowView.swift; sourceTree = "<group>"; };
		F000002F /* SettingsView.swift */ = {isa = PBXFileReference; lastKnownFileType = sourcecode.swift; path = SettingsView.swift; sourceTree = "<group>"; };
		F0000030 /* Assets.xcassets */ = {isa = PBXFileReference; lastKnownFileType = folder.assetcatalog; path = Assets.xcassets; sourceTree = "<group>"; };
		F0000031 /* Info.plist */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = Info.plist; sourceTree = "<group>"; };
		F0000032 /* FindDup.entitlements */ = {isa = PBXFileReference; lastKnownFileType = text.plist.xml; path = FindDup.entitlements; sourceTree = "<group>"; };
		F0000033 /* FindDup.app */ = {isa = PBXFileReference; explicitFileType = wrapper.application; includeInIndex = 0; path = FindDup.app; sourceTree = BUILT_PRODUCTS_DIR; };
/* End PBXFileReference section */

/* Begin PBXGroup section */
		F0000040 /* FindDup */ = {
			isa = PBXGroup;
			children = (
				F0000041 /* App */,
				F0000042 /* Core */,
				F0000043 /* ViewModel */,
				F0000044 /* View */,
				F0000030 /* Assets.xcassets */,
				F0000031 /* Info.plist */,
				F0000032 /* FindDup.entitlements */,
			);
			path = FindDup;
			sourceTree = "<group>";
		};
		F0000041 /* App */ = {
			isa = PBXGroup;
			children = (
				F0000020 /* FindDupApp.swift */,
				F0000021 /* ContentView.swift */,
			);
			path = App;
			sourceTree = "<group>";
		};
		F0000042 /* Core */ = {
			isa = PBXGroup;
			children = (
				F0000022 /* FileInfo.swift */,
				F0000023 /* FileScanner.swift */,
				F0000024 /* HashCalculator.swift */,
				F0000025 /* DuplicateFinder.swift */,
				F0000026 /* DuplicateGroup.swift */,
				F0000027 /* FileDeleter.swift */,
			);
			path = Core;
			sourceTree = "<group>";
		};
		F0000043 /* ViewModel */ = {
			isa = PBXGroup;
			children = (
				F0000028 /* ScanViewModel.swift */,
				F0000029 /* ResultViewModel.swift */,
				F000002A /* SettingsViewModel.swift */,
			);
			path = ViewModel;
			sourceTree = "<group>";
		};
		F0000044 /* View */ = {
			isa = PBXGroup;
			children = (
				F000002B /* ScanPanelView.swift */,
				F000002C /* ResultPanelView.swift */,
				F000002D /* DuplicateGroupRow.swift */,
				F000002E /* FileRowView.swift */,
				F000002F /* SettingsView.swift */,
			);
			path = View;
			sourceTree = "<group>";
		};
		F0000050 /* Products */ = {
			isa = PBXGroup;
			children = (
				F0000033 /* FindDup.app */,
			);
			name = Products;
			sourceTree = "<group>";
		};
		F0000051 = {
			isa = PBXGroup;
			children = (
				F0000040 /* FindDup */,
				F0000050 /* Products */,
			);
			sourceTree = "<group>";
		};
/* End PBXGroup section */

/* Begin PBXNativeTarget section */
		F0000060 /* FindDup */ = {
			isa = PBXNativeTarget;
			buildConfigurationList = F0000090 /* Build configuration list for PBXNativeTarget "FindDup" */;
			buildPhases = (
				F0000071 /* Sources */,
				F0000070 /* Resources */,
			);
			buildRules = (
			);
			dependencies = (
			);
			name = FindDup;
			productName = FindDup;
			productReference = F0000033 /* FindDup.app */;
			productType = "com.apple.product-type.application";
		};
/* End PBXNativeTarget section */

/* Begin PBXProject section */
		F0000072 /* Project object */ = {
			isa = PBXProject;
			attributes = {
				BuildIndependentTargetsInParallel = 1;
				LastSwiftUpdateCheck = 1600;
				LastUpgradeCheck = 1600;
			};
			buildConfigurationList = F0000091 /* Build configuration list for PBXProject "FindDup" */;
			compatibilityVersion = "Xcode 14.0";
			developmentRegion = "en-US";
			hasScannedForEncodings = 0;
			knownRegions = (
				en-US,
				Base,
			);
			mainGroup = F0000051;
			productRefGroup = F0000050 /* Products */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				F0000060 /* FindDup */,
			);
		};
/* End PBXProject section */

/* Begin PBXResourcesBuildPhase section */
		F0000070 /* Resources */ = {
			isa = PBXResourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				F0000011 /* Assets.xcassets in Resources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXResourcesBuildPhase section */

/* Begin PBXSourcesBuildPhase section */
		F0000071 /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
				F0000001 /* FindDupApp.swift in Sources */,
				F0000002 /* ContentView.swift in Sources */,
				F0000003 /* FileInfo.swift in Sources */,
				F0000004 /* FileScanner.swift in Sources */,
				F0000005 /* HashCalculator.swift in Sources */,
				F0000006 /* DuplicateFinder.swift in Sources */,
				F0000007 /* DuplicateGroup.swift in Sources */,
				F0000008 /* FileDeleter.swift in Sources */,
				F0000009 /* ScanViewModel.swift in Sources */,
				F000000A /* ResultViewModel.swift in Sources */,
				F000000B /* SettingsViewModel.swift in Sources */,
				F000000C /* ScanPanelView.swift in Sources */,
				F000000D /* ResultPanelView.swift in Sources */,
				F000000E /* DuplicateGroupRow.swift in Sources */,
				F000000F /* FileRowView.swift in Sources */,
				F0000010 /* SettingsView.swift in Sources */,
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
/* End PBXSourcesBuildPhase section */

/* Begin XCBuildConfiguration section */
		F0000080 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "FindDup/Info.plist";
				INFOPLIST_KEY_CFBundleDisplayName = "FindDup";
				INFOPLIST_KEY_LSMinimumSystemVersion = "14.0";
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © 2026 FindDup. All rights reserved.";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.finddup.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = macosx;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Debug;
		};
		F0000081 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon;
				CODE_SIGN_STYLE = Automatic;
				CURRENT_PROJECT_VERSION = 1;
				ENABLE_PREVIEWS = YES;
				GENERATE_INFOPLIST_FILE = NO;
				INFOPLIST_FILE = "FindDup/Info.plist";
				INFOPLIST_KEY_CFBundleDisplayName = "FindDup";
				INFOPLIST_KEY_LSMinimumSystemVersion = "14.0";
				INFOPLIST_KEY_NSHumanReadableCopyright = "Copyright © 2026 FindDup. All rights reserved.";
				LD_RUNPATH_SEARCH_PATHS = (
					"$(inherited)",
					"@executable_path/../Frameworks",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MARKETING_VERSION = 1.0.0;
				PRODUCT_BUNDLE_IDENTIFIER = com.finddup.app;
				PRODUCT_NAME = "$(TARGET_NAME)";
				SDKROOT = macosx;
				SWIFT_EMIT_LOC_STRINGS = YES;
				SWIFT_VERSION = 5.0;
			};
			name = Release;
		};
		F0000082 /* Debug */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = dwarf;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				ENABLE_TESTABILITY = YES;
				GCC_DYNAMIC_NO_PIC = NO;
				GCC_OPTIMIZATION_LEVEL = 0;
				GCC_PREPROCESSOR_DEFINITIONS = (
					"DEBUG=1",
					"$(inherited)",
				);
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MTL_ENABLE_DEBUG_INFO = INCLUDE_SOURCE;
				ONLY_ACTIVE_ARCH = YES;
				SDKROOT = macosx;
				SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG;
				SWIFT_OPTIMIZATION_LEVEL = "-Onone";
			};
			name = Debug;
		};
		F0000083 /* Release */ = {
			isa = XCBuildConfiguration;
			buildSettings = {
				ALWAYS_SEARCH_USER_PATHS = NO;
				ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS = YES;
				CLANG_ANALYZER_NONNULL = YES;
				CLANG_CXX_LANGUAGE_STANDARD = "gnu++20";
				CLANG_ENABLE_MODULES = YES;
				CLANG_ENABLE_OBJC_ARC = YES;
				COPY_PHASE_STRIP = NO;
				DEBUG_INFORMATION_FORMAT = "dwarf-with-dsym";
				ENABLE_NS_ASSERTIONS = NO;
				ENABLE_STRICT_OBJC_MSGSEND = YES;
				GCC_OPTIMIZATION_LEVEL = s;
				MACOSX_DEPLOYMENT_TARGET = 14.0;
				MTL_ENABLE_DEBUG_INFO = NO;
				SDKROOT = macosx;
				SWIFT_COMPILATION_MODE = wholemodule;
				SWIFT_OPTIMIZATION_LEVEL = "-O";
			};
			name = Release;
		};
/* End XCBuildConfiguration section */

/* Begin XCConfigurationList section */
		F0000090 /* Build configuration list for PBXNativeTarget "FindDup" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				F0000080 /* Debug */,
				F0000081 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
		F0000091 /* Build configuration list for PBXProject "FindDup" */ = {
			isa = XCConfigurationList;
			buildConfigurations = (
				F0000082 /* Debug */,
				F0000083 /* Release */,
			);
			defaultConfigurationIsVisible = 0;
			defaultConfigurationName = Release;
		};
/* End XCConfigurationList section */
	};
	rootObject = F0000072 /* Project object */;
}
```

---

### Task 3: Create Core Layer — Models

**Files:**
- Create: `FindDup/FindDup/Core/FileInfo.swift`
- Create: `FindDup/FindDup/Core/DuplicateGroup.swift`

- [ ] **Step 1: Create FileInfo.swift**

```swift
import Foundation

struct FileInfo: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let size: Int64
    let modificationDate: Date
    var md5Hash: String?
    var sha256Hash: String?

    var fileName: String { url.lastPathComponent }
    var fileExtension: String { url.pathExtension.lowercased() }

    var formattedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: FileInfo, rhs: FileInfo) -> Bool {
        lhs.id == rhs.id
    }
}
```

- [ ] **Step 2: Create DuplicateGroup.swift**

```swift
import Foundation

struct DuplicateGroup: Identifiable {
    let id = UUID()
    let files: [FileInfo]
    let totalSize: Int64
    let wastedSize: Int64

    var fileCount: Int { files.count }
    var displayName: String { files.first?.fileName ?? "Unknown" }

    var formattedTotalSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: totalSize)
    }

    var formattedWastedSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: wastedSize)
    }
}
```

---

### Task 4: Create Core Layer — FileScanner (Actor)

**Files:**
- Create: `FindDup/FindDup/Core/FileScanner.swift`

- [ ] **Step 1: Create FileScanner.swift**

```swift
import Foundation

enum FileTypeFilter: String, CaseIterable {
    case all = "全部文件"
    case images = "图片"
    case documents = "文档"
    case videos = "视频"
    case music = "音乐"

    var extensions: [String] {
        switch self {
        case .all: return []
        case .images: return ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic", "webp"]
        case .documents: return ["pdf", "doc", "docx", "xls", "xlsx", "ppt", "pptx", "txt", "rtf", "md", "csv"]
        case .videos: return ["mp4", "mov", "avi", "mkv", "wmv", "flv", "webm"]
        case .music: return ["mp3", "wav", "aac", "flac", "ogg", "wma", "m4a"]
        }
    }
}

actor FileScanner {
    private var isCancelled = false

    func cancel() {
        isCancelled = true
    }

    func scanDirectory(
        _ url: URL,
        minimumSize: Int64 = 1024,
        fileTypeFilter: FileTypeFilter = .all,
        progressHandler: @escaping (Int) -> Void
    ) async throws -> [FileInfo] {
        isCancelled = false
        var files: [FileInfo] = []
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]

        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: keys,
            options: [.skipsHiddenFiles, .skipsPackageDescendants]
        ) else {
            throw ScannerError.directoryAccessFailed
        }

        while let fileURL = enumerator.nextObject() as? URL {
            if isCancelled { throw ScannerError.cancelled }

            guard let resourceValues = try? fileURL.resourceValues(forKeys: Set(keys)),
                  let fileSize = resourceValues.fileSize,
                  fileSize >= minimumSize
            else { continue }

            if fileTypeFilter != .all {
                let ext = fileURL.pathExtension.lowercased()
                guard fileTypeFilter.extensions.contains(ext) else { continue }
            }

            let fileInfo = FileInfo(
                url: fileURL,
                size: Int64(fileSize),
                modificationDate: resourceValues.contentModificationDate ?? Date()
            )
            files.append(fileInfo)

            if files.count % 100 == 0 {
                progressHandler(files.count)
            }
        }

        progressHandler(files.count)
        return files
    }
}

enum ScannerError: Error, LocalizedError {
    case cancelled
    case directoryAccessFailed

    var errorDescription: String? {
        switch self {
        case .cancelled: return "扫描已取消"
        case .directoryAccessFailed: return "无法访问该文件夹"
        }
    }
}
```

---

### Task 5: Create Core Layer — HashCalculator (Actor)

**Files:**
- Create: `FindDup/FindDup/Core/HashCalculator.swift`

- [ ] **Step 1: Create HashCalculator.swift**

```swift
import Foundation
import CommonCrypto

actor HashCalculator {
    private let bufferSize = 1024 * 1024

    func calculateMD5(for fileURL: URL) throws -> String? {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }

        var context = CC_MD5_CTX()
        CC_MD5_Init(&context)

        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: bufferSize)
            if data.isEmpty { return false }
            data.withUnsafeBytes { buffer in
                if let baseAddress = buffer.baseAddress {
                    CC_MD5_Update(&context, baseAddress, CC_LONG(data.count))
                }
            }
            return true
        }) {}

        var digest = [UInt8](repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
        CC_MD5_Final(&digest, &context)
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func calculateSHA256(for fileURL: URL) throws -> String? {
        let fileHandle = try FileHandle(forReadingFrom: fileURL)
        defer { try? fileHandle.close() }

        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)

        while autoreleasepool(invoking: {
            let data = fileHandle.readData(ofLength: bufferSize)
            if data.isEmpty { return false }
            data.withUnsafeBytes { buffer in
                if let baseAddress = buffer.baseAddress {
                    CC_SHA256_Update(&context, baseAddress, CC_LONG(data.count))
                }
            }
            return true
        }) {}

        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&digest, &context)
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
```

---

### Task 6: Create Core Layer — DuplicateFinder and FileDeleter (Actors)

**Files:**
- Create: `FindDup/FindDup/Core/DuplicateFinder.swift`
- Create: `FindDup/FindDup/Core/FileDeleter.swift`

- [ ] **Step 1: Create DuplicateFinder.swift**

```swift
import Foundation

actor DuplicateFinder {
    private let hashCalculator = HashCalculator()

    func findDuplicates(
        in files: [FileInfo],
        progressHandler: @escaping (Double) -> Void
    ) async throws -> [DuplicateGroup] {
        let sizeGroups = Dictionary(grouping: files) { $0.size }
            .filter { $0.value.count > 1 }

        let totalGroups = sizeGroups.count
        var processedGroups = 0
        var allDuplicates: [DuplicateGroup] = []

        for (_, candidates) in sizeGroups {
            processedGroups += 1
            progressHandler(Double(processedGroups) / Double(totalGroups))

            var md5Groups: [String: [FileInfo]] = [:]

            for var file in candidates {
                if let md5 = try await hashCalculator.calculateMD5(for: file.url) {
                    file.md5Hash = md5
                    md5Groups[md5, default: []].append(file)
                }
            }

            for (_, md5Group) in md5Groups where md5Group.count > 1 {
                var sha256Groups: [String: [FileInfo]] = [:]

                for var file in md5Group {
                    if let sha256 = try await hashCalculator.calculateSHA256(for: file.url) {
                        file.sha256Hash = sha256
                        sha256Groups[sha256, default: []].append(file)
                    }
                }

                for (_, duplicateFiles) in sha256Groups where duplicateFiles.count > 1 {
                    let totalSize = duplicateFiles.reduce(0) { $0 + $1.size }
                    let wastedSize = totalSize - duplicateFiles[0].size
                    allDuplicates.append(DuplicateGroup(
                        files: duplicateFiles,
                        totalSize: totalSize,
                        wastedSize: wastedSize
                    ))
                }
            }
        }

        return allDuplicates.sorted { $0.wastedSize > $1.wastedSize }
    }
}
```

- [ ] **Step 2: Create FileDeleter.swift**

```swift
import Foundation

actor FileDeleter {
    enum DeleteError: Error, LocalizedError {
        case trashFailed(String)

        var errorDescription: String? {
            switch self {
            case .trashFailed(let path): return "无法将文件移到废纸篓: \(path)"
            }
        }
    }

    struct DeleteResult {
        let successCount: Int
        let failureCount: Int
        let freedSpace: Int64
    }

    func moveToTrash(files: [FileInfo]) async -> DeleteResult {
        var successCount = 0
        var failureCount = 0
        var freedSpace: Int64 = 0

        for file in files {
            do {
                var resultingURL: NSURL?
                try FileManager.default.trashItem(at: file.url, resultingItemURL: &resultingURL)
                successCount += 1
                freedSpace += file.size
            } catch {
                failureCount += 1
            }
        }

        return DeleteResult(
            successCount: successCount,
            failureCount: failureCount,
            freedSpace: freedSpace
        )
    }
}
```

---

### Task 7: Create ViewModel Layer

**Files:**
- Create: `FindDup/FindDup/ViewModel/ScanViewModel.swift`
- Create: `FindDup/FindDup/ViewModel/ResultViewModel.swift`
- Create: `FindDup/FindDup/ViewModel/SettingsViewModel.swift`

- [ ] **Step 1: Create SettingsViewModel.swift**

```swift
import Foundation

class SettingsViewModel: ObservableObject {
    @Published var minimumFileSize: Int64 = 1024
    @Published var fileTypeFilter: FileTypeFilter = .all
    @Published var deleteToTrash: Bool = true

    var minimumFileSizeDisplay: String {
        if minimumFileSize < 1024 {
            return "\(minimumFileSize) B"
        } else if minimumFileSize < 1024 * 1024 {
            return "\(minimumFileSize / 1024) KB"
        } else {
            return "\(minimumFileSize / (1024 * 1024)) MB"
        }
    }
}
```

- [ ] **Step 2: Create ScanViewModel.swift**

```swift
import Foundation

@MainActor
class ScanViewModel: ObservableObject {
    enum ScanState {
        case idle, scanning, completed
    }

    @Published var scanState: ScanState = .idle
    @Published var scannedFileCount: Int = 0
    @Published var progress: Double = 0
    @Published var duplicateGroups: [DuplicateGroup] = []
    @Published var scannedFolderName: String = ""
    @Published var showSettings = false

    private let fileScanner = FileScanner()
    private let duplicateFinder = DuplicateFinder()

    nonisolated static let settingsViewModel = SettingsViewModel()

    func startScan(folder url: URL) {
        scanState = .scanning
        scannedFileCount = 0
        duplicateGroups = []
        progress = 0
        scannedFolderName = url.lastPathComponent

        Task {
            do {
                let settings = Self.settingsViewModel
                let files = try await fileScanner.scanDirectory(
                    url,
                    minimumSize: settings.minimumFileSize,
                    fileTypeFilter: settings.fileTypeFilter
                ) { count in
                    Task { @MainActor in
                        self.scannedFileCount = count
                    }
                }

                let groups = try await duplicateFinder.findDuplicates(in: files) { progressValue in
                    Task { @MainActor in
                        self.progress = progressValue
                    }
                }

                self.duplicateGroups = groups
                self.progress = 1.0
                self.scanState = .completed
            } catch ScannerError.cancelled {
                self.scanState = .idle
            } catch {
                self.scanState = .idle
            }
        }
    }

    func cancelScan() {
        Task {
            await fileScanner.cancel()
        }
    }

    func reset() {
        scanState = .idle
        scannedFileCount = 0
        duplicateGroups = []
        progress = 0
        scannedFolderName = ""
    }
}
```

- [ ] **Step 3: Create ResultViewModel.swift**

```swift
import Foundation

@MainActor
class ResultViewModel: ObservableObject {
    @Published var selectedFileIDs: Set<UUID> = []
    @Published var expandedGroupID: UUID?
    @Published var isDeleting = false
    @Published var showDeleteAlert = false
    @Published var deleteResultText: String?

    private let fileDeleter = FileDeleter()

    func toggleSelection(for fileID: UUID) {
        if selectedFileIDs.contains(fileID) {
            selectedFileIDs.remove(fileID)
        } else {
            selectedFileIDs.insert(fileID)
        }
    }

    func selectAll(in groups: [DuplicateGroup]) {
        for group in groups {
            for file in group.files.dropFirst() {
                selectedFileIDs.insert(file.id)
            }
        }
    }

    func deselectAll(in groups: [DuplicateGroup]) {
        for group in groups {
            for file in group.files {
                selectedFileIDs.remove(file.id)
            }
        }
    }

    func areAllSelected(in groups: [DuplicateGroup]) -> Bool {
        let allFiles = groups.flatMap { $0.files.dropFirst() }
        return allFiles.allSatisfy { selectedFileIDs.contains($0.id) }
    }

    func defaultSelection(in groups: [DuplicateGroup]) {
        selectedFileIDs.removeAll()
        for group in groups {
            for file in group.files.dropFirst() {
                selectedFileIDs.insert(file.id)
            }
        }
    }

    func calculateWastedSpace(for groups: [DuplicateGroup]) -> Int64 {
        groups.reduce(0) { total, group in
            let selectedInGroup = group.files.filter { selectedFileIDs.contains($0.id) }
            return total + selectedInGroup.reduce(0) { $0 + $1.size }
        }
    }

    func getFilesToDelete(from groups: [DuplicateGroup]) -> [FileInfo] {
        groups.flatMap { group in
            group.files.filter { selectedFileIDs.contains($0.id) }
        }
    }

    func deleteSelected(from groups: [DuplicateGroup]) {
        let filesToDelete = getFilesToDelete(from: groups)
        guard !filesToDelete.isEmpty else { return }

        isDeleting = true
        Task {
            let result = await fileDeleter.moveToTrash(files: filesToDelete)

            let deletedIDs = Set(filesToDelete.map(\.id))
            selectedFileIDs.subtract(deletedIDs)

            let formatter = ByteCountFormatter()
            formatter.countStyle = .file

            if result.failureCount > 0 {
                deleteResultText = "已释放 \(formatter.string(fromByteCount: result.freedSpace))，\(result.failureCount) 个文件删除失败"
            } else {
                deleteResultText = "已释放 \(formatter.string(fromByteCount: result.freedSpace))"
            }

            isDeleting = false
            showDeleteAlert = true
        }
    }

    func toggleGroupExpansion(_ groupID: UUID) {
        if expandedGroupID == groupID {
            expandedGroupID = nil
        } else {
            expandedGroupID = groupID
        }
    }
}
```

---

### Task 8: Create View Layer — ScanPanel

**Files:**
- Create: `FindDup/FindDup/View/ScanPanelView.swift`

- [ ] **Step 1: Create ScanPanelView.swift**

```swift
import SwiftUI
import UniformTypeIdentifiers

struct ScanPanelView: View {
    @ObservedObject var scanVM: ScanViewModel
    @State private var showFolderPicker = false

    var body: some View {
        VStack(spacing: 20) {
            if scanVM.scanState == .idle {
                idleView
            } else if scanVM.scanState == .scanning {
                scanningView
            }
        }
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    scanVM.startScan(folder: url)
                }
            case .failure:
                break
            }
        }
    }

    private var idleView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "magnifyingglass.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("查找重复文件")
                .font(.title2)
                .fontWeight(.medium)

            Text("选择一个文件夹开始扫描")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(action: { showFolderPicker = true }) {
                Label("选择文件夹", systemImage: "folder.badge.plus")
                    .font(.headline)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            RoundedRectangle(cornerRadius: 12)
                .stroke(style: StrokeStyle(lineWidth: 2, dash: [8, 4]))
                .foregroundStyle(.secondary)
                .frame(height: 120)
                .overlay {
                    VStack(spacing: 8) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.title3)
                            .foregroundStyle(.secondary)
                        Text("或拖拽文件夹到此处")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleDrop(providers: providers)
                    return true
                }

            Spacer()
        }
        .padding(40)
    }

    private var scanningView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 48))
                .foregroundStyle(.blue)
                .symbolEffect(.rotate, options: .repeating)

            Text("正在扫描「\(scanVM.scannedFolderName)」")
                .font(.title3)
                .fontWeight(.medium)

            ProgressView(value: scanVM.progress)
                .progressViewStyle(.linear)
                .frame(maxWidth: 300)

            Text("已扫描 \(scanVM.scannedFileCount) 个文件")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("取消", role: .cancel) {
                scanVM.cancelScan()
            }
            .buttonStyle(.bordered)

            Spacer()
        }
        .padding(40)
    }

    private func handleDrop(providers: [NSItemProvider]) {
        guard let provider = providers.first else { return }
        provider.loadItem(forTypeIdentifier: UTType.folder.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            var isDir: ObjCBool = false
            guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir),
                  isDir.boolValue else { return }
            DispatchQueue.main.async {
                scanVM.startScan(folder: url)
            }
        }
    }
}
```

---

### Task 9: Create View Layer — ResultPanel

**Files:**
- Create: `FindDup/FindDup/View/ResultPanelView.swift`
- Create: `FindDup/FindDup/View/DuplicateGroupRow.swift`
- Create: `FindDup/FindDup/View/FileRowView.swift`

- [ ] **Step 1: Create FileRowView.swift**

```swift
import SwiftUI

struct FileRowView: View {
    let file: FileInfo
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(
                get: { isSelected },
                set: { _ in onToggle() }
            ))
            .toggleStyle(.checkbox)
            .labelsHidden()

            FileIconView(fileExtension: file.fileExtension)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(file.fileName)
                    .font(.callout)
                    .lineLimit(1)
                    .foregroundStyle(.primary)

                Text(file.url.deletingLastPathComponent().path)
                    .font(.caption2)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(file.formattedSize)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(file.modificationDate, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct FileIconView: View {
    let fileExtension: String

    var body: some View {
        Group {
            if ["jpg", "jpeg", "png", "gif", "heic", "webp"].contains(fileExtension) {
                Image(systemName: "photo")
                    .foregroundStyle(.blue)
            } else if ["pdf", "doc", "docx", "txt", "md", "rtf"].contains(fileExtension) {
                Image(systemName: "doc.text")
                    .foregroundStyle(.orange)
            } else if ["mp4", "mov", "avi", "mkv"].contains(fileExtension) {
                Image(systemName: "video")
                    .foregroundStyle(.purple)
            } else if ["mp3", "wav", "aac", "flac", "m4a"].contains(fileExtension) {
                Image(systemName: "music.note")
                    .foregroundStyle(.red)
            } else {
                Image(systemName: "doc")
                    .foregroundStyle(.secondary)
            }
        }
    }
}
```

- [ ] **Step 2: Create DuplicateGroupRow.swift**

```swift
import SwiftUI

struct DuplicateGroupRow: View {
    let group: DuplicateGroup
    let isExpanded: Bool
    let selectedFileIDs: Set<UUID>
    let onToggle: () -> Void
    let onToggleFile: (UUID) -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    Image(systemName: "doc.on.doc")
                        .font(.title3)
                        .foregroundStyle(.blue)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(group.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .lineLimit(1)
                            .foregroundStyle(.primary)

                        Text("\(group.fileCount) 个副本 · 共 \(group.formattedTotalSize)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle")
                            .font(.caption)
                        Text("可节省 \(group.formattedWastedSize)")
                            .font(.caption)
                    }
                    .foregroundStyle(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.green.opacity(0.1))
                    .cornerRadius(6)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                        .animation(.easeInOut(duration: 0.2), value: isExpanded)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(spacing: 0) {
                    Divider()
                    ForEach(group.files) { file in
                        FileRowView(
                            file: file,
                            isSelected: selectedFileIDs.contains(file.id),
                            onToggle: { onToggleFile(file.id) }
                        )
                        if file.id != group.files.last?.id {
                            Divider()
                        }
                    }
                }
                .padding(.leading, 40)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(.background)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.separator, lineWidth: 0.5)
        )
    }
}
```

- [ ] **Step 3: Create ResultPanelView.swift**

```swift
import SwiftUI

struct ResultPanelView: View {
    @ObservedObject var scanVM: ScanViewModel
    @StateObject private var resultVM = ResultViewModel()

    private var totalWastedSpace: Int64 {
        resultVM.calculateWastedSpace(for: scanVM.duplicateGroups)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            toolbarView

            Divider()

            groupListView
        }
        .alert("删除结果", isPresented: $resultVM.showDeleteAlert) {
            Button("好的", role: .cancel) { }
        } message: {
            Text(resultVM.deleteResultText ?? "")
        }
        .onAppear {
            resultVM.defaultSelection(in: scanVM.duplicateGroups)
        }
    }

    private var headerView: some View {
        VStack(spacing: 4) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text("扫描完成 — 「\(scanVM.scannedFolderName)」")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text("找到 \(scanVM.duplicateGroups.count) 组重复文件")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var toolbarView: some View {
        HStack {
            let allSelected = resultVM.areAllSelected(in: scanVM.duplicateGroups)
            Button(allSelected ? "取消全选" : "全选") {
                if allSelected {
                    resultVM.deselectAll(in: scanVM.duplicateGroups)
                } else {
                    resultVM.selectAll(in: scanVM.duplicateGroups)
                }
            }
            .font(.subheadline)
            .buttonStyle(.borderless)

            Spacer()

            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            Button {
                resultVM.deleteSelected(from: scanVM.duplicateGroups)
                let deletedIDs = Set(resultVM.getFilesToDelete(from: scanVM.duplicateGroups).map(\.id))
                scanVM.duplicateGroups = scanVM.duplicateGroups.compactMap { group in
                    let remaining = group.files.filter { !deletedIDs.contains($0.id) }
                    if remaining.count >= 2 {
                        let totalSize = remaining.reduce(0) { $0 + $1.size }
                        let wastedSize = totalSize - remaining[0].size
                        return DuplicateGroup(files: remaining, totalSize: totalSize, wastedSize: wastedSize)
                    }
                    return nil
                }
                resultVM.selectedFileIDs.subtract(deletedIDs)
            } label: {
                Label("删除选中 (\(formatter.string(fromByteCount: totalWastedSpace)))", systemImage: "trash")
                    .font(.subheadline)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .disabled(resultVM.selectedFileIDs.isEmpty)

            Button { scanVM.showSettings = true } label: {
                Image(systemName: "gearshape")
                    .font(.subheadline)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var groupListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(scanVM.duplicateGroups) { group in
                    DuplicateGroupRow(
                        group: group,
                        isExpanded: resultVM.expandedGroupID == group.id,
                        selectedFileIDs: resultVM.selectedFileIDs,
                        onToggle: { resultVM.toggleGroupExpansion(group.id) },
                        onToggleFile: { fileID in resultVM.toggleSelection(for: fileID) }
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
        }
    }
}
```

---

### Task 10: Create View Layer — SettingsView

**Files:**
- Create: `FindDup/FindDup/View/SettingsView.swift`

- [ ] **Step 1: Create SettingsView.swift**

```swift
import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView {
            generalSettings
                .tabItem {
                    Label("通用", systemImage: "gearshape")
                }

            filterSettings
                .tabItem {
                    Label("筛选", systemImage: "line.3.horizontal.decrease")
                }
        }
        .frame(width: 420, height: 280)
    }

    private var generalSettings: some View {
        Form {
            Section("扫描选项") {
                Picker("最小文件大小", selection: $viewModel.minimumFileSize) {
                    Text("1 KB").tag(Int64(1024))
                    Text("10 KB").tag(Int64(10 * 1024))
                    Text("100 KB").tag(Int64(100 * 1024))
                    Text("1 MB").tag(Int64(1024 * 1024))
                    Text("10 MB").tag(Int64(10 * 1024 * 1024))
                }

                Picker("删除方式", selection: $viewModel.deleteToTrash) {
                    Text("移到废纸篓").tag(true)
                    Text("直接删除").tag(false)
                }
            }

            Spacer()
        }
        .padding()
    }

    private var filterSettings: some View {
        Form {
            Section("文件类型") {
                Picker("扫描类型", selection: $viewModel.fileTypeFilter) {
                    ForEach(FileTypeFilter.allCases, id: \.self) { filter in
                        Text(filter.rawValue).tag(filter)
                    }
                }
            }

            Spacer()
        }
        .padding()
    }
}
```

---

### Task 11: Create App Entry Point and ContentView

**Files:**
- Create: `FindDup/FindDup/App/FindDupApp.swift`
- Create: `FindDup/FindDup/App/ContentView.swift`

- [ ] **Step 1: Create FindDupApp.swift**

```swift
import SwiftUI

@main
struct FindDupApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .frame(minWidth: 800, minHeight: 500)
        }
        .windowResizability(.contentSize)
    }
}
```

- [ ] **Step 2: Create ContentView.swift**

```swift
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var scanVM = ScanViewModel()
    @State private var showFolderPicker = false

    var body: some View {
        HSplitView {
            sidebarView
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 250)

            mainContentView
        }
        .frame(minWidth: 800, minHeight: 500)
        .fileImporter(
            isPresented: $showFolderPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    scanVM.startScan(folder: url)
                }
            case .failure:
                break
            }
        }
    }

    private var sidebarView: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "doc.on.doc.fill")
                    .foregroundStyle(.blue)
                Text("FindDup")
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)

            Divider()

            Button(action: { showFolderPicker = true }) {
                Label("选择文件夹", systemImage: "folder.badge.plus")
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            if scanVM.scanState == .completed {
                Button(action: { scanVM.reset() }) {
                    Label("新建扫描", systemImage: "arrow.counterclockwise")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
            }

            Spacer()

            VStack(spacing: 4) {
                Divider()
                Button(action: { scanVM.showSettings = true }) {
                    Label("设置", systemImage: "gearshape")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.borderless)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .background(.background)
    }

    @ViewBuilder
    private var mainContentView: some View {
        Group {
            switch scanVM.scanState {
            case .idle:
                ScanPanelView(scanVM: scanVM)
            case .scanning:
                ScanPanelView(scanVM: scanVM)
            case .completed:
                ResultPanelView(scanVM: scanVM)
            }
        }
        .sheet(isPresented: $scanVM.showSettings) {
            SettingsView(viewModel: ScanViewModel.settingsViewModel)
        }
    }
}
```

---

### Task 12: Move Design Doc to Specs Folder

**Files:**
- Create: `FindDup/docs/superpowers/specs/2026-05-18-finddup-design.md`

Copy the design document from the brainstorming output.
