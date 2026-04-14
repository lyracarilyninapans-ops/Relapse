# Firestore Index Deployment (Staging + Production)

This project stores Firestore composite indexes in `firestore.indexes.json`.

## 1) Config wiring

Firebase CLI reads the index file path from `firebase.json`:

- `firestore.indexes = firestore.indexes.json`

This ensures `firebase deploy --only firestore:indexes` always deploys the same index definitions.

## 2) One-time setup (recommended)

Create a `.firebaserc` in project root with aliases:

```json
{
  "projects": {
    "prod": "relapse-488712",
    "staging": "<your-staging-project-id>"
  }
}
```

If you do not use aliases, use explicit project IDs in deploy commands.

## 3) Deploy commands

From the `Relapse` app root:

```bash
# Staging
firebase deploy --only firestore:indexes --project staging

# Production
firebase deploy --only firestore:indexes --project prod
```

Without aliases:

```bash
# Staging
firebase deploy --only firestore:indexes --project <your-staging-project-id>

# Production
firebase deploy --only firestore:indexes --project relapse-488712
```

## 4) Verification after deploy

1. Open Firebase Console -> Firestore Database -> Indexes for the target project.
2. Confirm index for `activityRecords` exists with:
   - `eventType` ascending
   - `timestamp` descending
3. Wait until status is `Enabled` before enabling code paths that require the new index.

## 5) CI recommendation

Use a manual/approved pipeline step for prod and auto for staging.

Example sequence:

1. Validate: `firebase firestore:indexes --project <target>` (or check via console)
2. Deploy staging indexes.
3. Run staging smoke test for latest-location stream.
4. Approve and deploy prod indexes.

## 6) Rollback approach

Indexes are additive and cannot be "reverted" instantly without deleting index definitions and waiting for rebuild.
For emergency rollback, keep app fallback behavior behind a feature flag and switch query path to the legacy query until index state is stable.

## 7) Runtime fallback toggle (no redeploy)

The app reads `users/{uid}/settings/preferences.use_optimized_latest_location_query`.

- `true`: use optimized query (`where(eventType == location_update) + orderBy(timestamp desc) + limit(1)`).
- `false`: use legacy client-filtered fallback query.

Operational usage:

1. Set the flag to `false` for affected users/cohorts if index rollout is unstable.
2. Verify latest-location behavior and read rates recover.
3. After index status is stable, set flag back to `true`.

Default behavior:

- If setting is absent, default is `true`.
- Build-level default can be overridden with `--dart-define=LATEST_LOCATION_OPTIMIZED_QUERY=true|false`.
