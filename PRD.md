# Totemic AddOn PRD

## Overview
- **Goal:** Provide a fast, reliable way for Turtle WoW shamans to configure, save, and deploy totem sets without micromanaging macros.
- **Scope:** Lightweight Lua 5.0 (WoW 1.12) addon with UI, minimap access, slash commands, keybindings, set storage, and macro generation.
- **Non-Goals:** Localization, automation beyond hardware-triggered casts, post-1.12 APIs, advanced totem rank logic.

## Primary Capabilities
- Detect known totem spells (Earth/Fire/Water/Air) and allow one selection per element.
- Save/load/delete named sets per character and surface them in a quick-select panel.
- Cast the active set (up to four totems) and create/update a `/totemic cast <SetName>` macro.
- Present a clean, minimal UI (modal frame + quick panel) with opacity control.
- Provide minimap toggle button, slash commands (`/totemic`, `/totemic cast`, `/totemic resetpos`), and keybindings (toggle/cast).

## Recent Issues & Requirements
- **UI stability:** Previous XML layout produced broken visuals (overlapping dropdowns, blank textures). UI now built in Lua for precise control; maintain minimalist layout (consistent fonts, 1px-style borders, labeled controls).
- **Compatibility:** Turtle WoW uses Lua 5.0. Avoid `SetSize`, `string.match`, ipairs, `#` operator. Use `SetWidth/SetHeight`, `table.getn`, etc.
- **Minimap toggle:** Ensure drag vs click logic prevents accidental toggling failure; button must always open Totemic when left-clicked.
- **Initialization:** UI creation must happen before interactions (login, slash commands). Always call `Totemic_UI_Init` before showing.
- **Alpha slider:** Keep slider label updated and ensure default value loads from SavedVariables on login.

## Architecture Notes
- `Core.lua` handles spell scanning, SavedVariables (`TotemicDB`), set management, casting, slash commands, keybindings, and frame position persistence.
- `UI.lua` now constructs the frame programmatically (no `UI.xml`). Functions:
  - `Totemic_UI_Init` builds frames and registers handlers.
  - `Totemic_UI_BuildDropdowns`, `_UpdateSets`, `_UpdateQuickList`, `_SetActiveSet`, `_UpdateAlphaLabel` keep UI state consistent.
- `Minimap.lua` maintains a draggable minimap button with tooltip and click handler.
- `Bindings.xml` defines toggle/cast keybindings.
- `Totemic.toc` loads `Core.lua`, `UI.lua`, `Minimap.lua`, `Bindings.xml` in that order.

## UI Requirements
- Left column: labeled dropdowns (“Select Totem” default) for Earth/Fire/Water/Air, Active Set display, Save/Delete controls, Load dropdown and button.
- Right column: “Quick Select” panel with hint text, up to 8 set buttons (hide unused slots), placeholder text when empty.
- Bottom row: “Cast Totems”, “Create Macro”, “Reset Window”, opacity slider, opacity label.
- Frame must be movable, clamped to screen, opacity adjustable via slider or mouse wheel.
- Use consistent fonts (`GameFontHighlight*`, `GameFontNormal*`) and dialog-style backgrounds per Vanilla conventions.

## Pending Work / Next Steps
- Visual polish: consider adding element icons, color-coded accents, or compact mode (optional enhancement).
- Localization and non-English spell name mapping (future if needed).
- Additional validation (unit tests not feasible; rely on in-game QA).

## Testing Checklist
- `/reload` produces no errors.
- Minimap button hover shows tooltip; left-click toggles frame; dragging stores new angle.
- Dropdowns list available totems; selections persist between openings until changed.
- Saving/loading sets updates Active Set label, dropdown default, quick buttons, and macro creation.
- `/totemic cast <Set>` loads and casts target set; `/totemic resetpos` recenters frame.
- Alpha slider and mouse wheel adjust opacity and update label.
