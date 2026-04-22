import test from "node:test";
import assert from "node:assert/strict";
import { extractReminderIdFromMetadata } from "./reminder_triggers";

test("extractReminderIdFromMetadata reads reminderId from metadata object", () => {
  const reminderId = extractReminderIdFromMetadata({
    reminderId: "reminder_123",
  });

  assert.equal(reminderId, "reminder_123");
});

test("extractReminderIdFromMetadata reads reminderId from legacy JSON string", () => {
  const reminderId = extractReminderIdFromMetadata(
    JSON.stringify({ reminderId: "reminder_legacy" }),
  );

  assert.equal(reminderId, "reminder_legacy");
});

test("extractReminderIdFromMetadata returns empty string for invalid legacy JSON", () => {
  const reminderId = extractReminderIdFromMetadata("{invalid-json");

  assert.equal(reminderId, "");
});

test("extractReminderIdFromMetadata returns empty string for non-string reminderId", () => {
  const reminderId = extractReminderIdFromMetadata({
    reminderId: 123,
  });

  assert.equal(reminderId, "");
});

test("extractReminderIdFromMetadata returns empty string when metadata missing", () => {
  const reminderId = extractReminderIdFromMetadata(undefined);

  assert.equal(reminderId, "");
});
