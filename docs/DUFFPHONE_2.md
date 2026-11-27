# Duffphone 2.0 and Glitch — approved design
Date: 2026-11-27. Status: design approved; implementation deferred, not shipped.

## Purpose
An original Android-inspired in-game phone, with an authentic working-class comedy voice. Duffphone is the central interface for daily life rather than adding more floating world markers. The simulated assistant Glitch satirizes AI-assisted everyday life. It is not a real AI service.

## Interface
Use existing Duffphone design and established button roles, with a distinct home screen, status bar, app grid, notifications, and clear back/home navigation. Do not copy a proprietary phone UI exactly. Landscape gameplay opens a readable phone panel with large touch targets, scalable text, and existing accessibility settings.
Apps: Messages, Banking, Calendar, Marketplace, Maps, Jobs, Contacts, 86 List, Skills. Adapt existing systems first; avoid duplicate economies or quest trackers. Show in-game clock and upcoming obligations; notifications should be dismissible. Start with Messages, Calendar, Banking and Glitch, expand later.

Approved visual treatment: [interface board, panel C](art/wrr-concepts/interface-options.jpg). Use original phone styling, shared colors and legible app icons; preserve approved Glitch design.

## Glitch
Glitch is a fictional offline helper with handcrafted contextual dialogue based only on game state. No network calls, subscriptions, real financial advice, external accounts, real device data or API usage. Zero operating cost. The helper's visual identity may draw on the approved three-eyed fox imagery, subject to owner art approval; it remains inside the phone. The physical mascot is a separate rare neighborhood cameo, not a companion.

Functions:
- Daily planning and reminders (shifts, bills, errands).
- In-game budget summaries calculated from actual save state.
- Cooking and station mastery hints.
- Optional spoiler-free quest guidance.
- NPC reputation and progress summaries.
- Contextual sarcastic commentary.
- Hidden jokes and recurring callbacks.

Voice: witty, dry, occasionally cocky but useful. Morning: weary encouragement; work: kitchen consultant; payday: blunt budgeting commentary; exploration: curious observer; late night: unexpectedly reflective. Sample game dialogue: “Have you considered working? Revolutionary concept, I know.” “I've analyzed your spending habits. Have you considered being less expensive?” Tailor jokes to fictional events and avoid personal details. Never punish players for ignoring suggestions.

## State and progression
Use deterministic context selection, cooldowns and non-repeating lines, with optional hints and a persistent history of relevant in-game choices. Facts such as cash, due dates and skill levels must be derived from game state, not invented. Missing data gets a neutral response. Respect cast token/public edition rules and existing dialogue approvals. No new paid assets.

## Acceptance criteria for a future implementation
- Home, back, close, interruption/resume and save/reload work without input leaks.
- Phone remains legible at supported landscape sizes and accessibility settings.
- Glitch answers accurately for low cash, upcoming rent, shift and mastery changes; locked quest hints reveal no spoilers.
- No repetition spam, no external calls, no new permissions, no real-world advice.
- Existing 2D edition and active kitchen/neighborhood previews remain untouched.
- Actual Godot renders and regression tests accompany the future implementation PR.

## Handoff
This is a queued design idea, not authorization to replace current milestones. Implement after the porch/kitchen gates and daily-life foundations are ready; first audit existing Duffphone UI and state adapters. Keep the studio's internal 9/10 release goal distinct from unmeasured prototype quality.
