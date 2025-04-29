--[[
RESOURCES:
-- https://wiki.cockos.com/wiki/index.php/RPR_GetSelectedTrack
-- https://forums.cockos.com/showthread.php?t=290900
--     https://mespotin.uber.space/Ultraschall/Reaper_Config_Variables.html#prerollmeas
]]

CURR_PROJ = 0; -- current project
FIRST = 0; -- first selected track 

-- Set pre-roll to (4) measures
reaper.SNM_SetDoubleConfigVar("prerollmeas", 4)
