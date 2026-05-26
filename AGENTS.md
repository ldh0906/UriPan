# UriPan Codex Instructions

These instructions apply only in the UriPan repository.

## Token Discipline

Keep exploration output small. Prefer targeted `rg` searches and capped file reads over broad recursive listings or full-file dumps.

- Do not print full install logs, generated build logs, large README files, or large `SKILL.md` files unless the user explicitly asks.
- Avoid `ls -R`, broad `Get-ChildItem -Recurse`, `find` over large trees, and unbounded log reads.
- When inspecting large outputs, use filters, `Select-Object -First`, `-TotalCount`, or search patterns first.
- Summarize tool output instead of pasting long command output into the conversation.
- Use gstack and Compound Engineering skills only when their heavier context is worth the task.

## Superpowers Brainstorming

When using Superpowers brainstorming for UriPan work, add a lightweight multi-role discussion before presenting the final design. Run this discussion directly in the current Codex thread by default. Do not load gstack skills automatically; use gstack only when the user explicitly asks for a gstack command or deeper specialist review.

Required roles:

- Product owner: challenge user value, scope, and sequencing.
- Engineering lead: challenge architecture, maintainability, and integration risk.
- Designer: challenge UX clarity, interaction details, and visual consistency.
- QA reviewer: challenge testability, edge cases, and regression risk.

Fold the useful objections into the design before asking for approval. Keep the discussion concise and actionable.

## Review Completion

After Superpowers review is complete and before finishing a development branch, run only the Compound Engineering compounding step if the plugin is available. Avoid loading broader Compound Engineering workflows unless the user explicitly asks for them.

Use the compound step to record:

- mistakes found during review,
- patterns that could repeat,
- project-specific guardrails for future work,
- follow-up checks that should happen before merge.

Do not use compounding as a substitute for tests, code review, or verification.
