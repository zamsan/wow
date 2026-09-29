# Warrior Tank HUD Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a small WoW Forever beta addon that always shows a warrior's health, rage, and Shield Block, Revenge, Taunt, and Thunder Clap states beneath the character.

**Architecture:** Keep client API access in `State.lua` and UI construction in `View.lua`, coordinated by `Core.lua`. Use events for state changes, a short ticker only for visible countdown text, and per-character saved coordinates. Resolve client-specific Interface and spell IDs against the installed beta client before claiming compatibility.

**Tech Stack:** WoW addon TOC, Lua, built-in UI and SavedVariables APIs; local Lua interpreter for isolated tests; beta client for integration tests.

**Spec:** `docs/superpowers/specs/2026-09-29-warrior-tank-hud-design.md`

## Global Constraints

- Show the HUD only for warriors, including outside combat.
- Health and rage appear as bars with current numeric values.
- Shield Block, Taunt, and Thunder Clap show icons, remaining cooldown, and API-reported usability; Revenge highlights when API-reported usable.
- An unlearned or unreadable spell remains inactive; never infer eligibility or automate a cast.
- Drag position persists per character and a reset command restores the initial position.
- Do not assert a WoW Forever Interface version, spell ID, or restricted API behavior before verifying it in the installed beta client.

## Review Focus

- A character with no rage: the bars remain valid and spell readiness matches API values (Task 2).
- Missing or changed spell ID: icon is inactive and no Lua error occurs (Task 2).
- Cooldown ends while standing idle: countdown reaches ready without another combat event (Task 3).
- Saved position is corrupt or off screen: default position is used (Task 3).
- Another class loads the addon: no HUD appears and no Lua error occurs (Task 3).

---

## File Map

- `WarriorTankHUD/WarriorTankHUD.toc`: metadata, per-character settings declaration, and load order.
- `WarriorTankHUD/Core.lua`: warrior gate, events, refresh scheduling, slash reset command.
- `WarriorTankHUD/State.lua`: API adapter and a plain snapshot consumed by the view.
- `WarriorTankHUD/View.lua`: bars, icons, countdown text, drag and saved placement.
- `tests/state.lua`: mocked game API behavior for snapshot tests.
- `tests/view.lua`: mocked frame API behavior for placement and display tests.
- `README.md`: installation, beta compatibility probe, game test checklist.

### Task 1: Client Compatibility Contract

**Files:** Create `WarriorTankHUD/WarriorTankHUD.toc`, `README.md`; inspect the installed beta client's own TOC/UI files when accessible.

**Interfaces:** Produce verified Interface value and spell ID mapping for Shield Block, Revenge, Taunt, Thunder Clap; document observed cooldown/usability API signatures for Task 2. If the client is unavailable, mark these as a game integration gate in README and keep the source configurable without claiming installability.

- [ ] **Step 1: Establish the probe:** Record the beta build and read `## Interface` from a shipped addon TOC; find the four spell IDs from the client's spellbook/API and record the API return shapes in README.
- [ ] **Step 2: Add metadata:** Write the TOC with verified Interface, `SavedVariablesPerCharacter`, and `State.lua`, `View.lua`, `Core.lua` load order. If unverified, keep an explicitly documented packaging placeholder and do not present it as compatible.
- [ ] **Step 3: Check:** Compare README's recorded values against the beta client; inspect TOC load order and metadata; `git diff --check` must exit 0.
- [ ] **Step 4: Commit:** `git add WarriorTankHUD/WarriorTankHUD.toc README.md && git commit -m "chore: establish warrior HUD client contract"`.

### Task 2: State Snapshot

**Files:** Create `WarriorTankHUD/State.lua`, `tests/state.lua`.

**Interfaces:** `WarriorTankHUD.State.Read(api, spellIds)` returns `{ health, healthMax, rage, rageMax, spells }`; `spells` is keyed by `shieldBlock`, `revenge`, `taunt`, `thunderClap`, each value carrying `icon`, `remaining`, `usable`, `known`. `api` wraps verified client calls, while tests inject mocked calls.

- [ ] **Step 1: Write failing tests:** Assert health/rage values; API-reported usability and cooldown for all four spells; zero rage; absent spell; nil API result without an exception.
- [ ] **Step 2: Run:** `lua tests/state.lua` must fail before implementation with a missing module or function error.
- [ ] **Step 3: Implement:** Add `State.Read(api, spellIds)` with explicit nil handling and no combat recommendation or inferred range check; put a one-line comment above every function.
- [ ] **Step 4: Verify:** `lua tests/state.lua` exits 0 with all assertions passing; `git diff --check` exits 0.
- [ ] **Step 5: Commit:** `git add WarriorTankHUD/State.lua tests/state.lua && git commit -m "feat: read warrior HUD state"`.

### Task 3: HUD, Refresh, and Placement

**Files:** Create `WarriorTankHUD/View.lua`, `WarriorTankHUD/Core.lua`, `tests/view.lua`; update `README.md`.

**Interfaces:** `WarriorTankHUD.View.Create(api, savedPosition)` returns a view with `Render(snapshot)` and `ResetPosition()`; Core passes `State.Read(...)` output to `Render`, guards with player class, and owns the per-character SavedVariables table.

- [ ] **Step 1: Write failing tests:** Assert always-visible warrior bars and four icons; no other-class HUD; cooldown text updates after time advances while idle; drag/reload persists; corrupt/off-screen position resets; slash reset restores default.
- [ ] **Step 2: Run:** `lua tests/view.lua` must fail before implementation with a missing view or coordinator function error.
- [ ] **Step 3: Implement:** Create native frames at a fixed screen anchor below the character, render state, bind verified client events and a countdown ticker, save drag position, add reset command, and handle API failures as inactive; put a one-line comment above every function.
- [ ] **Step 4: Verify locally:** `lua tests/state.lua && lua tests/view.lua` and `git diff --check` exit 0.
- [ ] **Step 5: Verify in beta:** Install under the client's `Interface/AddOns`; test the six spec criteria including actual Revenge activation and each cooldown, relog, and another class. Record build and any failures in README. Do not claim game compatibility if this step cannot run.
- [ ] **Step 6: Commit:** `git add WarriorTankHUD/View.lua WarriorTankHUD/Core.lua tests/view.lua README.md && git commit -m "feat: add warrior tank HUD"`.
