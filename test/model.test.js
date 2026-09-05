const test = require("node:test");
const assert = require("node:assert");
const Model = require("../Model.js");

test("normalizeTransform handles valid and invalid inputs", () => {
  assert.strictEqual(Model.normalizeTransform(0), 0);
  assert.strictEqual(Model.normalizeTransform(1), 1);
  assert.strictEqual(Model.normalizeTransform(2), 2);
  assert.strictEqual(Model.normalizeTransform(3), 3);
  assert.strictEqual(Model.normalizeTransform("2"), 2);
  assert.strictEqual(Model.normalizeTransform(null), 0);
  assert.strictEqual(Model.normalizeTransform(undefined), 0);
  assert.strictEqual(Model.normalizeTransform(-1), 0);
  assert.strictEqual(Model.normalizeTransform(10), 0);
});

test("isPortraitTransform identifies 90 and 270 degree orientations", () => {
  assert.strictEqual(Model.isPortraitTransform(0), false);
  assert.strictEqual(Model.isPortraitTransform(1), true);
  assert.strictEqual(Model.isPortraitTransform(2), false);
  assert.strictEqual(Model.isPortraitTransform(3), true);
  assert.strictEqual(Model.isPortraitTransform(5), true);
  assert.strictEqual(Model.isPortraitTransform(7), true);
});

test("rotationDegrees maps transform to degrees", () => {
  assert.strictEqual(Model.rotationDegrees(0), 0);
  assert.strictEqual(Model.rotationDegrees(1), 90);
  assert.strictEqual(Model.rotationDegrees(2), 180);
  assert.strictEqual(Model.rotationDegrees(3), 270);
});

test("rotationName returns readable labels", () => {
  assert.strictEqual(Model.rotationName(0), "Standard (0°)");
  assert.strictEqual(Model.rotationName(1), "Portrait (90°)");
  assert.strictEqual(Model.rotationName(2), "Inverted (180°)");
  assert.strictEqual(Model.rotationName(3), "Portrait (270°)");
});

test("effectiveDimensions correctly handles standard and rotated monitors", () => {
  // Standard 1920x1080 at scale 1.0
  const standard = Model.effectiveDimensions(1920, 1080, 1.0, 0);
  assert.strictEqual(standard.width, 1920);
  assert.strictEqual(standard.height, 1080);

  // Standard 1920x1080 at scale 1.5
  const scaled = Model.effectiveDimensions(1920, 1080, 1.5, 0);
  assert.strictEqual(scaled.width, 1280);
  assert.strictEqual(scaled.height, 720);

  // Rotated 90° (transform 1) 1920x1080 at scale 1.0 -> width 1080, height 1920
  const rotated90 = Model.effectiveDimensions(1920, 1080, 1.0, 1);
  assert.strictEqual(rotated90.width, 1080);
  assert.strictEqual(rotated90.height, 1920);

  // Rotated 270° (transform 3) 1920x1080 at scale 1.5 -> width 720, height 1280
  const rotated270 = Model.effectiveDimensions(1920, 1080, 1.5, 3);
  assert.strictEqual(rotated270.width, 720);
  assert.strictEqual(rotated270.height, 1280);

  // Rotated 180° (transform 2) 1920x1080 at scale 1.0 -> width 1920, height 1080
  const rotated180 = Model.effectiveDimensions(1920, 1080, 1.0, 2);
  assert.strictEqual(rotated180.width, 1920);
  assert.strictEqual(rotated180.height, 1080);
});

test("applySmartSnapping works with rotated monitors", () => {
  // Primary: 1920x1080 (transform 0, scale 1), Secondary: 1080x1920 (transform 1, scale 1)
  const pEffW = 1920;
  const pEffH = 1080;
  const sEffW = 1080;
  const sEffH = 1920;

  // Snapping to right side attachment (x = 1920)
  const snappedRight = Model.applySmartSnapping(1915, 0, pEffW, pEffH, sEffW, sEffH);
  assert.strictEqual(snappedRight.x, 1920);
  assert.strictEqual(snappedRight.y, 0);

  // Snapping to left side attachment (x = -1080)
  const snappedLeft = Model.applySmartSnapping(-1075, 0, pEffW, pEffH, sEffW, sEffH);
  assert.strictEqual(snappedLeft.x, -1080);
});
