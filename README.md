# Multiple Mark And Recall (with spells) for TES3MP

Edited version of the [https://github.com/hristoast/tes3mp-mmar](https://github.com/hristoast/tes3mp-mmar)

**[DataManager](https://github.com/tes3mp-scripts/DataManager) is optional**

This plugin replaces default mark and recall spells. Removes existing spells from the player on join and spellbook changes, adds custom spells to the player. Uses gui for interaction.

**If you used the original version, you can use the marks you saved**

## Installation

1. Place this repo into your `CoreScripts/scripts/custom/` directory.

1. Add the following to `CoreScripts/scripts/customScripts.lua` (If you are **not** using DataManager, do not add the first line):
```lua
DataManager = require("custom/DataManager/main")
require("custom/mmar")
```
Optionally configure MMAR by editing the `CoreScripts/data/custom/__config_MultipleMarkAndRecall.json` file (If you have DataManager, if you dont you can edit from lua file).
