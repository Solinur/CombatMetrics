# Gamepad / Console Navigation — Design & Implementation Plan

Branch: `dk_addConsoleNavigation`

Goal: make the fight report fully operable with a gamepad in ESO's gamepad-preferred mode —
move a focus between panels, scroll and select inside lists, read tooltips, and reach the
menu-bar actions through the keybind strip.

This document is the research result and the staged plan. It is written so panels can be
converted one at a time; each phase leaves the addon in a working state.

The plan started from assumptions read out of the ESO UI source rather than a running client.
**§0 records what checking them in game returned** — several answers changed the design rather
than confirming it, and the sections that follow are written against those answers.

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
| A2 | Mouse still usable there? | Yes (but it won't be on console!) |
| A3 | Mode switch while open — what happens? | Report closes |
| A4 | Tooltips appear without mouse movement? | Yes |
| B1 | All required `ZO_*` functions exist? | Yes |
| B2 | `FRAGMENT_GROUP.GAMEPAD_DRIVEN_UI_WINDOW` exists? | Yes |
| B3 | QUATERNARY / QUINARY bound on gamepad? | QUATERNARY = hold X (172). QUINARY = 0, unbound — assumed bound anyway |
| C1 | Keybind strip shows on the CMX scene? | Yes. But keyboard mode also gains `Menu: Exit`, and the group is not re-evaluated on reopen → gate on gamepad mode, swap on the mode event |
| C2 | Hold-A delivers a clean down/up pair? | Yes — one DOWN, one UP, tap and hold alike. Removing the group mid-hold fires no UP, so §7.5's `IsKeyDown` clear is required |
| C3 | Who else consumes directional input? | HUD 1, report 2, dialog-over-report 4 — they stack, so §5.1 navigator deactivation is mandatory |
| C4 | Sort header focus invisible without a template? | Yes. `ZO_ThinListHighlight` is good enough to ship |
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

Gamepad codes start at 133 (`KEY_GAMEPAD_BUTTON_1`); anything lower is a keyboard key and means the
query was made with `preferGamepad = false`. Two consequences run through the rest of the plan:

- **`QUATERNARY` is not a fifth button.** It is *hold X* — the same physical button as `SECONDARY`
  (tap X). A panel defining both puts them on one button, and the tap only resolves on release, so
  frequency decides which gets the tap (§3.3, §7.4).
- **`QUINARY` is unbound.** The plan proceeds as if it is bound: it is a slot the player can
  assign, and nothing in phases 1–3 depends on it. Anything placed there must degrade to
  unreachable-but-harmless, never to a broken panel.

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
  distinct marks: the selection fill and the gold outline.

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

### Two hard constraints found in the source

1. **Only one object may consume directional input.**
   `DIRECTIONAL_INPUT:GetX/GetY` *consume* the device once a non-zero value is read
   (`zo_directionalinput.lua:183-234`). If both the multi-focus manager and, say,
   `ZO_SortFilterList_Gamepad`'s own controller are activated, one of them silently eats the
   input. ESO's own code avoids this: `GamepadInteractiveSortFilterFocus_Panel:HandleMovement`
   calls `self.manager:MoveNext()` instead of activating the list's controller.
   → **CMX will register exactly one `UpdateDirectionalInput` consumer** (the navigator), and
   focus areas translate its results into panel actions. Never call
   `SetDirectionalInputEnabled(true)` on a list or a header group.

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

### What we do *not* have to solve

Addons only run on PC, so "console mode" here means **gamepad-preferred mode on PC**, where the
mouse is still physically present. `HIDE_MOUSE_FRAGMENT` only calls
`HideMouse(ONLY_CONSIDER_MOUSE_VISIBILITY_WHILE_MOVING)`, so the cursor reappears as soon as the
mouse moves. Gamepad navigation is therefore **additive** — the existing mouse paths stay, and a
panel that has not been converted yet is still usable with the mouse. This is what makes a
panel-by-panel rollout safe.

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
- Sort headers are created via `ZO_SortHeader_Initialize` **without a highlight template**
  ([ui/panels/units.xml](../CombatMetrics/ui/panels/units.xml) and friends), so
  `ZO_SortHeaderGroup:SetSelectedIndex` would move an invisible focus.
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
  `Deactivate(self)`; called from the view-scene `StateChange` callback in `scenes.lua`.
- `Rebuild(sceneKey)`: clears the area list and re-adds the focus area of every panel that is
  visible in the current view scene, in a fixed order, then applies that scene's neighbour map.
  Called after `applyLayout(key)` in `scenes.lua`, i.e. once per view switch, and again after a
  fight change if a panel became empty.
- `UpdateDirectionalInput()` (inherited) → `HandleMoveCurrentFocus(horizontal, vertical)`.
- Only runs when `IsInGamepadPreferredMode()` is true (checked once at `Activate`).

**`ui.FocusArea`** — extends the ESO base with a 2D neighbour map, because CMX's layout is a
grid, not a chain. The ESO base only knows `previousFocus` / `nextFocus`.

```lua
---@class CMXFocusArea : ZO_GamepadMultiFocusArea_Base
---@field panel Panel
---@field neighbours table<integer, CMXFocusArea>   -- keyed by ZO_DIRECTION_*
```

- `SetNeighbours{ up=, down=, left=, right= }`.
- Override `HandleMovementInternal(horizontal, vertical)`:
  1. give the panel a chance to consume it (`self:HandleMovement(...)` — list scroll, row step),
  2. otherwise walk `neighbours` in that direction, skipping areas whose `CanBeSelected()` is
     false, and `manager:SelectFocusArea(next)`.
- `CanBeSelected()` defaults to "panel control is not hidden **and** the panel has content".
- `Activate` / `Deactivate` show/hide the panel's focus highlight and add/remove the panel's
  keybind descriptor (already handled by the ESO base via `SetKeybindDescriptor`).

**Panel hook.** `PanelObject:GetFocusArea()` returns `self.focusArea`, created lazily.
`PanelObject:CreateFocusArea()` is the per-panel override point; the default returns `nil`,
meaning "this panel is not reachable by the gamepad yet". That is what makes the rollout
incremental — an unconverted panel is simply skipped when the navigator rebuilds.

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

Directional input moves the focus; nothing else does. See §7 for how every action in the addon
was assigned to one of these rows and why.

| Input | Strip | Scope | Action |
| --- | --- | --- | --- |
| Left stick / d-pad ↑↓ | – | global | Move inside the focused area. At the top/bottom edge, fall through to the vertical neighbour. |
| Left stick / d-pad ←→ | – | global | Move to the horizontal neighbour area. Inside a sort-header focus, move between columns. |
| `UI_SHORTCUT_PRIMARY` (A) | visible | focused entry | Select / Deselect a list row; press a menu-bar button; sort by a column header. Label is dynamic. |
| `UI_SHORTCUT_SECONDARY` (X) | visible | focused row | Panel-defined. `buffs`: Expand / Collapse, visible only when the row `hasDetails`. Absent on `units` and `abilities`. |
| `UI_SHORTCUT_TERTIARY` (Y) | visible | focused row | **More…** — opens the row's menu dialog (§5.1). Hidden when the row has no extra actions. |
| `UI_SHORTCUT_QUATERNARY` (hold X) | visible | focused row | Panel-defined. `buffs`: Add / Remove Favourite. Shares a button with SECONDARY — see §0.2 B3. |
| `UI_SHORTCUT_NEGATIVE` (B) | visible | global | Clear selections if any (`CMXint.ClearSelections`), otherwise close the report. |
| `LEFT_SHOULDER` / `RIGHT_SHOULDER` | ethereal | global | Previous / next **category** (damage done → healing done → damage received → healing received). |
| `LEFT_TRIGGER` / `RIGHT_TRIGGER` | ethereal | global | Previous / next **fight** (`SelectPreviousFight` / `SelectNextFight`). |
| `RIGHT_STICK` (click) | ethereal | global | Jump straight to the menu-bar focus area from anywhere. |
| `LEFT_STICK` (click) | ethereal | — | Reserved. First claim: previous / next **view** if reaching it through the menu bar proves slow. |

**Two budgets, not one.** Stock gamepad screens mark shoulders, triggers and stick clicks
`ethereal = true` — the bind fires but draws nothing on the strip
(`ingame/armory/gamepad/armorybuildskills_gamepad.lua:80`,
`ingame/guildhistory/gamepad/guildhistory_gamepad.lua:58`). So there are 4 *visible* buttons
(A / X / Y / B) carrying 5 slots — QUATERNARY is hold X, not a button of its own — plus 6 *free*
ones, and QUINARY once the player binds it. Cycling actions belong in the free tier — which is
also what ESO does with them (`ingame/champion/champion.lua:701` cycles constellations on the
shoulders, `guildhistory` pages on the triggers).

Resulting strip density: `units` and `abilities` show 3 binds, `buffs` shows 5, the menu bar
shows 2.

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
- Add `settings.fightReport.gamepadNavigation` (default: follow `IsInGamepadPreferredMode()`).
- Navigator activate/deactivate from the view-scene `StateChange` callback.

**Done when:** in gamepad mode the report opens, the strip shows `B — Close`, and B closes it.

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
  - `HandleMovement`: vertical → `MoveNext` / `MovePrevious`.
  - `HandleMovePrevious`: only escape to the neighbour when `ZO_ScrollList_AtTopOfList`.
  - `HandleMoveNext`: only escape when `ZO_ScrollList_AtBottomOfList`.
  - `CanBeSelected`: `self.panel.dataList:HasEntries()`.
  - `Activate`: `ZO_ScrollList_AutoSelectData(list, ANIMATE_INSTANTLY)`; `Deactivate`:
    `ZO_ScrollList_SelectData(list, nil)`.
  - Keybinds: A toggles the focused row, and **holding A while moving paints a range** — see
    §7.5 for the state machine, the stuck-state guard and the update-cost constraint.
    Refactor `SelectionHandler:HandleClick` first so the gamepad path does not have to fake a
    mouse button: extract `Toggle(id)` / `SetSelected(id, state)` / `SelectRange(id)` as
    primitives that do **not** call `fightReport:Update()`, and let each caller decide when to
    update. `HandleClick` keeps the mouse-button/modifier decoding and calls them.
- Column headers: a second focus area per list panel wrapping `sortHeaderGroup`.
  - Requires a highlight — pass a template as the 7th argument of `ZO_SortHeader_Initialize` in
    `units.xml`, `abilities.xml`, `buffs.xml`, or call `sortHeaderGroup:EnableHighlight(...)`
    once in `SortFilterList:Initialize`.
  - Drive it with `sortHeaderGroup:EnableSelection(true)` + `SetSelectedIndex(i)` from our
    navigator; **do not** call `sortHeaderGroup:SetDirectionalInputEnabled(true)`.
  - A on a header → `sortHeaderGroup:OnHeaderClicked(header)`.
- `buffs` only, two extras:
  - Its `SearchBar` is a `ZO_RadioButtonGroup` of three buttons (Enemy / Group / Player). That is
    a third focus area stacked above the headers, giving the panel the same
    filters → headers → list chain as `ZO_GamepadInteractiveSortFilterList`. ↑ from the top of
    the list reaches the headers, ↑ again the filters. No keybind needed.
  - A stays "select"; expand/collapse moves to `X` and favourite to `QUATERNARY` (hold X) — the
    more frequent action gets the tap, see §0.2 B3 — both with
    dynamic labels (§3.3). `CMXint.BuffContextMenu` ([buffs.lua:106](../CombatMetrics/ui/panels/buffs.lua))
    already contains all four actions but currently has **no caller** — it is pending re-wire
    from the v1 code. Split it when re-wiring: favourite and collapse become the two binds, the
    two "post uptime" entries become the `Y` menu (§5.1).
- Tooltips: on focus change call the existing handler with the focused row control.

**Done when:** the three list panels can be entered, scrolled, sorted and (multi-)selected with
a gamepad, and the numbers in the other panels react to the selection as they do with a mouse.

### Phase 2 — menu bar as a focus area, plus the gamepad options dialog

The menu bar is a vertical column of 14 buttons (4 category, 4 view, settings, feedback,
6 fight-nav) — a textbook `ZO_GamepadFocus`. Making it a focus area covers all of them with no
new keybinds and no new UI, because every button already has a callback and a tooltip.

- `ui.ButtonFocusArea` (a thin `ui.RowFocusArea`, see phase 3) over
  `MenuPanel.categoryButtons`, `.sceneButtons`, `.settingsButton`, `.feedbackButton`,
  `.navButtons`, in visual order. It is the leftmost area, so ← from the leftmost panel lands
  on it and ↑↓ walk the buttons.
- Entry `activate` → `CMXint.OnMouseEnter(button)` (they all carry `button.tooltip` already).
- A → the button's existing handler. Note the handlers are written as `OnMouseUp(button, ...)`
  and some read the `shift` argument (`SaveFight`); extract the body into a plain function so
  both callers can use it rather than faking mouse arguments.
- `canFocus` per entry ← `MenuPanel:UpdateButtonStates()`, which already computes exactly this;
  a `BSTATE_DISABLED` button must not be focusable.
- **Shortcuts for the frequent actions only:** `LEFT_TRIGGER` / `RIGHT_TRIGGER` = previous /
  next fight, `QUATERNARY` (hold X) = most recent fight. Everything else stays in the focus area.
  No conflict with `SECONDARY` here — the menu bar defines no tap-X.

The **settings and feedback buttons open context menus**, which is the only part that cannot be
reused — see §5.1. Their A press calls `CMXint.ShowGamepadMenu(...)` instead of
`ClearMenu`/`ShowMenu` when `IsInGamepadPreferredMode()`.

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

- `combat_stats`, `player_stats`, `info_row`, `title_bar`: no per-row targets. Either skip them
  entirely (their `CreateFocusArea` stays `nil`) or make them a single focus stop that shows the
  panel tooltip. Skipping is the recommended default.
- Window position/size: dragging is unavailable. Add entries to the gear menu (§5.1) to nudge
  position and change scale (`FightReport:Resize`), or accept centred+fixed in gamepad mode.
- Title rename (`OnMouseDoubleClick` → edit box): gamepad text entry needs
  `ZO_GamepadEditBox` handling; defer, or expose rename only in keyboard mode.
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
So the two menus behind the gear and feedback buttons need a replacement. Everything *else* that
looks menu-like in CMX is a plain button and is handled by the phase 2 focus area.

What is actually in them:

| Menu | Entries | Nature |
| --- | --- | --- |
| Gear | show/hide IDs, overheal, pets | 3 booleans, label flips with state |
| Feedback | submenu *Feedback*: mail (EU only), ESOUI, GitHub, Discord — submenu *Donate*: gold (EU only), ESOUI | 6 one-shot actions, one nesting level, 2 conditionally disabled |
| (commented out) unit row, post-DPS | ~7 chat-post variants | one-shot, context-dependent |

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

1. **Sort headers have no highlight template.** Must be supplied or the header focus is
   invisible (§3, phase 1).

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
- Per-phase checklist: open in gamepad mode → strip shows → every visible panel reachable →
  every panel's content reachable → B closes → reopen restores the previous focus → switch to
  keyboard mode and confirm mouse behaviour is unchanged.

---

## 7. Decision overview

Settled before implementation so no phase has to re-litigate it. Every user-facing action in the
report is assigned to exactly one of four mechanisms.

### 7.1 The four mechanisms

| # | Mechanism | Costs | Use when |
| --- | --- | --- | --- |
| 1 | **Focus area** — walk to it with the stick, press A | nothing | The thing is already a control laid out in the window. |
| 2 | **Visible strip bind** — A / X / Y / B, plus hold-X (QUATERNARY) | one of ~5 slots on 4 buttons | The action applies to *whatever is focused*, has at most two states, and is used more than once per fight reviewed. |
| 3 | **Ethereal cycle bind** — LB/RB, LT/RT, LS/RS | nothing | A *global* ordered set stepped through often. No strip space, so no justification needed beyond "ordered and frequent". |
| 4 | **Menu dialog entry** (§5.1) | two extra presses | Everything else: more than two variants, unordered, or rare. |

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
| Previous / next fight | 3 — LT / RT | Global, ordered, arbitrary length, very frequent. Matches `guildhistory` paging. |
| Previous / next category (4) | 3 — LB / RB | Global, ordered, frequent. Fails "binary" so not a visible bind; ordered so not a menu. Matches `champion.lua` constellation cycling. |
| Switch view (fightStats / info / …) | 1 — menu bar | Ordered, but rare — `info` is a build page you open once. LS/RS held in reserve if that proves wrong. |
| Most recent fight, load, save, delete | 1 — menu bar | Buttons already exist; `MenuPanel:UpdateButtonStates()` already computes their enabled state. |
| Jump to menu bar | 3 — RS click | Pure shortcut for a long ← walk from the right-hand panels. |
| Show IDs / overheal / pets | 4 — gear menu | Global, not focused → fails test 1. Rare → fails test 3. |
| Feedback / donate (6) | 4 — feedback menu | Rare, and two nesting levels flatten into headed sections. |
| Rename fight, move / resize window | deferred | Needs gamepad text entry; see phase 4. |

#### Scroll-list row-level (`units`, `abilities`, `buffs`)

| Action | Mechanism | Reasoning |
| --- | --- | --- |
| Select / deselect row | 2 — A | Focused, binary, constant. The core interaction. |
| Additive toggle (was ctrl+click) | 2 — A | Same bind: on a gamepad every A press is additive, since there is no modifier. Deselect-all stays on B. |
| Range select (was shift+click) | 2 — **hold A and move** | Paint-select, §7.5. Recovers range selection without a modifier and without a mode. |
| Clear selection (was middle-click) | 2 — B | Focused-ish, binary, frequent; B falls through to "close" when nothing is selected. |
| Sort by column | 1 — header focus area | Already controls laid out above the list; ↑ from the top row reaches them. |
| Buff category Enemy / Group / Player | 1 — filter focus area | Already a `ZO_RadioButtonGroup` in the panel. Gives buffs the same filters → headers → list chain as `ZO_GamepadInteractiveSortFilterList`. |
| `buffs` expand / collapse details | 2 — X | Focused, binary, frequent while reading a buff list. Takes the tap because it out-frequents favourite. |
| `buffs` favourite add / remove | 2 — QUATERNARY (hold X) | Focused, binary, and the dynamic label is how the feature becomes discoverable at all. Rarer, so it takes the hold. |
| Post unit DPS / unit-name DPS / selection DPS / selection HPS | 4 — Y menu | Four variants, conditional on category and selection → fails "binary". |
| Post buff uptime / on bosses / on group | 4 — Y menu | Same; conditional on category and buff category. |

#### Panel-local

| Action | Mechanism | Reasoning |
| --- | --- | --- |
| `skills` page between bars | 1 — focus the existing `pageButton` | The button already exists and is already positioned. |
| `champion_points` scroll | – | Falls out of focus movement via `ZO_Scroll_ScrollControlIntoView`. |

### 7.4 Consequences to keep in mind

- **`X` and `QUATERNARY` are panel-defined, not global.** Their descriptors live in each panel's
  focus area, and `visible` is a function of the focused row (`hasDetails` for expand). A panel
  that defines neither simply shows fewer prompts. Do not centralise them.
- **They are also the same physical button.** `QUATERNARY` is hold X (§0.2 B3), so a panel
  defining both makes the tap resolve only on release. Give the tap to the more frequent action
  and keep the pair on one row's worth of state — never bind X and hold X to actions that read
  as unrelated.
- **One action loses fidelity on gamepad**: ctrl-click collapses into plain A, since there is no
  modifier — every A press is additive. Range-select survives as paint-select (§7.5). The
  keyboard path is unchanged; the phase 1 refactor extracts
  `SelectionHandler:Toggle` / `SetSelected` / `SelectRange` as primitives that **do not** call
  `fightReport:Update()`, leaving each caller to decide when to update.
- **`CMXint.BuffContextMenu` is currently dead code** (defined, never called). It is the v1
  behaviour awaiting re-wire, and it is the single place where the buffs split above has to be
  applied. Do not re-wire it as a context menu and convert it later — split it once, at re-wire
  time, into two binds plus two menu entries.
- **The category cycle changes global state while a list is focused**, so the focused row may
  vanish. `ZO_ScrollList`'s selection is data-based and survives a commit, but if the datum is
  gone the area must re-run `ZO_ScrollList_AutoSelectData` rather than leave a stale cursor.

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
| Focus areas, ↑↓ within / ←→ between | `ZO_GamepadMultiFocusArea_Manager` drives exactly this — one horizontal and one vertical `ZO_MovementController` move between areas, each area handling its own interior (`zo_gamepadmultifocusareamanager.lua:132`, `:262`). |
| A = select / activate | Universal. |
| A toggles rows additively in a multi-select list | `universaldeconstructionpanel_gamepad.lua:362` — A adds the focused item if absent, removes it if present. The same model, including no modifier. |
| B = back / close | Universal. |
| B = "Clear Selections" while a selection exists | Real pattern: alchemy, enchanting and provisioner each bind `UI_SHORTCUT_NEGATIVE` to `ClearSelections` with `visible = HasSelections()` (`alchemy_keyboard.lua:168`). Note they express it as a *second descriptor gated on `visible`*, not one callback branching internally — §3.3 should do the same so the strip label is honest about what B will do. |
| Y = open a list of further actions | The dominant use of `UI_SHORTCUT_TERTIARY`: crafting options, inventory action list, dyeing options, `SI_GAMEPAD_OPTIONS_MENU`, equipped-item more-actions. |
| X and QUATERNARY as panel-defined row actions | `universaldeconstructionpanel_gamepad.lua:382`/`:398` uses both for exactly this. |
| LB / RB cycling an ordered set, ethereal | `champion.lua:699` cycles constellations on the shoulders with `ethereal = true`. |
| LT / RT paging, ethereal | `guildhistory_gamepad.lua:58` pages the events list on the triggers. |
| Ethereal binds drawing nothing on the strip | 126 uses across `ingame/` and `libraries/`. |
| `handlesKeyUp` hold binds | `champion.lua:648` holds a trigger to remove points, taking `up` in the callback. |

**Two deliberate divergences**, both worth keeping but worth knowing about:

1. **Paint-select (§7.5) has no vanilla equivalent.** The closest thing is champion's hold-trigger,
   which repeats one action on *one* target; nothing in the stock UI holds a button and sweeps a
   selection across rows. The idiom is borrowed from desktop file managers instead. It is additive
   — a plain tap still toggles one row — so a player who never discovers it loses nothing, which is
   what makes the divergence acceptable.
2. **RS click = jump to the menu bar** is navigation, where vanilla stick clicks are *actions*
   (set waypoint, report guild, enter/exit preview). Keeping it is fine — it is ethereal, so it
   costs no strip space and cannot mislead — but it will not be guessed. Treat it as a power-user
   shortcut, never the only route to the menu bar; ← from the leftmost panel must always work.
