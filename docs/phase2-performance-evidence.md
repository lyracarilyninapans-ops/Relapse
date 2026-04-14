# Phase 2 Performance Evidence

Use this template to record before/after measurements for Phase 2 workstreams.

## Test Environment

- Date:
- Engineer:
- Device (physical):
- Emulator profile:
- Build mode: profile
- Commit (before):
- Commit (after):

## Scripted Flow

1. Launch app -> login
2. Navigate: Home -> Activity -> Memory -> Activity
3. Run for 5 minutes with live updates enabled
4. Tab switch stress: 30 switches across all tabs
5. Record DevTools screenshots for rebuild/repaint

## Metrics

### Home Screen

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| Rebuild count (Patient Overview) |  |  |  |
| Repaint count (main content) |  |  |  |
| Avg frame time (ms) |  |  |  |

### Activity Screen

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| Rebuild count (Current Location card) |  |  |  |
| Repaint count (Map + chart region) |  |  |  |
| Avg frame time (ms) |  |  |  |

### Resource / Runtime

| Metric | Before | After | Delta |
|---|---:|---:|---:|
| Memory after 30 min active session (MB) |  |  |  |
| Hidden-tab map resource usage note |  |  |  |

## Acceptance Check

- [ ] Home tracked rebuild/repaint counts improved by >= 25%
- [ ] Activity tracked rebuild/repaint counts improved by >= 25%
- [ ] No user-visible regression in map interactions
- [ ] No user-visible regression in tab state behavior

## Attachments

- DevTools screenshot (before):
- DevTools screenshot (after):
- Notes:
