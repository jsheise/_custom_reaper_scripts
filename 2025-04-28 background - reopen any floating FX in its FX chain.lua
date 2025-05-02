--[[
  BLOCK COMMENT TEMPLATE
]]

--------------------------------------------------------------------------------
---------------------------------- HELPERS -------------------------------------
--------------------------------------------------------------------------------
-- flag for enabling Msg function to display messages in the "Reascript console 
-- output" window 
local debug = 1

local projTrackCount_current = 0

-- simplified logging function
function Msg(str)
    if debug == 1 then
        reaper.ShowConsoleMsg(tostring(str) .. "\n\r")
    end
end

function getTrackInfo(trackIdx)
    -- returns MediaTrack type corresponding to track
    local trackMT = reaper.GetTrack(0, trackIdx)
    -- get track state
    local trackName, trackState = reaper.GetTrackState(trackMT)

    return trackMT, trackName, trackState
end

-- written with help from https://gist.github.com/jtackaberry/0ee52278e48d24cce7a3
function moveFloatingFxToChain() 
    projTrackCount_current = reaper.CountTracks(0)

    for trackIdx = 0, projTrackCount_current - 1 do
        currentTrackMT, currentTrackName, currentTrackState = getTrackInfo(trackIdx)
        for fxIdx = 0, reaper.TrackFX_GetCount(currentTrackMT) - 1 do
            if reaper.TrackFX_GetFloatingWindow(currentTrackMT, fxIdx) ~= nil then
                reaper.TrackFX_Show(currentTrackMT, fxIdx, 1)
                reaper.TrackFX_Show(currentTrackMT, fxIdx, 2)
            end
        end -- end  for fxIdx
    end -- end  for trackIdx
end -- end  function

function main()
    moveFloatingFxToChain()
    reaper.defer(main)
end

--------------------------------------------------------------------------------
--------------------------------- SCRIPT START ---------------------------------
--------------------------------------------------------------------------------
projTrackCount_current = 0
reaper.ClearConsole()
main()
  
