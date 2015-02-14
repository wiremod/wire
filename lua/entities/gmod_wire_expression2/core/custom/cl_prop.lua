language.Add("Undone_e2_spawned_prop", "Undone E2 Spawned Prop")
language.Add("Undone_e2_spawned_seat", "Undone E2 Spawned Seat")
E2Helper.Descriptions["propManipulate"] = "Allows to do any single prop core function in one term.\n(position, rotation, freeze, gravity, notsolid)"
E2Helper.Descriptions["propSpawn"] = "Use the model string or a template entity to spawn a prop.\nYou can set the position and/or the rotation as well.\nThe last number indicates frozen/unfrozen."
E2Helper.Descriptions["seatSpawn"] = "Spawn a remodeled prop_vehicle_prisoner_pod"
E2Helper.Descriptions["propSpawnEffect(n)"] = "Set to 1 to enable prop spawn effect, 0 to disable."
E2Helper.Descriptions["propDelete"] = "Removes the given entity(s). Returns how may are deleted."
E2Helper.Descriptions["propFreeze"] = "Passing 0 unfreezes the entity, everything else freezes it."
E2Helper.Descriptions["propNotSolid"] = "Passing 0 makes the entity solid, everything else makes it non-solid."
E2Helper.Descriptions["propGravity"] = "Passing 0 makes the entity weightless, everything else makes it weighty."
E2Helper.Descriptions["setPos"] = "Sets the position of an entity."
E2Helper.Descriptions["reposition"] = "Deprecated. Kept for backwards-compatibility."
E2Helper.Descriptions["setAng"] = "Set the rotation of an entity."
E2Helper.Descriptions["rerotate"] = "Deprecated. Kept for backwards-compatibility."
E2Helper.Descriptions["parentTo"] = "Parents one entity to another."
E2Helper.Descriptions["deparent"] = "Unparents an entity, so it moves freely again."
E2Helper.Descriptions["propBreak"] = "Breaks/Explodes breakable/explodable props (Useful for Mines)."
E2Helper.Descriptions["propCanCreate"] = "Returns 1 when propSpawn() will successfully spawn a prop until the limit is reached."
E2Helper.Descriptions["propDrag"] = "Passing 0 makes the entity not be affected by drag"
E2Helper.Descriptions["propDraw"] = "Passing 0 disables rendering for the entity (makes it really invisible)"
E2Helper.Descriptions["propShadow"] = "Passing 0 disables rendering for the entity's shadow"
E2Helper.Descriptions["propSetBuoyancy"] = "Sets the prop's buoyancy ratio from 0 to 1"
E2Helper.Descriptions["propSpawnUndo"] = "Set to 0 to force prop removal on E2 shutdown, and suppress Undo entries for props."
E2Helper.Descriptions["propDeleteAll"] = "Removes all entities spawned by this E2"
