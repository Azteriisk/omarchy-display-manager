function clampBrightness(value) {
  var n = Number(value)
  if (!isFinite(n)) return 1
  return Math.max(1, Math.min(100, Math.round(n)))
}

function normalizeScale(scale) {
  var n = parseFloat(String(scale || ""))
  if (!isFinite(n)) return ""
  return String(Math.round(n * 100) / 100)
}

function gcd(a, b) {
  while (b) {
    var remainder = a % b
    a = b
    b = remainder
  }
  return a
}

function cleanScale(scale, width, height) {
  var requested = Number(scale)
  var modeWidth = Number(width)
  var modeHeight = Number(height)
  if (!isFinite(requested) || !isFinite(modeWidth) || !isFinite(modeHeight)
      || requested <= 0 || modeWidth <= 0 || modeHeight <= 0) return ""

  var divisor = gcd(Math.round(modeWidth * 120), Math.round(modeHeight * 120))
  var scaleUnits = Math.round(requested * 120)
  if (scaleUnits > divisor) scaleUnits = divisor
  while (divisor % scaleUnits !== 0) scaleUnits++
  return normalizeScale(scaleUnits / 120)
}

function matchingScaleIndex(scales, currentScale, width, height) {
  var current = Number(currentScale)
  if (!Array.isArray(scales) || !isFinite(current)) return -1

  var bestIndex = -1
  var bestDistance = Infinity
  var normalizedCurrent = normalizeScale(current)
  for (var i = 0; i < scales.length; i++) {
    if (cleanScale(scales[i], width, height) !== normalizedCurrent) continue

    var distance = Math.abs(Number(scales[i]) - current)
    if (distance < bestDistance) {
      bestIndex = i
      bestDistance = distance
    }
  }
  return bestIndex
}

function availableScales(scales, width, height) {
  if (!Array.isArray(scales) || Number(width) <= 0 || Number(height) <= 0) return scales || []

  var byEffectiveScale = {}
  for (var i = 0; i < scales.length; i++) {
    var requested = Number(scales[i])
    var effective = Number(cleanScale(requested, width, height))

    if (!isFinite(requested) || !isFinite(effective)) continue

    var key = normalizeScale(effective)
    var existing = byEffectiveScale[key]
    if (!existing || Math.abs(requested - effective) < existing.distance) {
      byEffectiveScale[key] = {
        value: String(scales[i]),
        index: i,
        distance: Math.abs(requested - effective)
      }
    }
  }

  return Object.keys(byEffectiveScale)
    .map(function(key) { return byEffectiveScale[key] })
    .sort(function(a, b) { return a.index - b.index })
    .map(function(candidate) { return candidate.value })
}

function brightnessName(percent) {
  var p = Math.round(percent)
  if (p >= 95) return "Sun blast"
  if (p >= 80) return "Solar flare"
  if (p >= 65) return "Golden hour"
  if (p >= 45) return "Even day"
  if (p >= 30) return "Soft glow"
  if (p >= 20) return "Lamp light"
  if (p >= 10) return "Candlelit"
  return "Night owl"
}

function parseDisplays(raw) {
  var displays = []
  try {
    displays = raw ? JSON.parse(String(raw)) : []
  } catch (e) {
    displays = []
  }
  if (!Array.isArray(displays)) displays = []

  var count = 0
  for (var i = 0; i < displays.length; i++) {
    if (displays[i] && displays[i].enabled) count++
  }

  return {
    displays: displays,
    enabledDisplayCount: count
  }
}

/**
 * Snap raw coordinates with a tolerance threshold
 */
function snapCoordinate(val, target, tolerance) {
  if (Math.abs(val - target) <= (tolerance || 25)) {
    return target
  }
  return val
}

/**
 * Normalize and validate a Hyprland monitor transform value (0..7)
 */
function normalizeTransform(transform) {
  var t = parseInt(transform, 10)
  if (!isFinite(t) || t < 0 || t > 7) return 0
  return t
}

/**
 * Returns true if the transform swaps width and height (90 or 270 degrees)
 */
function isPortraitTransform(transform) {
  var t = normalizeTransform(transform)
  return t === 1 || t === 3 || t === 5 || t === 7
}

/**
 * Get rotation in degrees for a given transform value
 */
function rotationDegrees(transform) {
  var t = normalizeTransform(transform)
  var degs = [0, 90, 180, 270, 0, 90, 180, 270]
  return degs[t] || 0
}

/**
 * Human-readable rotation label
 */
function rotationName(transform) {
  var t = normalizeTransform(transform)
  if (t === 1) return "Portrait (90°)"
  if (t === 2) return "Inverted (180°)"
  if (t === 3) return "Portrait (270°)"
  return "Standard (0°)"
}

/**
 * Calculate effective workspace dimensions given mode width/height, scale, and transform
 */
function effectiveDimensions(width, height, scale, transform) {
  var w = Number(width)
  var h = Number(height)
  var s = parseFloat(String(scale || "1"))
  if (!isFinite(w) || w <= 0) w = 1920
  if (!isFinite(h) || h <= 0) h = 1080
  if (!isFinite(s) || s <= 0) s = 1.0

  var portrait = isPortraitTransform(transform)
  var effW = portrait ? Math.round(h / s) : Math.round(w / s)
  var effH = portrait ? Math.round(w / s) : Math.round(h / s)

  return {
    width: effW,
    height: effH
  }
}

/**
 * Apply smart edge & center snapping when dragging secondary monitor around primary
 */
function applySmartSnapping(rawX, rawY, pEffW, pEffH, sEffW, sEffH) {
  var x = rawX
  var y = rawY

  var centerX = (pEffW - sEffW) / 2
  var centerY = (pEffH - sEffH) / 2

  // Horizontal edge/center snapping
  x = snapCoordinate(x, 0, 30)
  x = snapCoordinate(x, centerX, 30)
  x = snapCoordinate(x, pEffW - sEffW, 30)

  // Vertical edge/center snapping
  y = snapCoordinate(y, 0, 30)
  y = snapCoordinate(y, centerY, 30)
  y = snapCoordinate(y, pEffH - sEffH, 30)

  // Top / Bottom attachment snapping
  y = snapCoordinate(y, pEffH, 35)      // Bottom attachment
  y = snapCoordinate(y, -sEffH, 35)     // Top attachment

  // Left / Right attachment snapping
  x = snapCoordinate(x, pEffW, 35)      // Right attachment
  x = snapCoordinate(x, -sEffW, 35)     // Left attachment

  return {
    x: Math.round(x),
    y: Math.round(y)
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    clampBrightness: clampBrightness,
    normalizeScale: normalizeScale,
    cleanScale: cleanScale,
    matchingScaleIndex: matchingScaleIndex,
    availableScales: availableScales,
    brightnessName: brightnessName,
    parseDisplays: parseDisplays,
    normalizeTransform: normalizeTransform,
    isPortraitTransform: isPortraitTransform,
    rotationDegrees: rotationDegrees,
    rotationName: rotationName,
    effectiveDimensions: effectiveDimensions,
    applySmartSnapping: applySmartSnapping
  }
}
