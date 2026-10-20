# Independent Core Review

Date: 2026-10-11. Source review only; no build, simulator, device run, network call, purchase, or App data mutation was performed. The only written artifact is this report. Scope: TaskStore persistence, export range/time semantics, notification launch routing, and read/export/delete after subscription expiration. Existing fixed map/time-zone and AI conflict findings are not repeated.

## Findings

### [P2] Opening an already-delivered advance reminder schedules a second alert at task start

Source: `MapToDo/Features/Reminders/ReminderService.swift:24–27`, `:95–120`; activation caller `MapToDo/App/MapToDoApp.swift:13–18`.

Reproduction conditions: an incomplete task starts at 10:00 with a 15-minute advance reminder. Its notification is delivered at 09:45. At 09:46, tap the notification or foreground the App, without editing the task. The plan sees the advance time in the past and returns a new request for 10:00. Synchronization fetches delivered notifications but uses that list only to remove stale fingerprints; it does not suppress scheduling for a matching task notification that has already fired. It therefore adds a second future notification for the same unchanged task. This is also possible if the user cleared the first notification before opening the App, since no durable fired state exists.

Impact: the selected single advance reminder becomes an additional start-time reminder simply because the App was activated. The fallback added for a newly created task whose advance time has already elapsed is useful, but the current policy does not distinguish that case from an already-reminded task.

Recommendation: distinguish first scheduling after a missed advance window from an unchanged schedule that already fired. A persisted schedule/fingerprint delivery record, or a synchronization design that preserves the already-scheduled timeline and only uses the fallback for new/changed schedules, can avoid the duplicate. A delivered-notification-only check handles the immediate tap case but is insufficient after Notification Center dismissal. Add a regression for the 09:45-delivered/09:46-reactivated/10:00-start scenario as well as the existing newly-created-task fallback test.

Status: confirmed by control-flow inspection; OS delivery reproduction NOT RUN. No P0 or P1 defect was established in this review scope.

## Inspected paths without an additional established defect

- Persistence: `TaskStore.swift:55–75` validates the decoded collection, detects duplicate IDs, retains the original unreadable file, and enters read-only mode. Mutations publish new tasks only after atomic/protected write succeeds. `:42–53` rejects an invalid schedule batch before persistence. Corruption therefore does not silently overwrite the original bytes. This is a preservation strategy, not a user-facing recovery mechanism.
- Export range: `ExportFormatter.swift:13–18` uses calendar start-of-day and an exclusive next-day upper boundary, so the end day is inclusive without assuming a 24-hour DST day. `ExportView.swift:26–27` discloses that filtering uses the device time zone. `ExportFormatter.swift:24–28` renders each task in its stored time zone; `:65–76` exports UTC ICS dates and escaped/folded content. A task that starts before the selected day and overlaps it is excluded by the documented start-time filter, not treated here as a bug.
- Cold notification routing: `ReminderService.swift:57–62` installs the notification delegate; `:155–162` parses an owned matching task UUID and publishes it on MainActor. `RootView.swift:14–18` observes with `initial: true`, allowing an ID published before view observation to be consumed. `TaskStore` loads synchronously during creation (`TaskStore.swift:22`). Source supports the route, but does not establish the timing of the actual OS cold-launch callback.
- Expired access: `SubscriptionStore.swift:101–122` accepts only verified active/non-revoked transactions, clears stale access, and schedules expiration reconciliation. `AccessPolicy.swift:4–12` limits demo access to DEBUG testing flags. `TaskEditorView.swift:137–146` checks access before save, but its deletion path (`:103–105`) does not require access. `TodayView.swift:39–47` similarly leaves deletion and export available; opening an existing item remains allowed (`:50–53`). `ExportView`/`ExportFormatter` and `TaskStore` reads have no subscription gate. Existing data is therefore accessible independently of an App Store product fetch.

## Missing verification and limits

1. **Actual notification cold launch:** `ReminderTests` proves payload/identifier validation, not OS callback delivery or final editor presentation. Kill the signed App, receive a local notification, tap it, and verify the matching existing task opens once. Also check a removed task's stale notification does not resurrect it. Repeat while a warm App already has an editor/export sheet open; RootView clears the ID before presentation, so sheet contention needs explicit coverage rather than a source-only success claim.
2. **True expiration-to-data-operation integration:** `StoreKitLifecycleTests.swift:69–81` exercises expiration on a newly constructed SubscriptionStore, while `testExistingTasksCanExportTextMarkdownAndICSWithoutDemoAccess` proves no-access exports. Neither is an end-to-end UI test that expires the singleton entitlement used by AccessPolicy, then verifies read, all three exports, deletion+reload, and blocked save. Run that lifecycle with no demo-access flag; do not equate separate tests to this combined result.
3. **Persistence failure behavior:** CoreTests covers normal edit/completion/delete reload and corrupt bytes. It lacks a forced valid-store write failure (e.g. an unwritable destination), asserting unchanged in-memory tasks and unchanged original file for upsert/remove/batch apply. Real device protected-file behavior before first unlock and storage exhaustion are also unverified in this pass.
4. **Recovery boundary:** corrupted files are retained but no repair/import/recovery screen was found. The user can see an error yet cannot export the unreadable original via the normal task exporter. This is a product limitation to document; not an allegation of silent data loss.
5. **Export calendar matrix:** existing ExportTests covers the spring-forward 23-hour end day, UTC ICS, escaping, and UTF-8 folding. Add fall-back 25-hour day, device-zone filtering of overseas tasks at both midnight boundaries, and locale-independent ICS importer validation. This review did not run or re-certify previously reported tests.

## Recommendation

Resolve or consciously document the duplicate-reminder behavior, and keep real cold-launch/expiration/storage-failure checks in the release verification matrix. The inspected source is not evidence that those OS-dependent scenarios passed.
