# AGENTS.md — weixinfenshen

This repository is developed with AI coding agents. Treat this file as the default operating procedure for all work in this repo.

## 1. User / product-owner model

- The user is the product owner, not the implementation engineer.
- Convert natural-language requests into concrete engineering tasks yourself.
- Resolve routine debugging, dependency, build, signing, and architecture questions from the repository/tooling whenever possible instead of pushing them back to the user.
- When a requirement is slightly ambiguous, prefer the smallest reversible implementation that best serves the stated product goal.
- Final status should be concise Chinese unless the user asks otherwise.

## 2. Definition of done

Never claim a feature is complete merely because code was written or compilation succeeded.

A change is complete only when all applicable checks pass:

1. The project builds successfully.
2. The changed path is exercised in a real or representative runtime when available.
3. Important user interactions are actually tested.
4. Relevant runtime/build logs are checked.
5. Persistence/isolation changes are verified across process termination and relaunch.
6. The final report distinguishes what was implemented from what was actually verified.

If runtime verification is impossible in the current environment, explicitly say `implemented but not runtime-verified`.

## 3. iOS / multi-instance verification rules

When an Xcode environment is available:

- Build with the repository's real target/scheme/configuration.
- Prefer Simulator or device verification for behavior changes.
- Perform a cold launch after changes touching startup, persistence, Keychain, UserDefaults, caches, app groups, entitlements, bundle identifiers, target configuration, or authentication/session state.
- For multiple app variants/instances, test each variant independently after both have been terminated.
- Verify that one instance does not silently read another instance's persisted state unless sharing is an explicit product requirement.
- Check bundle identifiers, Keychain access groups, App Groups, shared containers, UserDefaults suites, caches, database paths, and entitlement inheritance when isolation bugs appear.
- A value appearing different during one live process is not sufficient proof of isolation; verify terminate -> relaunch -> re-read.

## 4. Regression scenario for instance isolation

For bugs involving A/B instances, reproduce and verify at least this sequence when relevant:

1. Launch instance A.
2. Create/change A-specific persisted state.
3. Terminate A.
4. Launch instance B.
5. Create/change B-specific persisted state.
6. Terminate B.
7. Relaunch A and confirm A restores only the expected A state.
8. Relaunch B and confirm B restores only the expected B state.
9. Repeat once with reversed launch order if the bug involved "last writer wins" or shared fallback behavior.

Do not declare the isolation bug fixed until the cold-start sequence passes.

## 5. GitHub Actions / CI

- A red workflow is an engineering task, not a user task.
- Inspect failed jobs and logs yourself before modifying code.
- Fix the root cause rather than retrying blindly.
- Do not hide failures by removing checks, weakening build settings, or disabling tests.
- When this repository depends on GitHub Actions macOS runners for Xcode builds, treat CI as the authoritative build environment and verify the relevant workflow passes before declaring success whenever possible.

## 6. Scope and architecture discipline

- Prefer the smallest correct fix over a broad rewrite.
- Preserve working architecture unless it directly causes the requested problem.
- Reuse existing code and configuration before introducing parallel systems.
- Do not add abstractions/dependencies merely for elegance.
- First make the full user path work; refactor only after verification.
- Avoid speculative features not requested by the user.

## 7. Debugging discipline

For bugs:

1. Reproduce or precisely identify the failing path.
2. Determine the relevant boundary: runtime state, persistence, target configuration, entitlements, signing, cache, networking, etc.
3. Form a concrete hypothesis.
4. Make the smallest root-cause fix.
5. Re-run the exact scenario that previously failed.
6. Add a regression test or explicit verification step when practical.

Do not label a workaround as a root-cause fix.

## 8. Security and platform integrity

- Never commit signing certificates, provisioning profiles containing private material, API keys, passwords, tokens, or other credentials.
- Keep secrets in the repository's existing secure mechanism / GitHub Secrets.
- Do not weaken platform security controls merely to make a build pass.
- Do not introduce code intended to access another app's private data, bypass platform sandboxing, evade authentication, or defeat account/platform security controls.
- Keep instance separation explicit and auditable.

## 9. UI / product quality

- Maintain clear states for setup, success, failure, missing configuration, and recovery.
- Error messages should identify the actionable cause rather than displaying generic failure text when the underlying reason is known.
- UI changes are not complete until the affected screen is rendered and visually checked when tools are available.

## 10. Repository hygiene

- Avoid unrelated formatting churn.
- Do not commit generated build products unless this repository intentionally tracks them.
- Preserve working CI and build configuration unless changing it is part of the task.

## 11. Agent handoff / reporting

Before finishing, report:

- **Changed:** files/configuration/features materially changed.
- **Verified:** build/runtime/cold-start scenarios actually exercised.
- **Result:** what now works.
- **Remaining risk:** real unverified paths or known limitations only.

Never say `done`, `fixed`, or `works` when the relevant path has not been verified.
