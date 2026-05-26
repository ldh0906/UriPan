# UriPan Superpowers Gstack and Compound Design

## Scope

Apply the integration only when Codex is working inside `C:\UriPan`.

## Goals

- Add a multi-role discussion step to Superpowers brainstorming so design assumptions are checked from product, engineering, design, and QA perspectives.
- Add a Compound Engineering step after review completion so repeated mistakes are captured before the branch is considered finished.
- Avoid editing cached third-party plugin files. Project-local instructions should survive plugin updates.

## Approach

Use `AGENTS.md` in the UriPan repository as the project-local hook. Codex already reads project instructions, so this keeps the behavior limited to UriPan without modifying the Superpowers plugin cache.

Install external tooling in Codex's user-level plugin/skill locations:

- gstack for Codex role orchestration skills.
- Compound Engineering for Codex review and compounding commands.

## Workflow

During Superpowers brainstorming:

1. Complete the normal Superpowers context exploration.
2. Run a role discussion before finalizing the design.
3. Include at least product, engineering, design, and QA perspectives.
4. Fold the useful objections and constraints into the proposed design.

After review completion:

1. Treat code review completion as the handoff point into the Compound step.
2. Run Compound Engineering's compounding workflow before branch finish.
3. Capture repeated mistakes, review lessons, and future guardrails.
4. Do not treat compounding as a replacement for tests, review, or verification.

## Risks

- Compound Engineering depends on its Codex plugin installation and Bun-based installer.
- gstack setup depends on its upstream installer behavior.
- Some plugin commands may require a Codex restart or TUI plugin installation after CLI setup.

## Verification

- Confirm project instructions exist in `C:\UriPan\AGENTS.md`.
- Confirm Codex marketplace entry exists for Compound Engineering.
- Confirm installed gstack skills are present in `~\.codex\skills`.
- Confirm any remaining manual Codex TUI install step is documented.
