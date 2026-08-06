# Gamepad / Console Navigation — Design & Implementation Plan

Branch: `v2_addConsoleNavigation`

Goal: make the fight report fully operable with a gamepad in ESO's gamepad-preferred mode —
move a focus between panels, scroll and select inside lists, read tooltips, and reach every
menu-bar action through the keybind strip or the `Y` menu.

This document is the research result and the staged plan. It is written so panels can be
converted one at a time; each phase leaves the addon in a working state on PC. Console is
all-or-nothing — there is no mouse there, so the addon is only usable once every panel is
converted (§1, third constraint).

The plan started from assumptions read out of the ESO UI source rather than a running client.
**§0 records what checking them in game returned** — several answers changed the design rather
than confirming it, and the sections that follow are written against those answers.

The input scheme in §3.3 is the second one. The first was pure vanilla — stick between areas,
shoulders cycling the category — and it did not survive measuring the layout or discovering that
the d-pad was reachable after all. **§7.7 records why it changed**; read it before proposing a
return to stick-driven area movement.

---

## 0. Verified assumptions

Everything below rested on assumptions read out of the ESO UI source rather than a running client.
They have all been checked in game; the throwaway probes that did it are gone. What remains is the
record of what came back, because the rest of the plan is built on it.

### 0.1 Working in gamepad mode

| Need | How |
| --- | --- |
| Switch to gamepad-preferred mode | `/script SetSetting(SETTING_TYPE_GAMEPAD, GAMEPAD_SETTING_INPUT_PREFERRED_MODE, INPUT_PREFERRED_MODE_ALWAYS_GAMEPAD)` — or Settings → Gameplay → Input Preferred Mode. Value `0` = `ALWAYS_KEYBOARD`, `1` = `ALWAYS_GAMEPAD`, `2` = `AUTOMATIC`. |
| Switch back | same call with `INPUT_PREFERRED_MODE_ALWAYS_KEYBOARD` |
| Confirm which mode is live | `/script d(IsInGamepadPreferredMode())` |
| Open / close the report | `/cmx` ([util.lua:167](../CombatMetrics/util.lua)), or the `CMX_REPORT_TOGGLE` binding |
| Get a fight to look at without combat | Nothing to do — `test/test.lua` defines `CMX_TestData` and [init.lua:277](../CombatMetrics/init.lua) adds it as a fight on load. |
| Reload after a code change | `/reloadui` |

`d(...)` prints to chat. The chat input truncates a command at 350 characters and silently drops
the rest, so anything longer belongs in a file. For a multi-step check, drop a scratch file into
the addon behind its own slash command, and delete it once the answer is recorded here.

### 0.2 What the checks found

| # | Question | Answer |
| --- | --- | --- |
| A1 | Report opens in gamepad mode? | Yes |
| A2 | Mouse still usable there? | Yes in gamepad-preferred mode on PC — but **not on console**, so this cannot be leaned on (§1, third constraint) |
| A3 | Mode switch while open — what happens? | Report closes |
| A4 | Tooltips appear without mouse movement? | Yes |
| B1 | All required `ZO_*` functions exist? | Yes |
| B2 | `FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW` exists? | Yes |
| B3 | QUATERNARY / QUINARY bound on gamepad? | QUATERNARY = hold X (172). QUINARY = 0, unbound — assumed bound anyway |
| C1 | Keybind strip shows on the CMX scene? | Yes. But keyboard mode also gains `Menu: Exit`, and the group is not re-evaluated on reopen → gate on gamepad mode, swap on the mode event |
| C2 | Hold-A delivers a clean down/up pair? | Yes — one DOWN, one UP, tap and hold alike. Removing the group mid-hold fires no UP, so §7.5's `IsKeyDown` clear is required |
| C3 | Who else consumes directional input? | HUD 1, report 2, dialog-over-report 4 — they stack, so §5.1 navigator deactivation is mandatory |
| C4 | Sort header focus invisible without a template? | Yes — but **moot**: §3.3 dropped the header focus area, so nothing needs the template |
| C5 | Two row highlights distinguishable? | Yes with an outline against the selection fill — now `CombatMetrics_RowCursor`. Mouse-over had never been wired; §0.3 wires it to share that outline |
| C6 | Gamepad dialog overlays the report? | Yes — draws above, stick-navigable, strip swapped and restored |
| D1 | `FightReport:Update()` cost per row? | ~4 ms on a small fight (lower bound) → §5.2 item 4 is required in phase 1 |

The gamepad button map, since three later sections depend on it. Note the second argument to
`GetHighestPriorityActionBindingInfoFromName(action, preferGamepad)` — pass `true`, or it returns
the *keyboard* binding and every action looks bound.

| Action | Code | Key |
| --- | --- | --- |
| `PRIMARY` | 133 | `GAMEPAD_BUTTON_1` — A |
| `SECONDARY` | 135 | `GAMEPAD_BUTTON_3` — X |
| `TERTIARY` | 136 | `GAMEPAD_BUTTON_4` — Y |
| `QUATERNARY` | 172 | `GAMEPAD_BUTTON_3_HOLD` — **hold X** |
| `QUINARY` | 0 | none — **unbound by default** |
| `NEGATIVE` | 134 | `GAMEPAD_BUTTON_2` — B |
| `LEFT_SHOULDER` / `RIGHT_SHOULDER` | 131 / 132 | LB / RB |
| `LEFT_TRIGGER` / `RIGHT_TRIGGER` | 137 / 138 | LT / RT |
| `LEFT_STICK` / `RIGHT_STICK` | 129 / 130 | L3 / R3 |
| `INPUT_UP` / `INPUT_DOWN` | 123 / 124 | `GAMEPAD_DPAD_UP` / `_DOWN` |
| `INPUT_LEFT` / `INPUT_RIGHT` | 125 / 126 | `GAMEPAD_DPAD_LEFT` / `_RIGHT` |

**Gamepad codes start at 123 (`KEY_GAMEPAD_DPAD_UP`), not 133.** An earlier draft of this document
claimed 133 and told the reader to treat anything lower as a keyboard key — that heuristic would
misread every d-pad binding (123–126), Start/Back (127/128) and both stick clicks (129/130). The
real layout is 123–126 d-pad, 127/128 Start/Back, 129/130 stick clicks, 131/132 shoulders, 133–136
face buttons, 137/138 triggers. Three consequences run through the rest of the plan:

- **`UI_SHORTCUT_INPUT_*` is the d-pad, and it is a keybind-strip action.** All four route through
  `ZO_KeybindStrip_HandleKeybindDown` (`ingame/globals/bindings.xml:649-667`), so an addon binds
  them exactly like `PRIMARY`. This is the *only* way an addon reaches the d-pad — the
  `DIRECTIONAL_INPUT` route is closed (§1 constraint 1) — and the two paths are independent, so a
  d-pad bind cannot double-fire against the navigator's analog stick read. §3.3 spends all four.
  Do not confuse them with `UI_SHORTCUT_LEFT_STICK_UP` / `RIGHT_STICK_UP` and friends, which
  `return false` and exist only so keyboard keys emulating stick input can be rebound.
- **`QUATERNARY` is not a fifth button.** It is *hold X* — the same physical button as `SECONDARY`
  (tap X). A panel defining both puts them on one button, and the tap only resolves on release, so
  frequency decides which gets the tap (§3.3, §7.4).
- **`QUINARY` is unbound**, and nothing in this plan uses it. Anything placed there must degrade to
  unreachable-but-harmless, never to a broken panel.

Prominence, measured as `keybind = "UI_SHORTCUT_X"` descriptor counts across `ingame/` and
`libraries/`, since "what will a player recognise" decided several assignments below:
`PRIMARY` 242 · `SECONDARY` 146 · `TERTIARY` 111 · `NEGATIVE` 81 · `QUATERNARY` 54 ·
`RIGHT_STICK` 38 · `LEFT_TRIGGER` / `RIGHT_TRIGGER` 18 each · `LEFT_STICK` 18 · `QUINARY` 18 ·
`LEFT_SHOULDER` / `RIGHT_SHOULDER` **8 / 7** · `INPUT_LEFT` / `INPUT_RIGHT` 3 / 4 ·
`INPUT_UP` / `INPUT_DOWN` 0. The shoulders being rarer than R3 is worth knowing: repurposing them
costs less convention than it appears to.

### 0.3 Decisions taken

- **The row cursor is an outline, not a fill.** The selection mark
  (`CombatMetrics_Highlight`) is a white fill, so a second fill for the cursor reads as a brighter
  version of the same thing rather than a different mark. The winner of C5 is
  `CombatMetrics_RowCursor` ([templates.xml](../CombatMetrics/ui/base/templates.xml)) — CMX's own
  `simpleframe2.dds` with a gold edge over a transparent centre, left edge inset to clear the
  first column. Its `offsetX` is a fixed value and does not yet follow `ui.dx`; the production
  wiring must put it in the scaled layout record `storeOrigLayout` expects.
- **The row mouse-over highlight is registered but never triggered.**
  `ZO_ScrollList_EnableHighlight` is called in
  [scroll_lists.lua:112](../CombatMetrics/ui/base/scroll_lists.lua), but no row template wires
  `OnMouseEnter` / `OnMouseExit` and nothing calls `ZO_ScrollList_MouseEnter`, so it has never
  drawn — this predates the gamepad work.
  **Decided: wire it, sharing the cursor's art.** Mouse-over and gamepad focus mean the same
  thing — "the row the pointer is on" — so one look serves both and the row still has only two
  distinct marks: the selection fill and the gold outline. This is a PC-only improvement; on
  console the mouse path never runs, so it must never become the only way anything is shown.

  Two mechanics to respect when implementing:
  - They are *separate* ZO systems. `highlightTemplateOrFunction` (mouse-over) and
    `selectionTemplate` (cursor) each create their own child on the row, so pointing both at the
    same template yields two identical outlines if both are ever live — the mouse hovering row A
    while the cursor sits on row B would show two "current" rows.
  - Both `Enable*` calls latch on first use and ignore later ones
    (`scrolltemplates.lua:1513`, `:1552`), so the template cannot be swapped at runtime. Register
    both once with the same template and gate which one is *driven*: skip the row's
    `OnMouseEnter` / `OnMouseExit` when `IsInGamepadPreferredMode()`, and do not move the cursor
    outside it. This is the same mode gate §3.2 already applies to the fragments.
- **`CMXint.BuffContextMenu`** ([buffs.lua:106](../CombatMetrics/ui/panels/buffs.lua)) is defined
  but has no caller anywhere in the addon — it is v1 behaviour awaiting re-wire.
  **Confirmed: split as planned** — collapse → X, favourite → QUATERNARY (hold X), the two
  post-uptime entries → the Y menu.

  Y is the right slot for that menu: it is what vanilla gamepad UI uses for "a list of further
  actions" — `SI_GAMEPAD_CRAFTING_OPTIONS`, `SI_GAMEPAD_INVENTORY_ACTION_LIST_KEYBIND`,
  `SI_GAMEPAD_DYEING_OPTIONS`, `SI_GAMEPAD_OPTIONS_MENU` and
  `SI_GAMEPAD_INVENTORY_EQUIPPED_MORE_ACTIONS` all sit on `UI_SHORTCUT_TERTIARY`.
- **`util.PostBuffUptime` exists** ([util.lua:382](../CombatMetrics/util.lua)) but
  `util.PosttoChat` is commented out, so the units post-DPS menu has no implementation to call.
  **Decided: build the units Y menu anyway**, with the `PosttoChat` call written out and commented
  with a `TODO:`. The menu shape is then already correct and re-enabling it is one line, rather
  than a hidden bind nobody remembers to add later.

### 0.4 Still worth measuring

Neither blocks phase 1.

- **D1 on a raid-length fight.** ~4 ms came from the smallest fight available. Past ~8 ms the
  deferral in §7.5 needs frame coalescing rather than a plain debounce.
- **What the report's existing directional-input consumer is.** C3 counted 1 on the HUD and 2 with
  the report open, though CMX registers none. The navigator will sit *on top of* whatever that is,
  so a converted report should read 3 — worth confirming that is what happens.

---

## 1. What the game gives us

Everything needed already exists in the ESO UI library. No custom input polling is required.

| Need | ESO facility | Source |
| --- | --- | --- |
| Read stick / d-pad as discrete steps | `ZO_MovementController` + `DIRECTIONAL_INPUT` | `libraries/zo_movementcontroller`, `libraries/zo_directionalinput` |
| A focus that walks a set of arbitrary controls | `ZO_GamepadFocus` | `libraries/zo_focus/gamepad/zo_gamepadfocus.lua` |
| Switching focus between several *areas* (our panels) | `ZO_GamepadMultiFocusArea_Manager` / `_Base` | `libraries/zo_focus/gamepad/zo_gamepadmultifocusareamanager.lua` |
| Gamepad cursor + scrolling inside a `ZO_ScrollList` | `ZO_ScrollList_EnableSelection`, `ZO_ScrollList_SelectNextData` / `SelectPreviousData`, `ZO_ScrollList_AutoSelectData`, `ZO_ScrollList_AtTopOfList` / `AtBottomOfList` | `libraries/zo_templates/scrolltemplates.lua` |
| A gamepad-ready `ZO_SortFilterList` | `ZO_SortFilterList_Gamepad` | `libraries/zo_sortfilterlist/gamepad/zo_sortfilterlist_gamepad.lua` |
| Focus + sorting on column headers | `ZO_SortHeaderGroup:EnableSelection` / `SetSelectedIndex` / `EnableHighlight` | `libraries/zo_sortheadergroup/zo_sortheadergroup.lua` |
| On-screen button prompts | `KEYBIND_STRIP:AddKeybindButtonGroup` with `UI_SHORTCUT_*` actions | `libraries/zo_keybindstrip` |
| Scene wiring for a gamepad window | `FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW` | `ingame/scenes/ingamefragmentgroups.lua` |
| Scroll a plain `ZO_ScrollContainer` (champion points) | `ZO_Scroll_ScrollRelative`, `ZO_Scroll_ScrollControlIntoView` | `libraries/zo_templates/scrolltemplates.lua` |

The reference implementation to copy the *shape* from is
`libraries/zo_sortfilterlist/gamepad/zo_interactivesortfilterlist_gamepad.lua`: a manager that
owns several `ZO_GamepadMultiFocusArea_Base` subclasses (filters / headers / list), each with an
activate + deactivate callback and its own keybind descriptor.

### Three hard constraints

1. **Only one object may consume directional input.**
   `DIRECTIONAL_INPUT:GetX/GetY` *consume* the device once a non-zero value is read
   (`zo_directionalinput.lua:183-234`). If both the multi-focus manager and, say,
   `ZO_SortFilterList_Gamepad`'s own controller are activated, one of them silently eats the
   input. ESO's own code avoids this: `GamepadInteractiveSortFilterFocus_Panel:HandleMovement`
   calls `self.manager:MoveNext()` instead of activating the list's controller.
   → **CMX will register exactly one `UpdateDirectionalInput` consumer** (the navigator), and
   focus areas translate its results into panel actions. Never call
   `SetDirectionalInputEnabled(true)` on a list or a header group.

   **And it may only read the stick, never the d-pad.** `ZO_MovementController`'s default
   magnitude query is `DIRECTIONAL_INPUT:GetY(ZO_DI_LEFT_STICK, ZO_DI_DPAD)`, and the `ZO_DI_DPAD`
   branch calls `IsKeyDown` (`zo_directionalinput.lua:281`, `:316`). `IsKeyDown` is **private** —
   an addon-driven poll dies with *"Attempt to access a private function 'IsKeyDown' from insecure
   code"*, every frame, as soon as the navigator is active. Found the hard way in game.
   → Build the navigator's two controllers with a `magnitudeQueryFunctionOverride` restricted to
   `ZO_DI_LEFT_STICK`; the stick queries (`GetGamepadOrKeyboardLeftStickX/Y`) are public.

   The same wall takes out `DirectionalInput:GetLeftTriggerMagnitude` / `GetRightTriggerMagnitude`
   (`zo_directionalinput.lua:332`, `:342`), so **analog trigger pressure is unavailable too** —
   though LT and RT work fine as ordinary keybind-strip actions, which is all §3.3 needs.

   **This does not cost us the d-pad.** It is reachable through the *other* path:
   `UI_SHORTCUT_INPUT_UP` / `_DOWN` / `_LEFT` / `_RIGHT` are keybind-strip actions bound to
   `KEY_GAMEPAD_DPAD_*` (§0.2), so four ethereal binds give full d-pad navigation with no
   `DIRECTIONAL_INPUT` involvement. The two paths are independent — the navigator polls only the
   analog left stick, the strip handles the d-pad — so nothing double-fires. §3.3 uses all four.
   `ZO_DI_RIGHT_STICK` is likewise clean (`GetGamepadOrKeyboardRightStickX/Y`, no `IsKeyDown`) and
   remains unspent, should a second analog axis ever be wanted.

2. **Switching input mode while the report is open closes it.**
   `ZO_IngameSceneManager:OnGamepadPreferredModeChanged` (`ingame/scenes/ingamescenemanager.lua:202`)
   forces the HUD when `scene:WasRequestedToShowInGamepadPreferredMode() ~= IsInGamepadPreferredMode()`.
   That is acceptable behaviour (matches every stock screen), and C1 confirmed it still holds with
   the gamepad fragment group applied.
   It does not make the fragments self-correcting, though: C1 showed a keyboard-mode *reopen*
   still wearing the gamepad strip. The group has to be swapped on the mode change (§3.2); the
   forced close just means the swap always runs against hidden scenes.
   If we ever want to keep the window open across the switch,
   `scene:SetHandleGamepadPreferredModeChangedCallback(fn)` is the hook — returning `true` from it
   suppresses the forced HUD, and the callback would rebuild the fragments and the navigator.

### The third constraint: there is no mouse to fall back on

Addons run on console, where **no mouse exists at all**. Gamepad-preferred mode on PC is not the
target — it is only the nearest thing that can be driven from a dev machine, and even there the
cursor reappears the moment the mouse moves (`HIDE_MOUSE_FRAGMENT` calls
`HideMouse(ONLY_CONSIDER_MOUSE_VISIBILITY_WHILE_MOVING)`), which flatters the result. Use
**ConsoleFlow** on PC to test true console conditions, with the mouse genuinely gone.

→ **Gamepad navigation is not additive, it is a replacement.** Anything reachable only by pointing
at it is unreachable on console: an unconverted panel is not "still usable with the mouse", it is
dead. Every interaction the report offers needs a gamepad route before the addon is usable there.

This does not change how the work proceeds — phases still land one panel at a time, developed and
checked in gamepad-preferred mode — only what "finished" means at the end of them. CMX is not on
console yet, so there is no deadline and nothing to regress; the bar is simply that *every* panel
is converted before a console release, not "enough of them". Two working rules follow:

- A panel with no focus area is a hole in the console build, not a graceful degradation. §3.1's
  `CreateFocusArea()` returning `nil` is fine throughout development and not at the end of it.
- Anything that today only has a mouse affordance — hover tooltips, drag-to-move, right-click
  menus, the resize grip — needs an explicit gamepad equivalent or an accepted decision that it is
  PC-only. §7 assigns a mechanism to every action for exactly this reason; check it for gaps
  before declaring a phase complete.

---

## 2. Current state of CombatMetrics

What already helps:

- Panels are objects (`CMXint.PanelObject`) registered in `ui.panels`, each with a
  `control`, `scenes`, `Update` / `Clear` / `Recover` — the natural granularity for a focus area.
  See [ui/base/ui.lua](../CombatMetrics/ui/base/ui.lua).
- `units`, `abilities`, `buffs` use `ui.SortFilterList`, a `ZO_SortFilterList` subclass
  ([ui/base/scroll_lists.lua](../CombatMetrics/ui/base/scroll_lists.lua)) — so
  `ZO_SortFilterList_Gamepad`'s methods apply almost verbatim.
- Those three panels already get a `sortHeaderGroup` for free, because their XML defines a
  `Headers` child (`ZO_SortFilterList:InitializeSortFilterList` builds it).
- View switching is already scene based ([ui/base/scenes.lua](../CombatMetrics/ui/base/scenes.lua)),
  so "which panels are visible right now" is a well-defined, observable set.
- Tooltip handlers (`CMXint.OnMouseEnter`, `CMXint.SkillTooltip_OnMouseEnter`,
  `CMXint.ItemTooltip_OnMouseEnter`, `CMXint.CPTooltip_OnMouseEnter`) all take a control and read
  `control.data` / `control.tooltip`. They can be called directly from a focus-changed callback;
  none of them depend on `moc()`.

What blocks us:

- `CMX_REPORT_SCENE` and the view scenes carry only `ZO_HUDFadeSceneFragment`. Without
  `UI_SHORTCUTS_ACTION_LAYER_FRAGMENT` the `UI_SHORTCUT_*` actions are not bound, so the keybind
  strip cannot fire, and without a keybind-strip fragment nothing is drawn.
- Every interaction is a mouse handler: row selection
  (`CombatMetrics_RowTemplate` → `CMXint.AddSelection`), sort headers
  (`ZO_SortHeader_OnMouseUp`), menu-bar buttons (`OnMouseUp`), buff expand
  (`OnMouseDown`), title rename (`OnMouseDoubleClick`), window move/resize (drag).
- ~~Sort headers are created without a highlight template~~ — no longer a blocker. Sorting became
  the list's own horizontal axis (§3.3), so `SetSelectedIndex` is never called and nothing has to
  be visible. The headers keep their existing arrow, which is all the state the gamepad path shows.
- The settings and feedback buttons open `LibCustomMenu` context menus, which are mouse-only.
- The free-form panels (`skills`, `equipment`, `champion_points`, `combat_stats`,
  `player_stats`) draw with pooled shared controls and row containers; they have no per-row
  control list to focus and no highlight art.

---

## 3. Architecture

### 3.1 New module: `ui/base/gamepad.lua`

Loaded from [CombatMetrics.addon](../CombatMetrics/CombatMetrics.addon) after
`shared_controls.lua` and before `scenes.lua`. Exposes `ui.gamepad`.

```
ui.gamepad
├── ui.gamepad.navigator      -- singleton, ZO_GamepadMultiFocusArea_Manager subclass
├── ui.FocusArea              -- ZO_GamepadMultiFocusArea_Base subclass, CMX base for panels
├── ui.ListFocusArea          -- ui.FocusArea subclass for SortFilterList panels
└── ui.RowFocusArea           -- ui.FocusArea subclass for row-container panels
```

**Navigator** — one instance for the whole report.

- `Activate()` / `Deactivate()`: `DIRECTIONAL_INPUT:Activate(self, CombatMetricsReport)` /
  `Deactivate(self)`, driven by a `StateChange` callback the navigator registers on each view
  scene itself. `ZO_CallbackObject` chains callbacks, so `scenes.lua` needs no edit — and only the
  *view* scenes are hooked, since the view is pushed over the report scene and both would
  otherwise fire for one open. `SCENE_HIDDEN` deactivates only when no view scene is showing, so
  `SwapCurrentScene` between two views does not tear the navigator down.
- `Rebuild(sceneKey)`: clears the area list and re-adds the focus area of every visible panel,
  sorted by the panel control's `GetLeft()` / `GetTop()` — read off the live layout rather than a
  hardcoded panel list, so the order cannot drift from it. Called from the same `SCENE_SHOWN`
  callback, i.e. once per view switch, and again after a fight change if a panel became empty.
  **This one ordering serves both movers**: it is the stick's sideways chain and the shoulders'
  ring, which is why neither needs a map.
- `UpdateDirectionalInput()` (inherited) → `HandleMoveCurrentFocus(horizontal, vertical)`.
- `CycleArea(delta)`: steps `focusAreas` by ±1 with wraparound, skipping `CanBeSelected() == false`.
  What the shoulders call. Unlike the stick it wraps, so it reaches every area from anywhere.
- Owns the whole global keybind descriptor (§3.3): shoulders, triggers, d-pad, B, hold-X and Y.
  Only `A` and `X` belong to the per-panel areas.
- Only runs when `IsInGamepadPreferredMode()` is true (checked once at `Activate`).

**`ui.FocusArea`** — one panel's worth of focus. It holds **no map of its surroundings**: the ESO
base's `previousFocus` / `nextFocus` chain, ordered spatially by `Rebuild`, is the whole of it.

An earlier draft gave the class a 2D `neighbours` table keyed up/down/left/right, on the reasoning
that CMX's layout is a grid rather than a chain. That was written when the stick was the only way
between panels. With the shoulders owning that job it never acquired a caller, and vertical — the
one direction a chain genuinely cannot express — is exactly the direction the shoulders replaced.
It was deleted rather than left as scaffolding.

```lua
---@class CMXFocusArea : ZO_GamepadMultiFocusArea_Base
---@field panel Panel
---@field canEscape boolean
```

- Override `HandleMovementInternal(horizontal, vertical)`:
  1. give the panel a chance to consume it (`self:HandleMovement(...)` — list scroll, row step,
     sort column),
  2. otherwise apply the **edge latch** (§3.3): if the stick has not returned to neutral since
     this area last refused to move internally, consume the input and stay. One boolean per area
     (`canEscape`), cleared on `Activate` and on any internal move, set when the stick reads
     neutral. This lives in the base because every area can be left sideways,

     Read neutrality off the movement controllers' cached `lastMagnitude`, **not**
     `GetMagnitude()`: the latter goes through `DIRECTIONAL_INPUT:GetX` / `GetY`, which *consume*
     the device for the frame (§1 constraint 1), so polling it would starve the `CheckMovement`
     calls in the same tick and movement would stop entirely. Do the check *after* delegating to
     the base `UpdateDirectionalInput`, which is where `lastMagnitude` is refreshed.
  3. otherwise, **for horizontal moves only**, `GetPreviousSelectableFocusArea` /
     `GetNextSelectableFocusArea` and `manager:SelectFocusArea(next)`. Vertical never leaves an
     area: the chain runs left to right, so stepping it on an up/down push would jump sideways.
- `CanBeSelected()` defaults to "panel control is not hidden **and** the panel has content".
- `Activate` / `Deactivate` show/hide the panel's focus highlight and add/remove the panel's
  keybind descriptor (already handled by the ESO base via `SetKeybindDescriptor`).

