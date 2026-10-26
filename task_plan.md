# Nourish App Store Release Plan

## Objective

Make the repository release-ready for App Store submission. All workspace-controlled
gates must pass. External Apple account, agreements, and manual device actions are
tracked separately and must be the only remaining blockers.

## Gates

- [ ] Audit project configuration, signing, entitlements, privacy, secrets, and assets.
- [ ] Confirm current Apple submission requirements from official sources.
- [ ] Fix production configuration and release-only behavior.
- [ ] Add required App Store privacy metadata and export compliance declarations.
- [ ] Add/validate app icons, launch behavior, version/build numbers, and device support.
- [ ] Audit data loss, notifications, hydration, matcher, correction memory, and API failures.
- [ ] Run automated matcher evaluation and targeted regression harnesses.
- [ ] Eliminate build warnings that affect submission or runtime behavior.
- [ ] Produce signed Debug build and unsigned/signed Release archive where credentials permit.
- [ ] Validate archive/app bundle contents, entitlements, privacy manifest, and embedded secrets.
- [ ] Prepare App Store metadata, privacy answers, review notes, and release checklist.
- [ ] Review final diff and produce release-readiness report.

## Current Status

In progress: project and policy audit.

## Known External Dependencies

- Paid Apple Developer Program membership for TestFlight/App Store distribution.
- App Store Connect access, agreements, tax/banking status, and app record ownership.
- Physical iPhone availability for final notification/hydration regression.

## Errors And Decisions

- Correction memory is process-local in all configurations. Apple's App Review
  Guidelines prohibit storing personal health information in iCloud; durable
  cross-device memory requires a separately designed backend and privacy flow.
- Existing worktree is intentionally dirty; preserve all user changes.
