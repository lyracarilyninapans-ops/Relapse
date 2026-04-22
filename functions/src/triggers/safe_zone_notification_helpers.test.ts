import test from "node:test";
import assert from "node:assert/strict";
import {
  buildSafeZoneNotificationBody,
  isSafeZoneCooldownActive,
  pickPatientNameFromDoc,
} from "./safe_zone_notification_helpers";

test("pickPatientNameFromDoc prefers name field", () => {
  const result = pickPatientNameFromDoc({
    name: "Alex",
    patientName: "Pat",
    displayName: "Display",
  });

  assert.equal(result, "Alex");
});

test("pickPatientNameFromDoc falls back through alternate fields", () => {
  const result = pickPatientNameFromDoc({
    name: "",
    patientName: "Pat",
    displayName: "Display",
  });

  assert.equal(result, "Pat");
});

test("pickPatientNameFromDoc uses default when no valid name exists", () => {
  const result = pickPatientNameFromDoc({
    name: "   ",
    patientName: 123,
    displayName: null,
  });

  assert.equal(result, "Patient");
});

test("buildSafeZoneNotificationBody formats exit text", () => {
  const body = buildSafeZoneNotificationBody("Alex", "exit");
  assert.equal(body, "Alex has left the safe zone");
});

test("buildSafeZoneNotificationBody formats enter text", () => {
  const body = buildSafeZoneNotificationBody("Alex", "enter");
  assert.equal(body, "Alex has entered the safe zone");
});

test("buildSafeZoneNotificationBody uses fallback for blank name", () => {
  const body = buildSafeZoneNotificationBody("   ", "enter");
  assert.equal(body, "Patient has entered the safe zone");
});

test("isSafeZoneCooldownActive returns true inside cooldown window", () => {
  const now = Date.now();
  const isActive = isSafeZoneCooldownActive(new Date(now - 5_000), now, 10_000);
  assert.equal(isActive, true);
});

test("isSafeZoneCooldownActive returns false outside cooldown window", () => {
  const now = Date.now();
  const isActive = isSafeZoneCooldownActive(new Date(now - 11_000), now, 10_000);
  assert.equal(isActive, false);
});

test("isSafeZoneCooldownActive returns false when no previous send timestamp", () => {
  const isActive = isSafeZoneCooldownActive(undefined, Date.now(), 10_000);
  assert.equal(isActive, false);
});
