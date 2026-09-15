# AGENTS.md — weixinfenshen

This repository inherits the cross-project AI workflow from:

`https://github.com/zcssr1998-art/AI-Development-Rules/blob/main/GLOBAL_AI_RULES.md`

This file contains **weixinfenshen-specific** rules only. Rule precedence:

`explicit current user instruction > this AGENTS.md > GLOBAL_AI_RULES.md > agent defaults`

## New-session read order

1. `AGENTS.md`
2. global `GLOBAL_AI_RULES.md`
3. current task/state file if present
4. current branch / HEAD / `git status` / relevant diff
5. only files required for the current task

Do not paste the global rulebook or repo-resident taskbooks into chat again.

## iOS / multi-instance verification

When an Xcode environment is available:

- Build with the repository's real target/scheme/configuration.
- Prefer Simulator or device verification for behavior changes.
- Perform a cold launch after changes touching startup, persistence, Keychain, UserDefaults, caches, app groups, entitlements, bundle identifiers, target configuration, or authentication/session state.
- For multiple app variants/instances, test each variant independently after both have been terminated.
- Verify that one instance does not silently read another instance's persisted state unless sharing is an explicit product requirement.
- Check bundle identifiers, Keychain access groups, App Groups, shared containers, UserDefaults suites, caches, database paths, and entitlement inheritance when isolation bugs appear.
- A value appearing different during one live process is not sufficient proof of isolation; verify terminate → relaunch → re-read.

## Required regression scenario for instance isolation

For A/B instance bugs, reproduce and verify when relevant:

1. launch A;
2. create/change A-specific persisted state;
3. terminate A;
4. launch B;
5. create/change B-specific persisted state;
6. terminate B;
7. relaunch A and confirm A restores only expected A state;
8. relaunch B and confirm B restores only expected B state;
9. repeat once with reversed launch order if the bug involved last-writer-wins/shared fallback behavior.

Do not declare an isolation bug fixed until the cold-start sequence passes.

## CI authority

When the repository depends on GitHub Actions macOS runners for Xcode builds, treat CI as the authoritative build environment.

- Inspect failed jobs/logs directly.
- Fix root cause instead of blindly retrying.
- Do not weaken build settings, remove checks, or disable tests just to obtain green CI.

## Security / platform integrity

In addition to the global secret-handling rules:

- never commit signing certificates, provisioning profiles containing private material, or private signing credentials;
- do not weaken platform security controls merely to make a build pass;
- do not introduce code intended to access another app's private data, bypass platform sandboxing, evade authentication, or defeat account/platform security controls;
- keep instance separation explicit and auditable.

## UI / product quality

- Maintain clear states for setup, success, failure, missing configuration, and recovery.
- Error messages should identify the actionable cause when known.
- UI changes are not complete until the affected screen is rendered and visually checked when tools are available.

## Reporting additions

Follow the global concise-reporting rule. For this project add only relevant build/runtime/cold-start/isolation verification and remaining real risk.
