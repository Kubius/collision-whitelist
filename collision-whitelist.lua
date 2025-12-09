local default_masks = require("__core__/lualib/collision-mask-defaults")

---------------------------------------------------
--[[-----------------------------------------------
setup_whitelist is the only function provided by this mod.
Include it at a late data stage (typically final fixes) to iterate over prototypes.
Required parameters:
- mask_id: The string for the collision mask you'd like to introduce to objects NOT specified by whitelisting.
At least one of:
- prototype_types: A list of kinds of prototype you'd like to be whitelisted (for example, "transport-belt").
- object_names: A list of specific objects you'd like to be whitelisted (for example, "assembling-machine-1").
Optional:
- construction_only: By default, only player-constructed on-grid objects are blacklisted.
  Set this to false, and everything with the is_object collision mask will be eligible for blacklisting.
]]-------------------------------------------------
---------------------------------------------------

local function setup_whitelist(params)
  local mask_id = params.mask_id
  local construction_only = params.construction_only or true
  local prototype_types = params.prototype_types or nil
  local object_names = params.object_names or nil
  local construction_only_string = "constructed objects only"
  if construction_only == false then
    local construction_only_string = "all eligible is_object entities"
  end

  log("collision-whitelist: beginning mask application for collision mask " .. mask_id)
  log("collision-whitelist: blacklist will be applied to " .. construction_only_string)

  for set_type,set in pairs(data.raw) do
    --Get prototype type sets, check them first (if entire type is exempt we don't need to go further)
    local continue_to_item = true
    if prototype_types then
      for _,checktype in pairs(prototype_types) do
        if(set_type == checktype) then
          continue_to_item = false
          break
        end
      end
    end

    
    if continue_to_item then
      for _,prototype in pairs(set) do 
        --Flag evaluation; if we're limiting ourselves to only influencing constructed objects, don't bother delving further on the others
        local pre_eval = false
        if construction_only == true then
          if prototype.flags then
            local not_offgrid = true
            for _,flag in pairs(prototype.flags) do
              if (flag == "placeable-off-grid") then
                not_offgrid = false
              elseif (flag == "player-creation") then
                pre_eval = true
              end
            end
            pre_eval = pre_eval and not_offgrid
          end
        else
          pre_eval = true
        end
        --
        
        --Collision mask evaluation and final mask application
        if pre_eval == true then
          local mask_handler = nil
          local initialize_mask = false --If the entity did not previously have a mask differing from its category, we'll need to set that up
          if prototype.collision_mask then
            mask_handler = prototype.collision_mask.layers
          elseif default_masks[set_type] then
            fetcher = default_masks[set_type]
            if fetcher.layers and #fetcher.layers then
              mask_handler = fetcher.layers
              initialize_mask = true
            end
          end
          if mask_handler then
            local mask = mask_handler
            if mask["is_object"] then
              local do_collide = true
              if object_names then
                for _,checkname in pairs(object_names) do
                  if(prototype.name == checkname) then
                    do_collide = false
                    break
                  end
                end
              end

              if do_collide == true then --don't mess with the field at all if we're not setting it to true
                if initialize_mask then
                  prototype.collision_mask = default_masks[set_type]
                end
                mask[mask_id] = true
              end

            end
          end
        end
        --
      end
    end

  end
end

return
{
  setup_whitelist = setup_whitelist
}
