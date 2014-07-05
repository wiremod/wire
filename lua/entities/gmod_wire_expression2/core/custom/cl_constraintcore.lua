language.Add("Undone_e2_axis", "Undone E2 Axis")
language.Add("Undone_e2_ballsocket", "Undone E2 Ballsocket")
language.Add("Undone_e2_winch", "Undone E2 Winch")
language.Add("Undone_e2_hydraulic", "Undone E2 Hydraulic")
language.Add("Undone_e2_rope", "Undone E2 Rope")
language.Add("Undone_e2_slider", "Undone E2 Slider")
language.Add("Undone_e2_nocollide", "Undone E2 Nocollide")
language.Add("Undone_e2_weld", "Undone E2 Weld")
E2Helper.Descriptions["enableConstraintUndo"] = "If 0, suppresses creation of undo entries for constraints"
E2Helper.Descriptions["axis"] = "Creates an axis constraint between two entities at vectors local to each entity"
E2Helper.Descriptions["ballsocket"] = "Creates a ballsocket constraint between two entities at a vector local to ent1"
E2Helper.Descriptions["ballsocket(evevvv)"] = "Creates an AdvBallsocket constraint between two entities at a vector local to ent1, using the specified mins, maxs, and frictions)"
E2Helper.Descriptions["weldAng"] = "Creates an angular weld constraint (angles are fixed, position is free) between two entities at a vector local to ent1"
E2Helper.Descriptions["winch"] = "Creates a winch constraint with a referenceid, between two entities, at vectors local to each"
E2Helper.Descriptions["hydraulic"] = "Creates a hydraulic constraint with a referenceid, between two entities, at vectors local to each"
E2Helper.Descriptions["rope"] = "Creates a rope constraint with a referenceid, between two entities, at vectors local to each"
E2Helper.Descriptions["e:setLength(nn)"] = "Sets the length of a winch/hydraulic/rope stored in this entity at a referenceid"
E2Helper.Descriptions["slider"] = "Creates a slider constraint between two entities at vectors local to each entity"
E2Helper.Descriptions["noCollide"] = "Creates a nocollide constraint between two entities"
E2Helper.Descriptions["noCollideAll"] = "Nocollides an entity to all entities/players, just like the tool's right-click"
E2Helper.Descriptions["weld"] = "Creates a weld constraint between two entities"
E2Helper.Descriptions["e:constraintBreak()"] = "Breaks all constraints of all types on an entity"
E2Helper.Descriptions["e:constraintBreak(e)"] = "Breaks all constraints between two entities"
E2Helper.Descriptions["e:constraintBreak(s)"] = "Breaks all constraints of a type (weld, axis, nocollide, ballsocket) on an entity"
E2Helper.Descriptions["e:constraintBreak(se)"] = "Breaks a constraint of a type (weld, axis, nocollide, ballsocket) between two entities"
