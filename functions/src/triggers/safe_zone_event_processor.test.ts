import test from "node:test";
import assert from "node:assert/strict";
import {
  buildSafeZoneNotificationData,
  buildSafeZoneNotificationTitle,
  processSafeZoneEventNotification,
  SAFE_ZONE_COOLDOWN_MS,
} from "./safe_zone_event_processor";

const baseInput = {
  uid: "uid123",
  patientId: "patient123",
  eventId: "event123",
  data: {
    safeZoneId: "zoneA",
    eventType: "exit" as const,
    timestamp: {} as FirebaseFirestore.Timestamp,
  },
};

test("processSafeZoneEventNotification returns malformed for invalid payload", async () => {
  const result = await processSafeZoneEventNotification(
    {
      ...baseInput,
      data: {
        ...baseInput.data,
        safeZoneId: "",
      },
    },
    {
      claimLock: async () => true,
      shouldAllowAndMarkCooldown: async () => true,
      resolvePatientName: async () => "Alex",
      sendPush: async () => 1,
    },
  );

  assert.equal(result, "malformed");
});

test("processSafeZoneEventNotification returns already_processed when lock exists", async () => {
  const result = await processSafeZoneEventNotification(baseInput, {
    claimLock: async () => false,
    shouldAllowAndMarkCooldown: async () => true,
    resolvePatientName: async () => "Alex",
    sendPush: async () => 1,
  });

  assert.equal(result, "already_processed");
});

test("processSafeZoneEventNotification suppresses send when cooldown active", async () => {
  let sendCalled = false;
  const result = await processSafeZoneEventNotification(baseInput, {
    claimLock: async () => true,
    shouldAllowAndMarkCooldown: async () => false,
    resolvePatientName: async () => "Alex",
    sendPush: async () => {
      sendCalled = true;
      return 1;
    },
  });

  assert.equal(result, "cooldown_suppressed");
  assert.equal(sendCalled, false);
});

test("processSafeZoneEventNotification sends expected payload on success", async () => {
  let sentTitle = "";
  let sentBody = "";
  let sentData: Record<string, string> | undefined;

  const result = await processSafeZoneEventNotification(
    {
      ...baseInput,
      data: {
        ...baseInput.data,
        eventType: "enter",
      },
    },
    {
      claimLock: async () => true,
      shouldAllowAndMarkCooldown: async () => true,
      resolvePatientName: async () => "Alex",
      sendPush: async (_uid, title, body, data) => {
        sentTitle = title;
        sentBody = body;
        sentData = data;
        return 1;
      },
      nowMs: () => 123456,
    },
  );

  assert.equal(result, "sent");
  assert.equal(sentTitle, "Safe Zone Update");
  assert.equal(sentBody, "Alex has entered the safe zone");
  assert.deepEqual(sentData, {
    type: "safe_zone_enter",
    patientId: "patient123",
    eventId: "event123",
    screen: "activity",
    channelId: "safe_zone_alerts",
  });
});

test("buildSafeZoneNotificationTitle maps event type to title", () => {
  assert.equal(buildSafeZoneNotificationTitle("exit"), "Safe Zone Alert");
  assert.equal(buildSafeZoneNotificationTitle("enter"), "Safe Zone Update");
});

test("buildSafeZoneNotificationData builds stable routing payload", () => {
  assert.deepEqual(
    buildSafeZoneNotificationData("patient123", "event123", "exit"),
    {
      type: "safe_zone_exit",
      patientId: "patient123",
      eventId: "event123",
      screen: "activity",
      channelId: "safe_zone_alerts",
    },
  );
});

test("SAFE_ZONE_COOLDOWN_MS is exported for processor tests", () => {
  assert.equal(typeof SAFE_ZONE_COOLDOWN_MS, "number");
  assert.ok(SAFE_ZONE_COOLDOWN_MS > 0);
});
