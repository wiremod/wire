local editing = {}
 
hook.Add("E2_IsEditing","E2_IsEditing_Hook",function(ply,set)
        editing[ply] = set
end)
 
__e2setcost(5)
e2function number entity:isE2Editing()
        if !IsValid(this) then return 0 end
        if !this:IsPlayer() then return 0 end
       
        //return editing[this] != nil ? 1 : 0
        if editing[this] and editing[this] ~= nil then return 1
        else return 0 end
end