# Omarchy Display Manager (`azterisk.display-manager`)

An interactive, visual display manager & positioning extension plugin for **Omarchy Linux** and **Hyprland**.

![Display Manager](https://raw.githubusercontent.com/Azteriisk/omarchy-display-manager/main/assets/preview.png)

---

## ✨ Features

- 🖱️ **Interactive Windows-Style Drag & Drop Canvas**: Click and freely drag connected displays around in real-time to arrange your multi-monitor layout visually.
- 🧲 **Magnetic Edge & Center Snapping**: Effortlessly snap displays to exact center alignments or adjacent edges.
- ⇄ **Display Role & Numbering Switcher**: Designate Display 1 (Primary) vs Display 2 (Secondary) and assign workspace bindings (Workspaces 1, 3, 5... on Display 1, Workspaces 2, 4, 6... on Display 2).
- 💾 **Automatic Instant Persistence**: Automatically writes your exact geometry coordinates to `~/.config/hypr/monitors.lua` and updates Hyprland live the second you let go.
- ☀️ **Complete Control Suite**: Built-in backlight brightness slider, UI text scaling, display scale presets ("1x", "1.25x", "1.5x", "2x"), and monitor enable/disable toggles.

---

## 🚀 Quick Install (1-Line Command)

Run this in your terminal to install and enable the plugin automatically:

```bash
git clone https://github.com/Azteriisk/omarchy-display-manager.git ~/.config/omarchy/plugins/azterisk.display-manager && omarchy plugin enable azterisk.display-manager && omarchy restart shell
```

---

## 🛠️ Manual Installation

1. **Clone or Copy to Plugins Directory**:
   ```bash
   mkdir -p ~/.config/omarchy/plugins/
   git clone https://github.com/Azteriisk/omarchy-display-manager.git ~/.config/omarchy/plugins/azterisk.display-manager
   ```

2. **Enable in `~/.config/omarchy/shell.json`**:
   Add or swap `"azterisk.display-manager"` in the right section of your bar layout:
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

3. **Restart the Shell**:
   ```bash
   omarchy restart shell
   ```

---

## 🗑️ Uninstallation

```bash
~/.config/omarchy/plugins/azterisk.display-manager/uninstall.sh
```

---

## 📁 Repository Structure

```
azterisk.display-manager/
├── manifest.json   # Plugin manifest specification (schemaVersion: 1)
├── Panel.qml       # Quickshell UI panel, drag & drop canvas, bar widget
├── Model.js        # Coordinate transformations, scale math & smart snapping
├── install.sh      # 1-command installer script
├── uninstall.sh    # Clean uninstaller script
└── README.md       # Documentation & usage guide
```

---

## 👤 Author
Created by **Azteriisk** for the Omarchy community.
