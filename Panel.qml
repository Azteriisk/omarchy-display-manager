import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Ui
import qs.Commons
import "Model.js" as Model

Panel {
  id: root
  moduleName: "azterisk.display-manager"
  ipcTarget: "azterisk.display-manager"
  manageIpc: false

  property int brightnessPercent: 0
  property int pendingBrightnessPercent: 0
  property bool brightnessSetQueued: false
  property bool brightnessAvailable: false
  property string internalMonitor: ""
  property string externalMonitor: ""
  property string focusedMonitor: ""
  property bool internalEnabled: false
  property bool mirrorEnabled: false
  property string monitorScale: ""
  property var displays: []
  property int enabledDisplayCount: 0
  property real wheelAccumulator: 0

  // Active Monitors & Geometry State
  property string primaryMonitor: "DP-1"
  property string secondaryMonitor: "HDMI-A-1"
  property int primaryWidth: 1920
  property int primaryHeight: 1080
  property real primaryScale: 1.0
  property int secondaryWidth: 1920
  property int secondaryHeight: 1080
  property real secondaryScale: 1.5

  // Live Hyprland relative coordinates of secondary display
  property int currentX: 200
  property int currentY: 1080
  property bool isDragging: false
  property bool hasUserPosition: false

  // Canvas visual scaling ratio (pixels in canvas per workspace pixel)
  readonly property real canvasRatio: 0.050

  readonly property var scalePresets: ["1", "1.25", "1.5", "1.6", "2", "3", "4"]
  readonly property var scaleValues: {
    for (var i = 0; i < displays.length; i++) {
      var display = displays[i]
      if (display && display.focused)
        return Model.availableScales(scalePresets, display.width, display.height)
    }
    return scalePresets
  }

  readonly property var textSizeStops: [9, 10, 11, 12, 14, 16, 20]
  property int textSizePreviewIndex: -1
  property bool reflowingText: false

  function markReflowing() {
    root.reflowingText = true
    reflowSettle.restart()
  }

  // Effective dimensions in Hyprland workspace
  readonly property int primaryEffW: Math.round(primaryWidth / primaryScale)
  readonly property int primaryEffH: Math.round(primaryHeight / primaryScale)
  readonly property int secondaryEffW: Math.round(secondaryWidth / secondaryScale)
  readonly property int secondaryEffH: Math.round(secondaryHeight / secondaryScale)

  function applyPositioning(newX, newY, notify) {
    hasUserPosition = true
    currentX = Math.round(newX)
    currentY = Math.round(newY)

    var pMon = primaryMonitor || "DP-1"
    var sMon = secondaryMonitor || "HDMI-A-1"

    var luaContent = "-- Hyprland Monitor Configuration\n"
      + "-- Managed by Display Manager\n"
      + "local omarchy_gdk_scale = 1\n"
      + "local omarchy_monitor_scale = \"auto\"\n\n"
      + "hl.env(\"GDK_SCALE\", tostring(omarchy_gdk_scale))\n\n"
      + "-- Primary Display (Display 1)\n"
      + "hl.monitor({\n"
      + "  output = \"" + pMon + "\",\n"
      + "  mode = \"1920x1080@240\",\n"
      + "  position = \"0x0\",\n"
      + "  scale = 1,\n"
      + "})\n\n"
      + "-- Secondary Display (Display 2)\n"
      + "hl.monitor({\n"
      + "  output = \"" + sMon + "\",\n"
      + "  mode = \"1920x1080@60\",\n"
      + "  position = \"" + currentX + "x" + currentY + "\",\n"
      + "  scale = " + secondaryScale + ",\n"
      + "})\n\n"
      + "-- Fallback for other displays\n"
      + "hl.monitor({ output = \"\", mode = \"preferred\", position = \"auto\", scale = 1 })\n\n"
      + "-- Workspace & Display Numbering Assignment\n"
      + "hl.config({\n"
      + "  workspace = {\n"
      + "    \"1, monitor:" + pMon + ", default:true\",\n"
      + "    \"2, monitor:" + sMon + ", default:true\",\n"
      + "    \"3, monitor:" + pMon + "\",\n"
      + "    \"4, monitor:" + sMon + "\",\n"
      + "    \"5, monitor:" + pMon + "\",\n"
      + "    \"6, monitor:" + sMon + "\",\n"
      + "    \"7, monitor:" + pMon + "\",\n"
      + "    \"8, monitor:" + sMon + "\",\n"
      + "    \"9, monitor:" + pMon + "\",\n"
      + "    \"10, monitor:" + sMon + "\",\n"
      + "  },\n"
      + "})\n"

    var notifyCmd = notify ? " && notify-send -a 'Display Manager' 'Layout Saved' 'Saved (" + currentX + "x" + currentY + ") to ~/.config/hypr/monitors.lua'" : ""
    var script = "cat << 'EOF' > ~/.config/hypr/monitors.lua\n" + luaContent + "EOF\n"
      + "hyprctl keyword monitor \"" + pMon + ",1920x1080@240,0x0,1\" && "
      + "hyprctl keyword monitor \"" + sMon + ",1920x1080@60," + currentX + "x" + currentY + "," + secondaryScale + "\""
      + notifyCmd

    actionProc.command = ["bash", "-c", script]
    if (!actionProc.running) actionProc.running = true
  }

  function savePositioningToConfig() {
    applyPositioning(currentX, currentY, true)
  }



  function snapToPreset(preset) {
    var x = 0
    var y = 0
    var centerX = Math.round((primaryEffW - secondaryEffW) / 2)
    var centerY = Math.round((primaryEffH - secondaryEffH) / 2)

    if (preset === "bottom-center") {
      x = centerX
      y = primaryEffH
    } else if (preset === "bottom-left") {
      x = 0
      y = primaryEffH
    } else if (preset === "bottom-current") {
      x = 200
      y = primaryEffH
    } else if (preset === "top-center") {
      x = centerX
      y = -secondaryEffH
    } else if (preset === "left-center") {
      x = -secondaryEffW
      y = centerY
    } else if (preset === "right-center") {
      x = primaryEffW
      y = centerY
    }

    applyPositioning(x, y, true)
  }

  function setBrightness(value) {
    var percent = Model.clampBrightness(value)
    root.brightnessPercent = percent
    root.pendingBrightnessPercent = percent

    if (setBrightnessProc.running) {
      root.brightnessSetQueued = true
      return
    }

    root.brightnessSetQueued = false
    setBrightnessProc.command = ["omarchy-brightness-display", "--no-osd", "--monitor", root.focusedMonitor, percent + "%"]
    setBrightnessProc.running = true
  }

  function showBrightnessOsd(percent) {
    if (!bar || !bar.shell) return
    bar.shell.summon("omarchy.osd", JSON.stringify({
      icon: "brightness",
      value: percent
    }))
  }

  function setTextSize(px) {
    textScaleProc.command = ["omarchy-display-text-size", String(px)]
    if (!textScaleProc.running) textScaleProc.running = true
  }

  function setScale(scale) {
    actionProc.command = ["bash", "-c", "omarchy-hyprland-monitor-scaling " + scale]
    if (!actionProc.running) actionProc.running = true
  }

  function toggleDisplay(name, enabled) {
    if (!name) return
    if (enabled && root.enabledDisplayCount <= 1) return

    actionProc.command = ["hyprctl", "keyword", "monitor", name + (enabled ? ",disable" : ",preferred,auto,auto")]
    if (!actionProc.running) actionProc.running = true
  }

  function nearestTextStop(px) {
    var best = 0
    var bestDist = 1e9
    for (var i = 0; i < textSizeStops.length; i++) {
      var d = Math.abs(textSizeStops[i] - px)
      if (d < bestDist) { bestDist = d; best = i }
    }
    return best
  }

  function currentTextIndex() {
    return textSizePreviewIndex >= 0 ? textSizePreviewIndex : nearestTextStop(Style.font.baseSize)
  }

  function effectiveScale(scale) {
    for (var i = 0; i < displays.length; i++) {
      var display = displays[i]
      if (display && display.focused)
        return Model.cleanScale(scale, display.width, display.height)
    }
    return Model.normalizeScale(scale)
  }

  function activeScaleIndex() {
    for (var i = 0; i < displays.length; i++) {
      var display = displays[i]
      if (display && display.focused)
        return Model.matchingScaleIndex(scaleValues, monitorScale, display.width, display.height)
    }
    return -1
  }

  function refresh() {
    if (!stateProc.running) stateProc.running = true
    if (!hyprMonitorsProc.running) hyprMonitorsProc.running = true
  }

  onOpenedChanged: {
    if (opened) {
      root.hasUserPosition = false
      refresh()
    }
  }

  Component.onCompleted: refresh()

  IpcHandler {
    target: "azterisk.display-manager"
    function open() { root.open() }
    function close() { root.close() }
    function toggle() { root.toggle() }
  }

  Process {
    id: hyprMonitorsProc
    command: ["hyprctl", "-j", "monitors"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        try {
          var mons = JSON.parse(text || "[]")
          for (var i = 0; i < mons.length; i++) {
            var m = mons[i]
            if (m.name === root.primaryMonitor || (!root.primaryMonitor && i === 0)) {
              root.primaryWidth = m.width
              root.primaryHeight = m.height
              root.primaryScale = m.scale || 1.0
            } else if (m.name === root.secondaryMonitor || (!root.secondaryMonitor && i === 1)) {
              root.secondaryWidth = m.width
              root.secondaryHeight = m.height
              root.secondaryScale = m.scale || 1.5
              if (!root.isDragging && !root.hasUserPosition) {
                root.currentX = m.x
                root.currentY = m.y
              }
            }
          }
        } catch (e) {}
      }
    }
  }

  Process {
    id: stateProc
    command: ["omarchy-monitor-state"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        var lines = String(text || "").split("\n")
        var brightness = String(lines[0] || "").trim()
        root.brightnessAvailable = brightness !== "unavailable" && brightness !== ""
        root.brightnessPercent = root.brightnessAvailable ? Math.max(0, Math.min(100, parseInt(brightness, 10))) : 0
        root.internalMonitor = String(lines[1] || "").trim()
        root.externalMonitor = String(lines[2] || "").trim()
        root.internalEnabled = String(lines[3] || "").trim() !== ""
        root.mirrorEnabled = String(lines[4] || "").trim() === root.externalMonitor && root.externalMonitor !== ""
        root.focusedMonitor = String(lines[5] || "").trim()
        root.monitorScale = Model.normalizeScale(String(lines[6] || "").trim())
        var parsed = Model.parseDisplays(String(lines[7] || "[]").trim())
        root.displays = parsed.displays
        root.enabledDisplayCount = parsed.enabledDisplayCount
      }
    }
  }

  Process {
    id: setBrightnessProc
    stdout: StdioCollector { waitForEnd: true }
  }

  Process {
    id: actionProc
    stdout: StdioCollector { waitForEnd: true }
    onRunningChanged: if (!running) root.refresh()
  }

  Process {
    id: textScaleProc
    stdout: StdioCollector { waitForEnd: true }
  }

  Timer {
    id: reflowSettle
    interval: 300
    repeat: false
    onTriggered: root.reflowingText = false
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: Quickshell.screens.length > 1 ? "󰍺" : "󰍹"
    onPressed: function(b) { root.toggle() }
    onWheelMoved: function(delta) {
      if (!root.brightnessAvailable) return
      var wheel = Util.wheelSteps(root.wheelAccumulator, delta)
      root.wheelAccumulator = wheel.remainder
      if (wheel.steps === 0) return
      root.setBrightness(root.brightnessPercent + wheel.steps * 5)
      root.showBrightnessOsd(root.brightnessPercent)
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    contentWidth: panel.fittedContentWidth(Style.space(400))
    contentHeight: panel.fittedContentHeight(panelColumn.implicitHeight, Style.space(720))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()

      ScrollView {
        id: scrollArea
        anchors.fill: parent
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
        ScrollBar.vertical.policy: panelColumn.implicitHeight > height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff

        Column {
          id: panelColumn
          width: scrollArea.availableWidth
          spacing: Style.space(14)

          // ---------- Hero Section ----------
          Item {
            width: parent.width
            implicitHeight: Math.max(heroIcon.implicitHeight, heroLabels.implicitHeight)

            Text {
              id: heroIcon
              text: root.displays.length > 1 ? "󰍺" : "󰍹"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.display
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Column {
              id: heroLabels
              anchors.left: heroIcon.right
              anchors.leftMargin: Style.space(14)
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                text: "Display Manager"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.title
                font.bold: true
                elide: Text.ElideRight
                width: parent.width
              }

              Text {
                text: "DRAG & DROP SCREEN POSITIONING"
                color: Color.accent
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.1
                elide: Text.ElideRight
                width: parent.width
              }
            }
          }

          // ==================== INTERACTIVE DRAG & DROP CANVAS ====================
          PanelSeparator { foreground: root.bar.foreground }

          Item {
            width: parent.width
            implicitHeight: canvasHeader.implicitHeight

            PanelSectionHeader {
              id: canvasHeader
              text: "REARRANGE DISPLAYS"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
            }

            Text {
              text: "Click & drag [2] freely"
              color: Color.accent
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
            }
          }

          // Visual Interactive Workspace Canvas
          Rectangle {
            id: canvasArea
            width: parent.width
            height: Style.space(170)
            color: Qt.darker(root.bar.foreground, 8.5)
            radius: Style.space(8)
            border.color: Qt.darker(root.bar.foreground, 3.0)
            border.width: 1
            clip: true

            // Grid background pattern
            Grid {
              anchors.fill: parent
              columns: 14
              spacing: Style.space(24)
              opacity: 0.12
              Repeater {
                model: 70
                Rectangle {
                  width: 2; height: 2; color: root.bar.foreground; radius: 1
                }
              }
            }

            Item {
              id: stage
              anchors.fill: parent

              // Reference Origin for Primary Display
              readonly property real originX: (stage.width - pBox.width) / 2
              readonly property real originY: (stage.height - (pBox.height + sBox.height + 8)) / 2

              // Primary Display Box [1]
              Rectangle {
                id: pBox
                width: root.primaryEffW * root.canvasRatio
                height: root.primaryEffH * root.canvasRatio
                x: stage.originX
                y: stage.originY
                color: Color.accent
                radius: 4
                border.color: Qt.lighter(Color.accent, 1.3)
                border.width: 2

                Column {
                  anchors.centerIn: parent
                  spacing: 1

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "1"
                    color: "#11111b"
                    font.bold: true
                    font.pixelSize: Style.font.title
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.primaryMonitor
                    color: "#11111b"
                    font.bold: true
                    font.pixelSize: 10
                  }
                }
              }

              // Secondary Display Box [2] (Interactive Draggable Item)
              Rectangle {
                id: sBox
                width: root.secondaryEffW * root.canvasRatio
                height: root.secondaryEffH * root.canvasRatio
                color: sMouse.drag.active ? "#89dceb" : "#a6e3a1"
                radius: 4
                border.color: sMouse.drag.active ? "#ffffff" : Qt.darker("#a6e3a1", 1.3)
                border.width: sMouse.drag.active ? 2 : 1
                z: sMouse.drag.active ? 10 : 1

                // Position binding when not actively dragging
                x: sMouse.drag.active ? x : stage.originX + (root.currentX * root.canvasRatio)
                y: sMouse.drag.active ? y : stage.originY + (root.currentY * root.canvasRatio)

                Column {
                  anchors.centerIn: parent
                  spacing: 1

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "2"
                    color: "#11111b"
                    font.bold: true
                    font.pixelSize: Style.font.subtitle
                  }

                  Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.secondaryMonitor
                    color: "#11111b"
                    font.bold: true
                    font.pixelSize: 9
                  }
                }

                MouseArea {
                  id: sMouse
                  anchors.fill: parent
                  cursorShape: Qt.SizeAllCursor
                  drag.target: sBox
                  drag.axis: Drag.XAndYAxis
                  drag.minimumX: stage.originX - (1500 * root.canvasRatio)
                  drag.maximumX: stage.originX + (2500 * root.canvasRatio)
                  drag.minimumY: stage.originY - (1200 * root.canvasRatio)
                  drag.maximumY: stage.originY + (1500 * root.canvasRatio)

                  onPressed: {
                    root.isDragging = true
                  }

                  onPositionChanged: {
                    if (drag.active) {
                      var rawHyprX = (sBox.x - stage.originX) / root.canvasRatio
                      var rawHyprY = (sBox.y - stage.originY) / root.canvasRatio
                      var snapped = Model.applySmartSnapping(
                        rawHyprX,
                        rawHyprY,
                        root.primaryEffW,
                        root.primaryEffH,
                        root.secondaryEffW,
                        root.secondaryEffH
                      )
                      root.currentX = snapped.x
                      root.currentY = snapped.y
                    }
                  }

                  onReleased: {
                    root.isDragging = false
                    root.applyPositioning(root.currentX, root.currentY, false)
                  }
                }
              }
            }
          }

          // Active Position & Offset Info
          Rectangle {
            width: parent.width
            height: Style.space(32)
            color: Qt.darker(root.bar.foreground, 7.5)
            radius: 4

            Item {
              anchors.fill: parent
              anchors.leftMargin: Style.space(10)
              anchors.rightMargin: Style.space(10)

              Text {
                text: "Position Coordinates:"
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.caption
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
              }

              Text {
                text: "X: " + root.currentX + " px  ·  Y: " + root.currentY + " px"
                color: Color.accent
                font.family: root.bar.fontFamily
                font.bold: true
                font.pixelSize: Style.font.caption
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
              }
            }
          }

          // Quick Snap Presets
          Row {
            width: parent.width
            spacing: Style.space(6)

            Button {
              text: "Snap Center"
              width: (parent.width - Style.space(12)) / 3
              fontSize: Style.font.caption
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              bordered: true
              onClicked: root.snapToPreset("bottom-center")
            }

            Button {
              text: "Snap Left (0px)"
              width: (parent.width - Style.space(12)) / 3
              fontSize: Style.font.caption
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              bordered: true
              onClicked: root.snapToPreset("bottom-left")
            }

            Button {
              text: "Current (200px)"
              width: (parent.width - Style.space(12)) / 3
              fontSize: Style.font.caption
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
              active: root.currentX === 200 && root.currentY === 1080
              bordered: true
              onClicked: root.snapToPreset("bottom-current")
            }
          }

          // Save Layout Action
          Button {
            text: "💾 Save Layout to monitors.lua"
            width: parent.width
            fontSize: Style.font.caption
            foreground: root.bar.foreground
            fontFamily: root.bar.fontFamily
            active: true
            bordered: true
            onClicked: root.savePositioningToConfig()
          }

          // ---------- Brightness ----------
          PanelSeparator {
            visible: root.brightnessAvailable
            foreground: root.bar.foreground
          }

          Column {
            visible: root.brightnessAvailable
            width: parent.width
            spacing: Style.space(6)

            PanelSectionHeader {
              text: "BRIGHTNESS"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            PanelSlider {
              width: parent.width
              bar: root.bar
              minimum: 1
              maximum: 100
              step: 1
              integer: true
              value: root.brightnessPercent
              onReleased: function(v) { root.setBrightness(Math.round(v)) }
            }
          }

          // ---------- Text Size ----------
          PanelSeparator { foreground: root.bar.foreground }

          Column {
            width: parent.width
            spacing: Style.space(6)

            PanelSectionHeader {
              text: "TEXT SIZE"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            PanelSlider {
              width: parent.width
              bar: root.bar
              minimum: 0
              maximum: root.textSizeStops.length - 1
              step: 1
              integer: true
              tickCount: root.textSizeStops.length
              value: root.currentTextIndex()
              onReleased: function(v) { root.setTextSize(root.textSizeStops[Math.round(v)]) }
            }
          }

          // ---------- Scale ----------
          PanelSeparator { foreground: root.bar.foreground }

          Column {
            width: parent.width
            spacing: Style.space(10)

            PanelSectionHeader {
              text: "SCALE (Focused: " + (root.focusedMonitor || "DP-1") + ")"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            Grid {
              id: scaleRow
              width: parent.width
              columns: root.scaleValues.length
              spacing: Style.spacing.xs

              readonly property real cellWidth: root.scaleValues.length > 0
                ? (width - spacing * (columns - 1)) / columns
                : 0

              Repeater {
                model: root.scaleValues
                Button {
                  required property string modelData
                  required property int index

                  text: root.effectiveScale(modelData) + "x"
                  fontSize: Style.font.caption
                  foreground: root.bar.foreground
                  fontFamily: root.bar.fontFamily
                  horizontalPadding: Style.spacing.sm
                  verticalPadding: Style.spacing.controlPaddingY
                  bordered: true
                  width: scaleRow.cellWidth
                  active: root.activeScaleIndex() === index
                  onClicked: root.setScale(modelData)
                }
              }
            }
          }

          // ---------- Displays List ----------
          PanelSeparator {
            visible: root.displays.length > 1
            foreground: root.bar.foreground
          }

          Column {
            width: parent.width
            spacing: Style.space(10)
            visible: root.displays.length > 1

            PanelSectionHeader {
              text: "CONNECTED MONITORS"
              foreground: root.bar.foreground
              fontFamily: root.bar.fontFamily
            }

            Repeater {
              model: root.displays
              CursorSurface {
                id: monitorRow
                required property var modelData
                width: panelColumn.width
                implicitHeight: Style.space(34)
                foreground: root.bar.foreground
                fill: Style.hoverFillFor(root.bar.foreground, Color.accent)
                currentFill: Style.selectedFillFor(root.bar.foreground, Color.accent)
                current: modelData && modelData.focused

                Row {
                  anchors.left: parent.left
                  anchors.right: parent.right
                  anchors.verticalCenter: parent.verticalCenter
                  anchors.leftMargin: Style.space(6)
                  anchors.rightMargin: Style.space(6)
                  spacing: Style.space(8)

                  Text {
                    text: "󰍹"
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.title
                    width: Style.space(22)
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: monitorRow.modelData.name + (monitorRow.modelData.focused ? " · focused" : "")
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.body
                    elide: Text.ElideRight
                    width: parent.width - Style.space(60)
                    anchors.verticalCenter: parent.verticalCenter
                  }

                  Text {
                    text: monitorRow.modelData.enabled ? "󰄬" : ""
                    color: root.bar.foreground
                    font.family: root.bar.fontFamily
                    font.pixelSize: Style.font.subtitle
                    anchors.verticalCenter: parent.verticalCenter
                  }
                }

                MouseArea {
                  anchors.fill: parent
                  hoverEnabled: true
                  cursorShape: Qt.PointingHandCursor
                  onClicked: root.toggleDisplay(monitorRow.modelData.name, monitorRow.modelData.enabled)
                }
              }
            }
          }

          Item {
            width: parent.width
            height: Style.space(6)
          }
        }
      }
    }
  }
}
