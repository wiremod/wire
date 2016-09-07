language.Add("Undone_e2_axis", "Undone E2 Axis")
language.Add("Undone_e2_ballsocket", "Undone E2 Ballsocket")
language.Add("Undone_e2_winch", "Undone E2 Winch")
language.Add("Undone_e2_hydraulic", "Undone E2 Hydraulic")
language.Add("Undone_e2_rope", "Undone E2 Rope")
language.Add("Undone_e2_slider", "Undone E2 Slider")
language.Add("Undone_e2_nocollide", "Undone E2 Nocollide")
language.Add("Undone_e2_weld", "Undone E2 Weld")
E2Helper.Descriptions["enableConstraintUndo"] = "If 0, suppresses creation of undo entries for constraints"
E2Helper.Descriptions["axis(evev)"] = "Creates an axis constraint between two entities at vectors local to each entity"
E2Helper.Descriptions["axis(evevn)"] = "Creates an axis constraint between two entities at vectors local to each entity with friction"
E2Helper.Descriptions["axis(evevnv)"] = "Creates an axis constraint between two entities at vectors local to each entity with friction and local rotation axis"
E2Helper.Descriptions["ballsocket"] = "Creates a ballsocket constraint between two entities at a vector local to ent1"
E2Helper.Descriptions["ballsocket(evevvv)"] = "Creates an AdvBallsocket constraint between two entities at a vector local to ent1, using the specified mins, maxs, and frictions"
E2Helper.Descriptions["ballsocket(evevvvn)"] = "Creates an AdvBallsocket constraint between two entities at a vector local to ent1, using the specified mins, maxs, frictions, rotateonly"
E2Helper.Descriptions["weldAng"] = "Creates an angular weld constraint (angles are fixed, position is free) between two entities at a vector local to ent1"
E2Helper.Descriptions["winch"] = "Creates a winch constraint with a referenceid, between two entities, at vectors local to each"
E2Helper.Descriptions["hydraulic(nevevn)"] = "Creates a hydraulic constraint with a referenceid, between two entities, at vectors local to each"
E2Helper.Descriptions["hydraulic(nevevnnsnn)"] = "Creates a hydraulic constraint with a referenceid, between two entities, at vectors local to each, with constant, damping, and stretch only"
E2Helper.Descriptions["hydraulic(nevevnnnsnn)"] = "Creates a hydraulic constraint with a referenceid, between two entities, at vectors local to each, with constant, damping, relative damping and stretch only"
E2Helper.Descriptions["rope(nevev)"] = "Creates a rope constraint with a referenceid, between two entities, at vectors local to each"
E2Helper.Descriptions["rope(nevevnns)"] = "Creates a rope constraint with a referenceid, between two entities, at vectors local to each with add length, width, and material"
E2Helper.Descriptions["rope(nevevnnsn)"] = "Creates a rope constraint with a referenceid, between two entities, at vectors local to each with add length, width, material, and rigidity"
E2Helper.Descriptions["setLength(e:nn)"] = "Sets the length of a winch/hydraulic/rope stored in this entity at a referenceid"
E2Helper.Descriptions["slider"] = "Creates a slider constraint between two entities at vectors local to each entity"
E2Helper.Descriptions["noCollide"] = "Creates a nocollide constraint between two entities"
E2Helper.Descriptions["noCollideAll"] = "Nocollides an entity to all entities/players, just like the tool's right-click"
E2Helper.Descriptions["weld"] = "Creates a weld constraint between two entities"
E2Helper.Descriptions["constraintBreak(e:)"] = "Breaks all constraints of all types on an entity"
E2Helper.Descriptions["constraintBreak(e:e)"] = "Breaks all constraints between two entities"
E2Helper.Descriptions["constraintBreak(e:s)"] = "Breaks all constraints of a type (weld, axis, nocollide, ballsocket) on an entity"
E2Helper.Descriptions["constraintBreak(e:se)"] = "Breaks a constraint of a type (weld, axis, nocollide, ballsocket) between two entities"