**Panel hook.** `PanelObject:GetFocusArea()` returns `self.focusArea`, created lazily.
`PanelObject:CreateFocusArea()` is the per-panel override point; the default returns `nil`,
meaning "this panel is not reachable by the gamepad yet". An unconverted panel is simply skipped
when the navigator rebuilds, which is what lets phases land one at a time — but on console that
panel is unreachable, not merely unconverted (§1, third constraint). Returning `nil` is a
development state, never a shipping one.

### 3.2 Scene wiring (`ui/fight_report.lua`, `ui/base/scenes.lua`)

Add to `CMX_REPORT_SCENE` **and** every `CMX_VIEW_*_SCENE` (fragments must be on the scene that is
actually on top, and the view scene is pushed over the report scene):

- keyboard mode: `FRAGMENT_GROUP.MOUSE_DRIVEN_UI_WINDOW_NO_COMBAT_OVERLAY`
- gamepad mode: `FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW`

Since `ZO_Scene:AddFragmentGroup` / `RemoveFragmentGroup` work at runtime, swap the group on
`EVENT_GAMEPAD_PREFERRED_MODE_CHANGED` while the scenes are hidden, rather than duplicating five
view scenes per input mode. The mode change force-closes the report (§1 constraint 2), so the
scenes are always hidden by the time the handler runs.

**Settled by C1** — the open question was whether the gamepad fragments disturb today's keyboard
path. They do: with `FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW` applied in keyboard mode the report
gains a `Menu: Exit` prompt it never had. So keyboard mode keeps its fragments exactly as they
are, and the gamepad group is added **only** while `IsInGamepadPreferredMode()`.

C1 also showed why the swap is mandatory rather than a tidiness measure: the group is not
re-evaluated on its own, so a report reopened in keyboard mode still carries the gamepad strip.

### 3.3 Input map

**Buttons move between areas; the stick moves within one.** That inversion is the core of this
section and it replaces an earlier draft where the stick did both. See §7 for how every action in
the addon was assigned to one of these rows and why, and §7.7 for what the earlier model got wrong.

| Input | Strip | Scope | Action |
| --- | --- | --- | --- |
| Left stick ↑↓ | – | focused area | Move inside the area — list rows, menu-bar buttons, row containers. |
| Left stick ←→ | – | focused area | The panel's horizontal axis if it has one (a list steps its **sort column**), otherwise move to the spatial neighbour area. |
| `LEFT_SHOULDER` / `RIGHT_SHOULDER` | ethereal | global | Previous / next **panel**. The unconditional escape from any area, at any scroll position. |
| `LEFT_TRIGGER` / `RIGHT_TRIGGER` | ethereal | global | Previous / next **fight** (`SelectPreviousFight` / `SelectNextFight`). |
| `INPUT_LEFT` / `INPUT_RIGHT` (d-pad ←→) | ethereal | global | Previous / next **view**, skipping views whose panel set is empty (§4 phase 2). |
| `INPUT_UP` / `INPUT_DOWN` (d-pad ↑↓) | ethereal | global | Previous / next **category** (damage done → healing done → damage received → healing received). |
| `UI_SHORTCUT_PRIMARY` (A) | visible | focused entry | Select / Deselect a list row; press a menu-bar button. Label is dynamic. |
| `UI_SHORTCUT_NEGATIVE` (B) | visible | global | Clear selections if any (`CMXint.ClearSelections`), otherwise close the report. Two descriptors gated on `visible`, so the label is honest — see §7.6. |
| `UI_SHORTCUT_SECONDARY` (X) | visible | focused row | Panel-defined. `buffs`: Expand / Collapse, visible only when the row `hasDetails`. Absent on `units` and `abilities`. |
| `UI_SHORTCUT_QUATERNARY` (hold X) | visible | global | **Save Fight.** `enabled` and the label come from the same condition `MenuPanel:UpdateButtonStates()` already computes. |
| `UI_SHORTCUT_TERTIARY` (Y) | visible | global | **Menu** (§5.1) — one sectioned dialog: row actions when a row is focused, then the buff filter, the display toggles, and feedback / donate. |
| `RIGHT_STICK` (click) | ethereal | global | Jump straight to the menu-bar area. An alternative route, never the only one. |
| `LEFT_STICK` (click) | ethereal | — | Reserved. |

Each pair has exactly one job: **triggers pick the fight, the d-pad picks the slice of it, the
shoulders pick where you are standing.**

Three notes on the choices, because each replaces something the earlier draft had:

- **The shoulders carry panels, not categories.** The report is a 2×3 grid whose list panels show
  12–14 rows of a 30–60 row dataset, so stick fall-through at a list edge means running the whole
  list out to leave the panel — 3–5 screens on `abilities`, which additionally has no down-neighbour
  and so can only be left *upward*. A button that escapes in one press is not a convenience here,
  it is the difference between usable and not. Categories move to the d-pad, which the earlier
  draft did not know it had.
- **Save is `QUATERNARY` because `QUATERNARY` is physically a hold.** "Long press to confirm intent"
  needs no state machine; the binding *is* the hold. It shares the X button with `buffs`' tap-X
  expand/collapse — accepted, since both are labelled on the strip and the collision exists in
  exactly one panel (§7.4).
- **No sort-header focus area and no buff-filter focus area.** Sorting is the list's own horizontal
  axis and the buff filter is a menu section, so every area in the navigator is now a whole panel.
  Nothing nests, the shoulder ring is 5–6 stops, and §5.2's mandatory header highlight template is
  no longer needed at all.

**The stick leaves an area sideways only.** ←→ that the panel does not consume steps the spatial
chain `Rebuild` builds; ↑↓ never leaves. That asymmetry is deliberate: the chain is ordered left to
right, so stepping it on an up/down push would move the focus sideways while the player pushed
down — worse than doing nothing, and the shoulders are the answer to "get me out of here" anyway.
Keeping A and B out of it still matters: A is select/deselect and B is clear/close, so neither
could double as enter/leave without adding a mode.

**Edge latch — a held stick must not cross an area boundary.** Stock ESO has a wart here that CMX
should not copy. `ZO_MovementController` accelerates a held direction
(`NUM_TICKS_TO_START_ACCELERATING = 5`, `MAX_TICKS_TO_ACCEL_ACROSS = 30`), and nothing guards the
boundary — `IsAtMaxVelocity()`, which exists to detect exactly this, is called in one place in the
entire UI source and it is the housing editor. So a held ← in a panel with no horizontal axis
sweeps the focus across every panel in the row at speed.

The fix is one piece of state per focus area, not a mode: **escape only on a fresh push.** When a
sideways move would leave the area, allow it only if the stick has passed through neutral since
the edge was reached; otherwise consume the move and stay put. Hold ← and you stop at the adjoining
panel. Release, push again, and you cross the next one. This also protects paint-select (§7.5),
where sliding out of the list mid-sweep would be worse than startling.
**The budget.** `ethereal = true` means the bind fires but draws nothing on the strip
(`ingame/armory/gamepad/armorybuildskills_gamepad.lua:80`,
`ingame/guildhistory/gamepad/guildhistory_gamepad.lua:58`). So there are 4 *visible* buttons
(A / X / Y / B) carrying 5 slots — QUATERNARY is hold X, not a button of its own — plus **10**
free ones: two shoulders, two triggers, two stick clicks and four d-pad directions. The map above
spends 8 of the 10, leaving both stick clicks. Cycling actions belong in the free tier, which is
also what ESO does with them (`ingame/champion/champion.lua:701` cycles constellations on the
shoulders, `guildhistory` pages on the triggers).

Resulting strip density: `units` and `abilities` show 4 binds (A, B, hold-X, Y), `buffs` shows 5,
the menu bar 4.

Each focus area owns one keybind group descriptor; `name`, `visible` and `enabled` are functions
so the strip re-reads them per focused row. Call `area:UpdateKeybinds()` whenever the focused
entry, the selection or the fight changes.

---

## 4. Phased implementation

Each phase is a self-contained commit and leaves both input modes working.

### Phase 0 — groundwork, no visible change

- Add `ui/base/gamepad.lua` with the navigator, `ui.FocusArea`, and `PanelObject:GetFocusArea()`
  returning `nil` by default.
- Add the fragment groups to the report and view scenes; verify Escape still pops correctly in
  both modes and that the keybind strip appears with a single dummy "Close" bind.
- ~~Add `settings.fightReport.gamepadNavigation`~~ — **dropped.** `menu.lua` is commented out of
  the manifest, so nothing could toggle it in game, and "default: follow
  `IsInGamepadPreferredMode()`" is not expressible as a literal in `svdefaults` (baking the call in
  at file-load time would freeze the value). The gate is `IsInGamepadPreferredMode()` alone; add a
  setting when the menu comes back, if it turns out to be wanted.
- Navigator activate/deactivate from the view-scene `StateChange` callback.

**Done when:** in gamepad mode the report opens, the strip shows `B — Close`, and B closes it.

