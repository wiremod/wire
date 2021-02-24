# Wire-FPGA

Adds a field programmable gate array for use with Wiremod (https://github.com/wiremod/wire)

Workshop: https://steamcommunity.com/sharedfiles/filedetails/?id=2384925255

Comes with a visual node editor, and offers a nice step between pure wire gates and E2,
but also makes stuff like custom CPUs and other complicated gate devices possible, since the performance hit is several times lower than 
multiple gates being used to make the same device.


## Source code modifications
Part of this mod (namely the editor-frame) is based on the Expression 2 / ZCPU editor (lua\wire\client\text_editor\wire_expression2_editor.lua) that comes with Wiremod. This part has been changed to fit the usage seen here, but the base of the code remains the same as the versions shipped with Wiremod (as of 2021-01-08).

The frame (the part outside the text editor, ie. the file selector, the tabs, the menus) has been changed to make it compatible with saving and loading node based files, and offer more relevant settings that the node editor would use. This involved changing the helper functions that get the "name" of the program from the editor, getting the data (text) from the editor, loading data into the editor, loading the editor itself (node editor).
Various other changes have been made, to remove ZCPU and E2 specific functionality which was no longer needed.

The gate selector from the Wire Gate tool has been put to use in the node editor, and the searching function has modified to fit the expanded gate library that Wire FPGA brings.

The vector/angle validation function from the Wire Value tool has been used in the node edit menu, when changing vector/angle constant values.
