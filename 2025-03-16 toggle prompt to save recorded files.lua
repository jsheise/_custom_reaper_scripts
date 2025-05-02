--[[
  BLOCK COMMENT TEMPLATE
]]

--------------------------------------------------------------------------------
---------------------------------- HELPERS -------------------------------------
--------------------------------------------------------------------------------
-- flag for enabling Msg function to display messages in the "Reascript console 
-- output" window 
local debug = 0

function Msg(str)
  if debug == 1 then 
    reaper.ShowConsoleMsg(tostring(str) .. "\n\r")
  end
end

--------------------------------------------------------------------------------
--------------------------------- SCRIPT START ---------------------------------
--------------------------------------------------------------------------------
local promptEndRec = reaper.SNM_GetIntConfigVar("promptendrec", 0)
Msg("promptEndRec = " .. promptEndRec)

-- if prompt to save file is enabled on stop, disable it; otherwise enable it
if promptEndRec == 1 then
  reaper.SNM_SetIntConfigVar("promptendrec", 0)
else 
  reaper.SNM_SetIntConfigVar("promptendrec", 1)
end 


--[[
--------------------------------------------------------------------------------
---------------------------------- REFERENCES ----------------------------------
--------------------------------------------------------------------------------

https://github.com/mespotine/ultraschall-and-reaper-docs/blob/master/Docs/Reaper-ConfigVariables-Documentation.txt#L634
https://forums.cockos.com/showthread.php?t=266962

# The following 415 variable-names can be used for the SWS-functions 
#
#    SNM_GetIntConfigVar(), SNM_SetIntConfigVar(), SNM_GetDoubleConfigVar() and SNM_SetDoubleConfigVar(), 
# as well as the C++-only functions
#    get_config_var(), projectconfig_var_addr() and projectconfig_var_getoffs()
# and Reaper's prerelease-only function
#    get_config_var_string()

# They are either double or integer-values. The integer-values are usually bitfields, where every bit stores 
# e.g. the value of a checkbox in the preferences.

# to get/set integer(-bitfield) variables, use the functions SNM_GetIntConfigVar or SNM_SetIntConfigVar.

# I documented bitfields differently than you usually use them. That means, &16384=1 is actually &16384=16384, 
# while &16384=0 is &16384=0. This is only for better readability of the document, not for any technical reasons.
# Some bitfields are documented as "unknown", though it's uncertain if they're unknown or just unused.

promptendrec
    Prompt to save/delete/rename new files-checkboxes, as set in Preferences -> Recording, as well as in the dialog opened when finishing recording
    It is an integer-bitfield
        &1=0, on stop(off) - unchecked
        &1=1, on stop(on) - checked
        
        &2=0, on punch-out/play(off) - unchecked
        &2=1, on punch-out/play(on) - checked

]] 