**Landed.** Verified in game: strip appears and B closes in gamepad mode, keyboard mode gains
nothing, and the fragment group swaps correctly across a mode change without a reload. Two things
the phase found that changed the design rather than confirming it — the `IsKeyDown` wall (§1
constraint 1, which also invalidates §7.5's guard) and the correct gamepad key-code range (§0.2).

### Phase 0.5 — global binds

Everything in §3.3 that is not panel-specific, landed before any panel gains a focus area so the
report is navigable in the large before it is navigable in the small. All of it lives on the
navigator's own keybind descriptor, which already exists.

- Shoulders → `navigator:CycleArea(±1)` over `self.focusAreas`. With no panel converted yet the
  ring is empty and the binds are inert, which is the correct degradation.
- Triggers → `SelectPreviousFight` / `SelectNextFight`.
- d-pad ←→ → previous / next view, **skipping views whose panel set is empty**. `graph` and
  `fightList` instantiate no panels at all today, so a naive cycle steps through two blank screens;
  deriving "is this view non-empty" from `ui.panels` means views light up by themselves as their
  panels come online, with no list to maintain. Do not persist `settings.scene` for `fightList`
  (§4 phase 2) — it is a picker, not a place to sit.
- d-pad ↑↓ → previous / next category over `util.MainCategories`, then `fightReport:Update()`.
- hold X → Save Fight. Reuse the enabled condition from `MenuPanel:UpdateButtonStates()`
  (`menu_bar.lua:495`) rather than recomputing it, and flip the label when the fight is already
  saved.
- B → the two-descriptor Clear Selections / Close pair (§7.6). `CMXint.IsSelectionActive()` and
  `CMXint.ClearSelections()` already exist at `scroll_lists.lua:218` / `:227`.

**Done when:** with no panel converted, a gamepad can switch fight, category and view, save a
fight, and close — the whole report shell, with the panels still inert.

### Phase 1 — list panels: `units`, `abilities`, `buffs`

The big one, and the one that unlocks most of the value.

- Give `ui.SortFilterList` the `ZO_SortFilterList_Gamepad` behaviour. Prefer *mixing in* the
  methods (`Activate`, `Deactivate`, `MoveNext`, `MovePrevious`, `ResetToTop`) over re-parenting
  the class, and **omit** `SetDirectionalInputEnabled` — per constraint 1 the navigator drives
  movement. Call `ZO_ScrollList_EnableSelection(self.list, <CMX highlight template>, cb)` in
  `SortFilterList:Initialize`.
  - Note the naming collision: `ZO_ScrollList`'s *selection* is the gamepad cursor, while CMX's
    `SelectionHandler` (`selectedItems`, the `HighLight` child of each row) is the multi-select
    used for filtering. They are independent; give the new one a distinct template so the two
    highlights are visually different.
- `ui.ListFocusArea`:
  - `HandleMovement`: vertical → `MoveNext` / `MovePrevious`; **horizontal → step the sort column**,
    `sortHeaderGroup:OnHeaderClicked(nextHeader)`. The header's own arrow already renders which
    column is active (`usesArrow = true`), so this needs no new art and no second focus area.
    Skip the plain `Label` columns — `PerCent` in `units`, `Crits` and `Hits` in `abilities` are
    not sort headers, so the chain has gaps.
  - **Do not override `HandleMovePrevious` / `HandleMoveNext`.** Vertical no longer escapes an
    area at all (§3.3), so `AtTopOfList` / `AtBottomOfList` never need testing — ↑ at the first row
    and ↓ at the last simply do nothing, and the shoulders are the way out. The base class's
    versions walk the sibling chain, so leave them shadowed by returning `true` from
    `HandleMovement` for every vertical input the list receives.
  - `CanBeSelected`: `self.panel.dataList:HasEntries()`.
  - `Activate`: `ZO_ScrollList_AutoSelectData(list, ANIMATE_INSTANTLY)`; `Deactivate`:
    `ZO_ScrollList_SelectData(list, nil)`.
  - Keybinds: A toggles the focused row, and **holding A while moving paints a range** — see
    §7.5 for the state machine, the stuck-state guard and the update-cost constraint.
    Refactor `SelectionHandler:HandleClick` first so the gamepad path does not have to fake a
    mouse button: extract `Toggle(id)` / `SetSelected(id, state)` / `SelectRange(id)` as
    primitives that do **not** call `fightReport:Update()`, and let each caller decide when to
    update. `HandleClick` keeps the mouse-button/modifier decoding and calls them.
- ~~Column headers as a second focus area~~ — **dropped.** Sorting is the list's horizontal axis
  (above), so there is no header area, no `sortHeaderGroup:EnableSelection`, and **no highlight
  template needed** — which retires §5.2 item 1 and check C4 entirely.
- ~~`buffs` `SearchBar` as a third focus area~~ — **dropped.** Player / Group / Enemy becomes a
  section of the `Y` menu (§5.1). The `ZO_RadioButtonGroup` stays exactly as it is for the mouse;
  the menu entries drive the same callbacks. Note the visual order is Player, Group, Enemy — the
  reverse of both the XML declaration order and the order `radioButtons:Add` walks.
- `buffs` keybinds: A stays "select", expand/collapse is `X` with a dynamic label, visible only
  when the row `hasDetails`. **Favourite moves to the `Y` menu**, because `QUATERNARY` is now the
  global Save Fight (§3.3). `CMXint.BuffContextMenu`
  ([buffs.lua:106](../CombatMetrics/ui/panels/buffs.lua)) already contains all four actions but has
  **no caller** — it is pending re-wire from the v1 code. Split it when re-wiring: collapse becomes
  the `X` bind, favourite and the two "post uptime" entries become `Y` menu rows.
- Tooltips: on focus change call the existing handler with the focused row control.

**Done when:** the three list panels can be entered with the shoulders, scrolled, sorted with ←→
and (multi-)selected with a gamepad, and the numbers in the other panels react to the selection as
they do with a mouse.

### Phase 2 — the `Y` menu, and the menu bar as an alternative route

**Every menu-bar action already has a bind or a menu entry by the end of phase 0.5.** Category is
the d-pad, views are the d-pad, fight nav is the triggers, save is hold-X, settings and feedback
are `Y` menu sections. So the menu bar is no longer a route anything depends on — it becomes a
focus area because it is cheap and some players will prefer pointing at a button, not because the
console build needs it. Build the `Y` menu first; the focus area is the smaller half.

**The `Y` menu** (`CMXint.ShowGamepadMenu`, §5.1) — one registered dialog, list rebuilt per
invocation, `header` starting each section:

| Section | Entries |
| --- | --- |
| *(row actions — only when a list row is focused)* | Post DPS / unit-name DPS / selection DPS / selection HPS, or the buff-uptime variants |
| **Panel** | `buffs`: Show Player / Group / Enemy · Add / Remove Favourite |
| **Options** | Show IDs · Show Overheal · Show Pets |
| **About** | Feedback ▸ · Donate ▸ |

The Options rows are toggles, so they need `blockDialogReleaseOnPress = true` and a rebuild in
place (§5.1). The About rows are one-shot and release.

**The menu bar focus area:**

- `ui.ButtonFocusArea` (a thin `ui.RowFocusArea`, see phase 3) over
  `MenuPanel.categoryButtons`, `.sceneButtons`, `.settingsButton`, `.feedbackButton`,
  `.navButtons`, in visual order. It is the leftmost area, so ← from the leftmost panel lands
  on it and ↑↓ walk the buttons. **Skip `notificationButton`** — it is `SetHidden(true)` at
  `menu_bar.lua:353` yet still occupies its 32 px of column, so it cannot be inferred from geometry.
- Entry `activate` → `CMXint.OnMouseEnter(button)` (they all carry `button.tooltip` already).
- A → the button's existing handler. Note the handlers are written as `OnMouseUp(button, ...)`
  and some read the `shift` argument (`SaveFight`); extract the body into a plain function so
  both callers can use it rather than faking mouse arguments.
- `canFocus` per entry ← `MenuPanel:UpdateButtonStates()`, which already computes exactly this;
  a `BSTATE_DISABLED` button must not be focusable. Only the 6 nav buttons ever disable.
- The **settings and feedback buttons open `LibCustomMenu` context menus**, which have no gamepad
  path at all. In gamepad mode their A press opens the `Y` menu scrolled to the corresponding
  section rather than reimplementing them.

**The `fightList` view.** It is already a scene (`VIEW_SCENE_KEYS`), so the d-pad view cycle reaches
it for free once the panel exists — but treat it as a picker, not a place to sit: A loads the
focused fight *and* returns to the previous view, and `SelectScene` must not persist
`settings.scene = "fightList"`, or the report reopens into the picker instead of the data. Its
strip is A — Load, B — Back, X — Delete, plus the global hold-X.

### Phase 3 — row-container panels: `skills`, `equipment`, `champion_points`

These have no scroll list; a `ZO_GamepadFocus` over the row containers is the right tool.

- `ui.RowFocusArea` owns a `ZO_GamepadFocus` and rebuilds its entries in the panel's `Update`
  (the containers change with the fight). Entry `control` = the row container, `highlight` = a
  new pooled `Backdrop` shared control, `activate` / `deactivate` = the existing tooltip
  handlers.
- Because entries are rebuilt on every `Update`, `RemoveAllEntries()` + re-`AddEntry` and then
  restore the index; `ZO_GamepadFocus` keeps `savedIndex` across `SetActive(false/true)`.
- `champion_points` additionally needs the focused container scrolled into view:
  `ZO_Scroll_ScrollControlIntoView(scrollContainer, container)` from the focus-changed callback.
- `skills`: X pages between skill bars (the existing `pageButton` handler).
- The highlight needs a shared-control type. Add `CT_BACKDROP` to `SharedControlManager` in
  [ui/base/shared_controls.lua](../CombatMetrics/ui/base/shared_controls.lua), or — simpler — give
  the row-container template a permanent hidden `Highlight` child so no new shared type is
  needed. Prefer the latter; it also survives the pool reset.

### Phase 4 — read-only panels and polish

This phase is what turns a staged rollout into a shippable console build — until it lands, the
gaps below are unreachable rather than merely unpolished (§1, third constraint).

- `combat_stats`, `player_stats`, `info_row`, `title_bar`: no per-row targets. Skipping them
  (`CreateFocusArea` stays `nil`) is fine *only* if they carry no information that needs a focus
  to reveal. Check each for hover tooltips first: a tooltip with no gamepad route is content a
  console player cannot read, and that panel then needs a single focus stop that shows it.
- Window position/size: dragging and the resize grip are mouse-only and have no console
  equivalent. Add gear-menu entries (§5.1) to nudge position and change scale
  (`FightReport:Resize`), or accept centred+fixed — but decide, rather than leaving it to the
  mouse.
- Title rename (`OnMouseDoubleClick` → edit box): gamepad text entry needs `ZO_GamepadEditBox`.
  Either wire it or declare rename PC-only — both are fine, but record which, since "deferred"
  reads as a gap on console.
- Screen narration (`SCREEN_NARRATION_MANAGER`) — nice to have, mirrors what
  `ZO_SortFilterList_Gamepad` does. Optional.

### Phase 5 — live report

`ui/live_report.lua` is a HUD overlay with no interaction beyond drag/lock; it needs nothing
unless we want gamepad repositioning. Out of scope for now.

---

## 5. Known problems to solve before the phase that needs them

### 5.1 Context menus

`ZO_Menu` (`ClearMenu` / `AddCustomMenuItem` / `ShowMenu`) is mouse-driven, and LibCustomMenu —
which CMX depends on — has no gamepad path at all (no `IsInGamepadPreferredMode` anywhere in it).
So the two menus behind the gear and feedback buttons need a replacement — and the scheme in §3.3
leans on that replacement much harder than the original did, because **`Y` is now the single home
for everything that is not a bind**: the gear toggles, feedback and donate, the `buffs` filter and
favourite, and the row post-to-chat actions. One dialog, sections chosen by what is focused.

What goes in it:

| Section | Entries | Nature |
| --- | --- | --- |
| *(row actions)* | ~7 chat-post variants, only when a list row is focused | one-shot, context-dependent |
| Panel | `buffs`: Show Player / Group / Enemy, Add / Remove Favourite | radio group + one toggle |
| Options | show/hide IDs, overheal, pets | 3 booleans, label flips with state |
| About | *Feedback*: mail (EU only), ESOUI, GitHub, Discord — *Donate*: gold (EU only), ESOUI | 6 one-shot actions, one nesting level, 2 conditionally disabled |

**Use ESO's own context-menu replacement: a registered `GAMEPAD_DIALOGS.PARAMETRIC` dialog whose
list is built per invocation.** The precedent is `GAMEPAD_SOCIAL_OPTIONS_DIALOG`
(`ingame/contacts/gamepad/socialdialogs_gamepad.lua:60` + `zo_socialoptionsdialog_gamepad.lua`),
which is literally the gamepad stand-in for the right-click context menu on the friends and
guild lists. The mechanism is `dialog.info.parametricList = data.parametricList` inside `setup`,
so **one** registered dialog serves every call site.

Add one helper in `ui/base/gamepad.lua`:

```lua
-- entries: { { text = <string>, callback = <fn>, enabled = <bool>, header = <string?> }, ... }
CMXint.ShowGamepadMenu(titleString, entries)
```

- Registers `CMX_GAMEPAD_MENU_DIALOG` once, with `DIALOG_PRIMARY` = "Select" and
  `DIALOG_NEGATIVE` = "Cancel".
- `header` on an entry starts a section, which is how the *Feedback* / *Donate* submenus
  flatten — nesting is not needed, and stock screens (e.g. the achievements options dialog,
  `ingame/achievements/gamepad/achievements_gamepad.lua:410`) group exactly this way.
- Disabled entries: build them with `entryData:SetEnabled(false)`; keeps the "EU server only"
  behaviour the keyboard menu has today.
- **Toggles must not close the dialog.** Set `blockDialogReleaseOnPress = true`, and in the
  primary callback re-run the builder and `dialog:setupFunc()` so the label flips in place —
  the pattern in `ingame/antiquities/gamepad/antiquityjournal_gamepad.lua:279`. One-shot
  entries call `ReleaseDialog` afterwards.
- Call sites stay symmetrical: `if IsInGamepadPreferredMode() then CMXint.ShowGamepadMenu(...)
  else ClearMenu() … ShowMenu(button) end`, with the entry table built once and consumed by
  both branches. That keeps the keyboard menu untouched.

Two mechanics to respect:

- Deactivate the navigator while the dialog is up and re-activate on the `AllDialogsHidden`
  callback (`ZO_GamepadInteractiveSortFilterList` registers for exactly this). **Required, not
  defensive**: C3 measured the directional-input consumer count going 2 → 4 when a dialog opens
  over the report, so the dialog *stacks* on what is already registered rather than replacing it.
  A navigator left active underneath is exactly the two-consumer collision §1 constraint 1
  describes.
- The dialog pushes its own keybind state, so the CMX strip is hidden while it is open and
  restored on close. Nothing to do, just do not fight it.

`RequestOpenUnsafeURL` (the ESOUI / GitHub / Discord entries) needs no change: the client shows
its own confirmation in either input mode.

### 5.2 Everything else

1. ~~**Sort headers have no highlight template.**~~ **Retired.** There is no header focus area any
   more (§3.3, §7.7), so nothing needs a highlight. Check C4 is likewise moot.

2. **`ui.sharedControls` lifetime vs. focus entries.** A panel releases its shared controls in
   `PanelObject:Release()` when it hides. Any `ZO_GamepadFocus` entry pointing at a released
   control is a dangling reference of exactly the kind
   `PanelObject:VerifySharedControls()` was written to catch. Rule: focus entries must reference
   **row containers and XML controls only**, never a pooled shared control, and
   `RowFocusArea` must clear its entries from the panel's `Release`.

3. **Scroll-list rows are recycled.** `ZO_ScrollList`'s own selection is data-based, not
   control-based, so it survives a commit — this is why phase 1 uses `ZO_ScrollList_EnableSelection`
   rather than a `ZO_GamepadFocus` over row controls.

4. **`FightReport:Update()` runs on every selection change — debounce it in phase 1.** Not a
   "verify if": D1 measured ~4 ms on the *smallest* available fight, a quarter of a 60 fps frame
   for one selection change, and a gamepad cursor moves a row per tick. Split the
   `SelectionHandler` → `Update` path so mutation and update are separate, and coalesce the
   update. Re-measure on a raid-length fight: past ~8 ms the deferral in §7.5 needs frame
   coalescing rather than a plain debounce.

---

## 6. Testing

- Manual, in game, with `/taneth` unaffected: the navigator is UI-only and cannot be covered by
  the existing headless suites (`CombatMetricsTests`, `LibCombatTests`), which deliberately load
  only non-UI files.
- `test/test.lua` provides a hard-coded fight, so gamepad navigation can be exercised without
  live combat — use it for every phase.
- Per-phase checklist, in gamepad-preferred mode: open in gamepad mode → strip shows → every
  visible panel reachable → every panel's content reachable → B closes → reopen restores the
  previous focus → switch to keyboard mode and confirm mouse behaviour is unchanged.
- **ConsoleFlow is the acceptance pass, run rarely.** Gamepad-preferred mode keeps a live mouse
  cursor, so a panel reachable only by pointing still *looks* fine there; ConsoleFlow is the only
  setting where "reachable" means what it means for a console player (§1, third constraint). It
  also costs real setup — other addons have to come off first — so it is not a per-phase step.
  Run it once the phases it would cover are all in, and bank questions for it in the meantime.

  Worth banking, because only ConsoleFlow can answer them:

  - Is every panel reachable, and every panel's content reachable, using nothing but the pad?
  - Does any tooltip carry information with no gamepad route to it?
  - Do the strip prompts match the buttons that actually work, with no stale or missing entries?
  - Does the report survive open → dialog → close → reopen without losing focus or input?

---

## 7. Decision overview

Settled before implementation so no phase has to re-litigate it. Every user-facing action in the
report is assigned to exactly one of four mechanisms.

### 7.1 The four mechanisms

| # | Mechanism | Costs | Use when |
| --- | --- | --- | --- |
| 1 | **Focus area** — walk to it with the stick, press A | nothing | The thing is already a control laid out in the window. |
| 2 | **Visible strip bind** — A / X / Y / B, plus hold-X (QUATERNARY) | one of ~5 slots on 4 buttons | The action applies to *whatever is focused*, has at most two states, and is used more than once per fight reviewed. |
| 3 | **Ethereal cycle bind** — LB/RB, LT/RT, d-pad ↑↓ and ←→, LS/RS | nothing | A *global* ordered set stepped through often. No strip space, so no justification needed beyond "ordered and frequent". |
| 4 | **Menu dialog entry** (§5.1) | two extra presses | Everything else: more than two variants, unordered, or rare. |

Mechanism 1 is weaker than it looks on console. A focus area is only cheap to *reach* if it is near
where you already are, and in a 2×3 grid of panels holding 30–60 row lists it frequently is not
(§7.7). Where mechanism 1 and mechanism 3 both fit, prefer 3 — ethereal slots cost nothing, and
after the d-pad was found there are ten of them.

### 7.2 The test

Reach for a **visible bind** only when all three hold:

1. **Focused** — it acts on the currently focused row/button, not on global state.
2. **Binary** — at most two outcomes, so the strip label can state what pressing will do
   (`Add Favourite` ↔ `Remove Favourite`). This is the real value of a bind over a menu entry:
   it is self-documenting.
3. **Repeated** — used more than once per fight you look at.

Fail (1) but pass (2) and (3), and it is global state → **ethereal cycle** if the values are
ordered, else a menu entry. Fail (2) → **menu entry**, because a label cannot describe a
four-way choice. Fail (3) → **menu entry**, regardless of the rest.

Anything that is already a button in the window is mechanism 1 by default; a bind for it is a
*shortcut*, added only when the test says "repeated" and a free ethereal slot exists.

### 7.3 Where every action landed

#### Report-level

| Action | Mechanism | Reasoning |
| --- | --- | --- |
| Close report | 2 — B | Universal, and B already means "back". |
| **Leave the focused panel** | 3 — LB / RB | The highest-priority requirement of the whole scheme. Must not depend on scroll position; see §7.7. |
| Previous / next panel | 3 — LB / RB | Same bind. Shoulders are the pane-switching idiom, and they are rarer in stock code than R3, so repurposing them costs little. |
| Previous / next fight | 3 — LT / RT | Global, ordered, arbitrary length, very frequent. Matches `guildhistory` paging. |
| Previous / next view | 3 — d-pad ← → | Ordered and wanted quickly. Skips views with no panels, so `graph` and `fightList` stay out of the cycle until they exist. |
| Previous / next category (4) | 3 — d-pad ↑ ↓ | Global, ordered. Fails "binary" so not a visible bind; ordered so not a menu. |
| **Save fight** | 2 — hold X | Wanted visible and fast, and `QUATERNARY` *is* physically a hold, so "confirm intent" is the binding rather than a state machine. `MenuPanel:UpdateButtonStates()` already computes `enabled`. |
| Most recent fight, load, delete | 1 — menu bar | Buttons already exist; load is also the `fightList` view. |
| Jump to menu bar | 3 — RS click | Shortcut only. ← from the leftmost panel and the LB/RB ring both reach it. |
| Show IDs / overheal / pets | 4 — Y menu | Global, not focused → fails test 1. Rare → fails test 3. |
| Feedback / donate (6) | 4 — Y menu | Rare, and two nesting levels flatten into headed sections. |
| Move / resize window | 4 — Y menu | Dragging and the resize grip are mouse-only, so on console they simply do not exist. Phase 4. |
| Rename fight | 4 — Y menu, or PC-only | Needs `ZO_GamepadEditBox`. If that is not done, rename is explicitly a PC-only feature rather than a deferral — see phase 4. |

#### Scroll-list row-level (`units`, `abilities`, `buffs`)

| Action | Mechanism | Reasoning |
| --- | --- | --- |
| Select / deselect row | 2 — A | Focused, binary, constant. The core interaction. |
| Additive toggle (was ctrl+click) | 2 — A | Same bind: on a gamepad every A press is additive, since there is no modifier. Deselect-all stays on B. |
| Range select (was shift+click) | 2 — **hold A and move** | Paint-select, §7.5. Recovers range selection without a modifier and without a mode. |
| Clear selection (was middle-click) | 2 — B | Focused-ish, binary, frequent; B falls through to "close" when nothing is selected. |
| Sort by column | – — left stick ←→ inside the list | The list has no other use for its horizontal axis, and the header arrow already shows the active column. Costs no bind, no focus area and no highlight art. |
| Buff category Enemy / Group / Player | 4 — Y menu | Three variants → fails "binary". A focus area for it would be a third nested stop reachable only by scrolling a list to its top. |
| `buffs` expand / collapse details | 2 — X | Focused, binary, frequent while reading a buff list. |
| `buffs` favourite add / remove | 4 — Y menu | Displaced from hold-X by Save Fight. Rare enough to pass the test as a menu entry, though it loses the self-documenting label. |
| Post unit DPS / unit-name DPS / selection DPS / selection HPS | 4 — Y menu | Four variants, conditional on category and selection → fails "binary". |
| Post buff uptime / on bosses / on group | 4 — Y menu | Same; conditional on category and buff category. |

#### Panel-local

| Action | Mechanism | Reasoning |
| --- | --- | --- |
| `skills` page between bars | 1 — focus the existing `pageButton` | The button already exists and is already positioned. |
| `champion_points` scroll | – | Falls out of focus movement via `ZO_Scroll_ScrollControlIntoView`. |

### 7.4 Consequences to keep in mind

- **`X` is panel-defined; `QUATERNARY` is global.** `X`'s descriptor lives in each panel's focus
  area with `visible` a function of the focused row (`hasDetails` for expand); a panel that defines
  none simply shows fewer prompts. `QUATERNARY` is the opposite — Save Fight, on the navigator,
  identical everywhere. Do not centralise `X`, and do not let a panel claim `QUATERNARY`.
- **They are the same physical button, and this collision is accepted.** `QUATERNARY` is hold X
  (§0.2), so in `buffs` a tap expands a row and a hold saves the fight, with the tap resolving only
  on release. Both are labelled on the strip and the pairing exists in exactly one panel, which is
  why it was taken over the alternatives (moving expand to left-stick →/←, or putting Save on a
  visible R3 click and losing the hold-to-confirm). It remains the one place in the scheme where
  two unrelated actions share a button — worth re-checking on the ConsoleFlow pass.
- **One action loses fidelity on gamepad**: ctrl-click collapses into plain A, since there is no
  modifier — every A press is additive. Range-select survives as paint-select (§7.5). The
  keyboard path is unchanged; the phase 1 refactor extracts
  `SelectionHandler:Toggle` / `SetSelected` / `SelectRange` as primitives that **do not** call
  `fightReport:Update()`, leaving each caller to decide when to update.
- **`CMXint.BuffContextMenu` is currently dead code** (defined, never called). It is the v1
  behaviour awaiting re-wire, and it is the single place where the buffs split above has to be
  applied. Do not re-wire it as a context menu and convert it later — split it once, at re-wire
  time, into one bind (`X` collapse) plus three menu entries (favourite, two post-uptime).
- **The category and view cycles change global state while a list is focused**, so the focused row
  may vanish. `ZO_ScrollList`'s selection is data-based and survives a commit, but if the datum is
  gone the area must re-run `ZO_ScrollList_AutoSelectData` rather than leave a stale cursor. The
  view cycle goes further — it changes which panels exist, so it must `navigator:Rebuild(key)`.
- **Nothing nests.** Every focus area is a whole panel, so the LB/RB ring is 5–6 stops and there is
  no "which sub-area am I in" state. Keep it that way: the moment a panel wants a second area, the
  ring grows and the reason the shoulders work starts to erode.

### 7.5 Paint-select — hold A and sweep

Replaces shift+range-select, which has no gamepad equivalent. Hold A and move the stick: every
row the cursor passes takes the selection state that the *first* row took.

**Mode is decided by the initial press**, not by a separate toggle: if the row under the cursor
was unselected, the sweep selects; if it was selected, the sweep deselects. This is the
mouse-drag idiom from file managers and spreadsheets, so it needs no affordance and no explaining.
A plain tap is unchanged — it toggles exactly one row, so nothing is lost for users who never
discover the hold.

```lua
-- on the list focus area
paintMode = nil            -- nil = not painting, true = selecting, false = deselecting
```

- **A down** → `paintMode = not selections:IsSelected(id)`; apply it to the focused row.
- **focus moves** while `paintMode ~= nil` → apply `paintMode` to the newly focused row.
- **A up**, or area deactivated, or fight/category changed → `paintMode = nil`, then one
  `fightReport:Update()`.

Mechanics:

- `handlesKeyUp = true` on the A descriptor; the callback receives `up` as its only argument.
  Precedent: `ingame/champion/champion.lua:645` holds a trigger to add/remove champion points.
- **Do not rely on the key-up arriving.** The champion code captures its target into an
  independent variable precisely because the selection can change mid-hold, and it still depends
  on the up event — which never fires if the descriptor is removed while held (focus area
  switched, panel hidden, report closed). The navigator already runs every frame, so also clear
  `paintMode` there when the key is no longer down:

  ```lua
  local PREFER_GAMEPAD = true
  local key = GetHighestPriorityActionBindingInfoFromName("UI_SHORTCUT_PRIMARY", PREFER_GAMEPAD)
  if paintMode ~= nil and not IsKeyDown(key) then self:EndPaint() end
  ```

  The second argument is `preferGamepad`, not "use keyboard" — pass `true` or the call returns the
  *keyboard* binding and `IsKeyDown` polls the wrong key, silently disabling this guard. B3 shows
  what the wrong value looks like.

  This is the pattern `DirectionalInput:GetRightTriggerMagnitude` uses
  (`libraries/zo_directionalinput/zo_directionalinput.lua:332`). It makes a stuck paint state
  impossible regardless of how the hold ends.

  > **⚠ This guard cannot be written as shown.** `IsKeyDown` is a private function and throws
  > *"Attempt to access a private function from insecure code"* when an addon calls it — the same
  > wall the d-pad hits in §1 constraint 1, hit in game during phase 0. The stuck-state problem is
  > real and still needs solving, just not this way. Candidates, none verified: clear `paintMode`
  > from the focus area's `Deactivate`, the panel's `Release` and the navigator's `Deactivate`
  > (covers every removal path C2 identified, but not a physically stuck button); or drive the
  > sweep off `handlesKeyUp` alone and accept that a lost UP leaves one stale flag, cleared on the
  > next A press. Settle this before phase 1 implements paint-select.
- **Update cost is the real constraint.** `SelectionHandler:HandleClick` currently ends with
  `CMXint.fightReport:Update()`; at one row per frame a sweep would run a full report update per
  row — §5.2 item 4 made an order of magnitude worse. During a sweep, mutate `selectedItems`,
  call `dataList:RefreshVisible()` only, and defer the single `fightReport:Update()` to
  `EndPaint`. This is why the phase 1 refactor must produce primitives that do not update.
- Movement is unaffected by the held button: directional input and the keybind strip are
  independent systems, so hold-A-and-push-down just works.

**Verified by C2.** A tap and a ~2 s hold both deliver exactly one `DOWN` and one `UP`, so the
separate `KEY_GAMEPAD_BUTTON_*_HOLD` key codes do not swallow a plain `UI_SHORTCUT_PRIMARY`
binding. C2 also confirmed the failure mode this section guards against: removing the descriptor
mid-hold produces **no `UP` at all**. The per-frame `IsKeyDown` clear above is therefore load-
bearing, not defensive padding — without it, closing the report mid-sweep leaves `paintMode` set
and the next entry into a list starts already painting.

Rejected alternative: an explicit range mode (X sets an anchor, move, X completes). More
discoverable through strip labels, but it costs two extra presses and adds a mode the user can be
stuck in. Paint-select is modeless.

### 7.6 Conformance to vanilla gamepad conventions

Checked against the stock screens, so a player arriving from the vanilla UI meets no new idioms
except where noted.

| Concept | Vanilla precedent |
| --- | --- |
| Focus areas, ↑↓ within an area | `ZO_GamepadMultiFocusArea_Manager` drives exactly this — one horizontal and one vertical `ZO_MovementController`, each area handling its own interior (`zo_gamepadmultifocusareamanager.lua:132`, `:262`). |
| A = select / activate | Universal, 242 descriptors. |
| A toggles rows additively in a multi-select list | `universaldeconstructionpanel_gamepad.lua:362` — A adds the focused item if absent, removes it if present. The same model, including no modifier. |
| B = back / close | Universal, 81 descriptors. |
| B = "Clear Selections" while a selection exists | Real pattern: alchemy, enchanting and provisioner each bind `UI_SHORTCUT_NEGATIVE` to `ClearSelections` with `visible = HasSelections()` (`alchemy_keyboard.lua:168`). Note they express it as a *second descriptor gated on `visible`*, not one callback branching internally — §3.3 does the same so the strip label is honest about what B will do. |
| Y = open a list of further actions | The dominant use of `UI_SHORTCUT_TERTIARY`: crafting options, inventory action list, dyeing options, `SI_GAMEPAD_OPTIONS_MENU`, equipped-item more-actions. |
| X as a panel-defined row action | `universaldeconstructionpanel_gamepad.lua:382`/`:398`. |
| LB / RB cycling an ordered set, ethereal | `champion.lua:699` cycles constellations on the shoulders with `ethereal = true`. |
| LT / RT paging, ethereal | `guildhistory_gamepad.lua:58` pages the events list on the triggers. |
| d-pad as discrete UI navigation | `ZO_Gamepad_AddForwardNavigationKeybindDescriptors` pairs an ethereal `UI_SHORTCUT_INPUT_RIGHT` with `PRIMARY` for the same callback (`zo_gamepadutils.lua:99`, `:135`). |
| Ethereal binds drawing nothing on the strip | 126 uses across `ingame/` and `libraries/`. |
| `handlesKeyUp` hold binds | `champion.lua:648` holds a trigger to remove points, taking `up` in the callback. |

**Four deliberate divergences**, all worth keeping but worth knowing about:

1. **Buttons, not the stick, move between areas.** Vanilla moves between focus areas with the
   stick and reserves the shoulders for tabs. CMX inverts it because its panels are large scrolling
   lists rather than the short chains stock screens use — see §7.7. The stick still falls through
   *sideways*, so the vanilla motion half works; but ↑ at the first row and ↓ at the last do
   nothing, where vanilla would hop to the adjoining area. That is the visible cost of the
   inversion, and it is paid so that holding ↓ through a 60-row list cannot end somewhere else.
2. **`QUATERNARY` is global, not a row action.** Stock uses hold-X for a second action on the
   focused item; CMX spends it on Save Fight, because a hold is the natural shape for a
   confirm-intent action and there is no other visible slot left.
3. **Paint-select (§7.5) has no vanilla equivalent.** The closest thing is champion's hold-trigger,
   which repeats one action on *one* target; nothing in the stock UI holds a button and sweeps a
   selection across rows. The idiom is borrowed from desktop file managers instead. It is additive
   — a plain tap still toggles one row — so a player who never discovers it loses nothing, which is
   what makes the divergence acceptable.
4. **RS click = jump to the menu bar** is navigation, where vanilla stick clicks are *actions*
   (set waypoint, report guild, enter/exit preview). Keeping it is fine — it is ethereal, so it
   costs no strip space and cannot mislead — but it will not be guessed. Treat it as a power-user
   shortcut, never the only route to the menu bar; ← from the leftmost panel must always work.

### 7.7 Why the stick stopped moving between panels

The original scheme was pure vanilla: stick ↑↓ inside an area, falling through to the vertical
neighbour at the edge, stick ←→ between horizontal neighbours, shoulders cycling the category. It
survived until the layout was measured, and then it did not.

CMX is a 2×3 grid of panels inside one 1044×770 window, and three of the six are scroll lists
showing a fraction of their data:

| Panel | Rect (scale 1) | Visible rows | Typical rows |
| --- | --- | --- | --- |
| `buffs` | 672..1040 × 56..430 | 14 | longest dataset in the addon, and rows *expand* |
| `units` | 40..400 × 434..738 | 12 | single digits to ~30 |
| `abilities` | 404..1040 × 434..738 | 12 | 30–60 |

Fall-through means leaving a panel costs one stick push per row. On `abilities` that is 3–5 full
screens of held stick, ending in a deliberate release-and-repush at the edge latch — and
`abilities` has no down-neighbour at all, so its only exit is *upward* through the whole list.
Stock screens get away with fall-through because they show one list at a time in a short chain;
CMX does not have that shape.

So the shoulders took panel switching, which is what they mean in stock UI anyway, and the freed
pair went to the d-pad along with the view cycle — the d-pad having turned out to be reachable
after all (§0.2). Three things fell out of that, all simplifications:

- **The stick's horizontal axis became free inside a panel**, which is where sorting went. No
  header focus area, no `EnableHighlight`, no template.
- **Sub-areas stopped being necessary.** The buff filter chain existed so ↑ out of a list had
  somewhere to land; with the shoulders escaping in one press it is just a menu section.
- **Every area is now a whole panel**, so the ring is 5–6 stops with no nesting.

The general lesson, if a later panel tempts a return to fall-through: *mechanism 1 is only cheap
when the thing is close.* In a grid of long lists, "walk to it" is not a free operation, and the
test in §7.2 has to weigh reachability, not just frequency.
