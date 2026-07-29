# Paused tools

Mechanics that are intentionally off. Keep the script here with fail-closed
messaging rather than deleting it: the reason it is paused is the valuable part, and a
deleted tool invites someone to rebuild it without knowing why it was retired.

A paused tool must exit non-zero with a message that says what is unavailable and
what to do instead. A skill must never list a paused tool as a runnable binding — see
`../../docs/skill-binding-contract.md`.
