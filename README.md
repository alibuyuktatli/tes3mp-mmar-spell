# Multiple Mark And Recall (with spells) for TES3MP
Edited version of the [https://github.com/hristoast/tes3mp-mmar](https://github.com/hristoast/tes3mp-mmar)

**DataManager is not required**

This plugin replaces default mark and recall spells and enchantments. Uses gui for interaction.
**If you used the original version, you can use the marks you saved**

Thanks [Rickoff](https://github.com/rickoff) for item and custom item enchantment support.

## Installation

1. Place mmar.lua into your `CoreScripts/scripts/custom/` directory.

1. Add the following to `CoreScripts/scripts/customScripts.lua`:
```lua
require("custom/mmar")
```

recallForbiddenCells and markForbiddenCells settings checks for player's current cell.


*Tested on tes3mp 0.8.1*