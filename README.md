# Omarchy Display Manager (azterisk.display-manager)

An interactive, visual display manager and positioning extension plugin for Omarchy Linux and Hyprland.

![Display Manager](https://raw.githubusercontent.com/Azteriisk/omarchy-display-manager/main/assets/preview.png)

## Features

- Interactive Drag and Drop Canvas: Click and freely drag connected displays around in real-time to arrange your multi-monitor layout visually.
- Per-Monitor Rotation: Rotate displays independently (0°, 90°, 180°, 270°) with instant canvas orientation preview and Hyprland lua config persistence.
- Magnetic Edge and Center Snapping: Snap displays to exact center alignments or adjacent edges.
- Display Role and Numbering Switcher: Designate Display 1 (Primary) vs Display 2 (Secondary) and assign workspace bindings (Workspaces 1, 3, 5 on Display 1; Workspaces 2, 4, 6 on Display 2).
- Automatic Instant Persistence: Automatically writes your exact geometry coordinates to ~/.config/hypr/monitors.lua and updates Hyprland live immediately.
- Complete Control Suite: Built-in backlight brightness slider, UI text scaling, display scale presets (1x, 1.25x, 1.5x, 2x), and monitor enable/disable toggles.

## Installation

### Method 1: Omarchy Plugin Manager (Recommended)
```bash
omarchy plugin add https://github.com/Azteriisk/omarchy-display-manager.git --enable --yes
```

### Method 2: Git Clone and 1-Line Setup
```bash
git clone https://github.com/Azteriisk/omarchy-display-manager.git ~/.config/omarchy/plugins/azterisk.display-manager && ~/.config/omarchy/plugins/azterisk.display-manager/install.sh
```

## Manual Installation

1. Clone or Copy to Plugins Directory:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/
   git clone https://github.com/Azteriisk/omarchy-display-manager.git ~/.config/omarchy/plugins/azterisk.display-manager
   ```

2. Enable in ~/.config/omarchy/shell.json:
   Add or swap "azterisk.display-manager" in the right section of your bar layout:
   ```json
   {
     "version": 1,
     "bar": {
       "layout": {
         "right": [
           { "id": "omarchy.tray" },
           { "id": "omarchy.network" },
           { "id": "omarchy.audio" },
           { "id": "azterisk.display-manager" },
           { "id": "omarchy.power" }
         ]
       }
     }
   }
   ```

3. Restart the Shell:
   ```bash
   omarchy restart shell
   ```

## Uninstallation

```bash
~/.config/omarchy/plugins/azterisk.display-manager/uninstall.sh
```

## Repository Structure

```
azterisk.display-manager/
├── manifest.json   # Plugin manifest specification (schemaVersion: 1)
├── Panel.qml       # Quickshell UI panel, drag and drop canvas, bar widget
├── Model.js        # Coordinate transformations, scale math and smart snapping
├── install.sh      # 1-command installer script
├── uninstall.sh    # Clean uninstaller script
└── README.md       # Documentation and usage guide
```

## Author
Created by Azteriisk for the Omarchy community.
