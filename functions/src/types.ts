/** Shared type definitions for Cloud Functions. */

export interface ActivityRecord {
  id?: string;
  patientId: string;
  eventType: string;
  timestamp: FirebaseFirestore.Timestamp;
  latitude?: number;
  longitude?: number;
  metadata?: Record<string, unknown>;
}

export interface SafeZoneEventData {
  id?: string;
  safeZoneId: string;
  eventType: "enter" | "exit";
  timestamp: FirebaseFirestore.Timestamp;
  latitude?: number;
  longitude?: number;
}

export interface WatchStatus {
  isConnected: boolean;
  batteryLevel?: number;
  lastSeen?: FirebaseFirestore.Timestamp;
  pairedWatchId?: string;
}

export interface DailySummary {
  date: string;
  totalEvents: number;
  safeZoneExits: number;
  remindersTriggered: number;
  distanceMeters: number;
  activeMinutes: number;
  placesVisited: number;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface DeviceRecord {
  fcmToken: string;
  platform: string;
  updatedAt: FirebaseFirestore.Timestamp;
}

export interface NotificationPayload {
  type: string;
  patientId?: string;
  eventId?: string;
  reminderId?: string;
  screen?: string;
}
