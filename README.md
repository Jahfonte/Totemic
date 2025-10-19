# Totemic - Shaman Totem Set Manager for Turtle WoW

A lightweight, reliable addon for managing and deploying shaman totem sets in Turtle WoW (WoW 1.12.1).

## Features

- **Totem Detection**: Automatically scans and detects all known totem spells
- **Set Management**: Save, load, and delete named totem sets per character
- **Quick Select Panel**: Fast access to your 8 most recent sets
- **One-Click Casting**: Deploy all totems in a set with a single click
- **Macro Generation**: Automatically creates `/totemic cast <SetName>` macros
- **Minimap Button**: Draggable minimap button for quick access
- **Keybindings**: Customizable hotkeys for toggle and cast
- **Import/Export**: Share totem sets between characters

## Installation

1. Extract the Totemic folder to Interface\AddOns\
2. Restart WoW or type /reload
3. Look for the Totemic minimap button

## Usage

### Opening the UI

- Click the minimap button
- Type `/totemic`
- Use your keybinding (set in ESC > Key Bindings > Totemic)

### Creating a Totem Set

1. Select totems from each element dropdown (Earth/Fire/Water/Air)
2. Type a name in the "Set Name" field (e.g., "totem1", "pvp", "raid")
3. Click "Save Set"
4. Addon automatically creates a macro with the same name
5. The set appears in the saved sets list below

### Using Your Totem Sets

**The addon creates macros you bind to keys:**
1. Save a set named "totem1"
2. Addon creates a macro named "totem1" containing:
   ```
   /cast Strength of Earth Totem
   /cast Searing Totem
   /cast Mana Spring Totem
   /cast Windfury Totem
   ```
3. Open WoW Keybindings (ESC > Key Bindings)
4. Find "totem1" in General Macros
5. Bind it to a key
6. Press that key to cast all 4 totems

**When you change totems:**
1. Open Totemic window
2. Load "totem1" from the list
3. Change totems in the dropdowns
4. Click "Save Set" again
5. Macro updates automatically
6. Your keybind still works - no need to rebind

### Managing Sets

- **Load**: Click "Load" button next to a saved set in the list
- **Delete**: Click "Delete" button next to a saved set (also deletes the macro)
- **Export**: `/totemic export <SetName>` - Outputs serialized data to chat
- **Import**: `/totemic import <NewName> <data>` - Import from string

## Slash Commands

```
/totemic              Toggle UI
/totemic show         Show UI
/totemic hide         Hide UI
/totemic cast [name]  Cast totem set (loads if name provided)
/totemic reset        Reset window position to center
/totemic debug        Toggle debug mode
/totemic reload       Invalidate spell cache
/totemic list         List all saved sets
/totemic export [name] Export set as string
/totemic import <name> <data> Import set
/totemic test         Run self-tests
/totemic help         Show command help
```

## Keybindings

Configure in ESC > Key Bindings > Totemic:
- **Toggle Totemic Window** - Show/hide the main UI
- **Cast Current Totem Set** - Cast the active totem selection

## Supported Totems

### Earth (5)
- Strength of Earth Totem
- Stoneskin Totem
- Tremor Totem
- Earthbind Totem
- Stoneclaw Totem

### Fire (5)
- Searing Totem
- Magma Totem
- Fire Nova Totem
- Flametongue Totem
- Frost Resistance Totem

### Water (5)
- Healing Stream Totem
- Mana Spring Totem
- Poison Cleansing Totem
- Disease Cleansing Totem
- Fire Resistance Totem

### Air (7)
- Windfury Totem
- Grace of Air Totem
- Tranquil Air Totem
- Grounding Totem
- Windwall Totem
- Nature Resistance Totem
- Sentry Totem

## UI Controls

**Totem Selection:**
- 4 labeled dropdowns (Earth/Fire/Water/Air) to select totems
- Dropdowns populate with your learned totem spells

**Set Management:**
- Set Name field - enter name for your totem set
- Save Set button - saves configuration and creates/updates macro
- Saved Sets list - shows all your saved sets (scrollable)
- Load button - loads a set into the dropdowns
- Delete button - removes set and its macro

**Bottom Controls:**
- Opacity slider (20-100%) - adjust window transparency
- Help text explaining macro generation

**Window:**
- Resizable - drag bottom-right corner to resize
- Movable - drag title bar to move
- Position and size saved per character
- Min 400x400, Max 800x600, Default 500x450

## Technical Details

**Lua 5.0 Compatible:**
- Built for WoW 1.12.1 API
- No modern Lua features used
- Defensive error handling throughout

**Performance:**
- Spell scanning cached (30s TTL)
- UI updates throttled (100ms)
- Minimal memory footprint

**Data Storage:**
- SavedVariables: `TotemicDB`
- Per-character set storage
- Frame position persistence
- Window visibility state saved

## Troubleshooting

**Totems not appearing in dropdowns:**
- Type `/totemic reload` to refresh spell cache
- Verify totems are learned in your spellbook

**UI not showing:**
- Type `/totemic reset` to reset window position
- Type `/totemic show` to force display

**Errors after update:**
- Type `/reload` to reinitialize addon
- Type `/totemic test` to run diagnostics

**Debug mode:**
- Type `/totemic debug on` for verbose logging
- Check for error messages in chat
- Type `/totemic debug off` to disable

## Version

**v0.1.0** - Initial release for Turtle WoW

## Credits

Built with pure Lua for maximum compatibility with WoW 1.12.1 and Turtle WoW.
