E2Helper.Descriptions["entFire"]
    = "Fires an entity's input.\n\n"..
    "<input> = The name of the input to fire.\n"..
    "<param> = The value to give to the input (optional)."


E2Helper.Descriptions["entKVSet"] =
    "Sets keyvalues value for the entity.\n\n"..
    "<key> = The key to change.\n"..
    "<value> = The new value to write."
E2Helper.Descriptions["entKVsGet"] =
    "Returns table of entity's keyvalues"


E2Helper.Descriptions["entDatadescGetTable"] =
    "Return entity's datadesc table"
E2Helper.Descriptions["entDatadescSet"] =
    "Sets datadesc value for the entity.\n\n"..
    "<key> = The key to change.\n"..
    "<value> = The new value to write."
E2Helper.Descriptions["entDatadescSetBoolean"] =
    "Sets datadesc value of boolean type (true/false) for the entity.\n\n"..
    "<key> = The key to change.\n"..
    "<value> = The new value to write."

E2Helper.Descriptions["entGetName"] =
    "Returns the mapping name of this entity (empty string if none)."
E2Helper.Descriptions["entGetNameOrAssignRandom"] =
    "Returns the mapping name of this entity or generates and set one if not exists."

E2Helper.Descriptions["entGetMapID"] =
    "Returns entity's map creation ID. Unlike entity(), it will always be the same on same map, no matter how much you clean up or restart it."
E2Helper.Descriptions["entityMapID"] =
    "Returns entity that has given MapCreationID. Unlike entity(), it will always be the same on same map, no matter how much you clean up or restart it."

E2Helper.Descriptions["entSpawnEx"] =
    "Spawns entity of given class at given position (default - E2 position) and with given angles (default - 0,0,0)"
E2Helper.Descriptions["entSpawnExKVs"] =
    "Spawns entity of given class at given position with given angles and with given keyvalues"

E2Helper.Descriptions["runOnEntityOutput"] =
    "Causes E2 to run when <output> of given <ent> is fired"

E2Helper.Descriptions["entityOutputClk"] =
    "Returns 1 if E2 was triggered due to some entity's output fire"
E2Helper.Descriptions["entityOutputClkActivator"] =
    "Returns entity that caused chain of output activations that triggered this E2"
E2Helper.Descriptions["entityOutputClkEntity"] =
    "Returns entity, output of which triggered this E2"
E2Helper.Descriptions["entityOutputClkOutput"] =
    "Returns name of output that triggered this E2"
E2Helper.Descriptions["entityOutputClkParam"] =
    "Returns parameter of output that triggered this E2" 
