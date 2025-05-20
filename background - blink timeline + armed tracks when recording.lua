--[[
  Description: Blink record-armed tracks & blink timeline when recording  
  Version: 0.4.0
  Modified: 
  Author: St Evyn (Joseph Heise)
  About: 
    As the description suggests, this script will run in the background to 
    monitor the record-arm status of tracks. If any tracks are record-armed, 
    they will blink red to visually indicate that they are armed.

    This functionality was inspired by how Pro Tools and Logic Pro visually 
    indicate armed tracks. As far as I could tell nobody had already tried this
    by the time I started on the script, hence why I had to figure it out 
    myself! 

    Initial development began 2025-01-31.
  
  Changelog: 

  References/Inspiration: 

]]

--------------------------------------------------------------------------------

--[[
  BLOCK COMMENT TEMPLATE
]]

--------------------------------------------------------------------------------

--[[
Scenarios to consider
 - Ensure that "recording" track color is not captured as original color
    - i.e. what if track count changes while tracks are highlighted with 
      recording red? That'd trigger allTracksRefresh and capture the current red 
      color
    - possible approach: if tracks are currently highilghted ("up" phase) AND 
      the track count has changed, then create a temp copy of allTracks from 
      which we can pull the original color rather than the current highlight
      color, checking if the track is armed beforehand
  - TODO: deleting tracks in middle of track list
  - TODO: moving tracks around
]]

--------------------------------------------------------------------------------

--[[
The last thing I was working on was how to manage tracks getting moved around.

Fortunately, I've got the script recognizing when tracks are moved around
and updating allTracks when that happens (i.e. when the actual track order no 
longer matches that recorded in allTracks).

However, the problem I was facing was the fact that this update will associate
the recording highlight color to the tracks due to the "refresh" called in 
that update.
]]

--------------------------------------------------------------------------------

--[[
2025-05-15
Changes:
- fixed track MCP panel color not updating; used reaper.ThemeLayout_RefreshAll()
- moved updateTimeline() from main() to setRecordingColors() to reduce overhead

Discovered bugs:
- error due to trying to setTrackColor() on nil if armed track is deleted
- if user switches to a different project tab while armed tracks are
  highlighted, color gets committed (any way to avoid this?)

Best solution for the above bugs is to associate the track GUID (not sufficient
to know the track index alone—have to be able to follow tracks)

Next up: finish implementation of track GUID usage 
]]

--------------------------------------------------------------------------------

--[[
2025-05-16

TODO: Any way to get the fader knob to blink as well? There must be since themes
can update that color... Or perhaps it's an image, in which case I would have to
swap out the images on every transition.
This idea was inspired by reviewing how Cubase indicates armed tracks.

For today, goal is to get use of track GUIDs implemented to address bugs in 
removing/adding/rearranging tracks—particularly when these actions are performed
on "in-between" tracks.


Current pseudocode...
[script start]
Clear console, initialize variables, print tracks
main()









reaper.ClearConsole()

projTrackCount_current = reaper.CountTracks(0)
projTrackCount_previous = projTrackCount_current

-- instantiate armedTracks
armedTracks = {} 
allTracksRefresh()

time_start = reaper.time_precise()
elapsed = 0
elapsed_previous = 0

playstate_previous = 0
playstate_current = 0

allTracksPrint()
Msg("")
Msg("......................................")
Msg("")

main()



]]


--------------------------------------------------------------------------------
-------------------------------- COLOR VARIABLES -------------------------------
--------------------------------------------------------------------------------
trackColArmed = reaper.ColorToNative( 252, 93, 95 ) -- colorIndex = 23027196 
-- trackColArmed2 = reaper.ColorToNative( 255, 255, 255 )

trackDefaultColor = reaper.ColorToNative( 130, 130, 130 )  -- if unset and trackColor updated, then track colorIndex becomes 16777216 

-- tl_bg = timeline background color
local tl_bg_normal = reaper.GetThemeColor("col_tl_bg", 0)
-- local tl_bg_normal_r, tl_bg_normal_g, tl_bg_normal_b = reaper.ColorFromNative(tl_bg_normal)
local tl_bg_recording = reaper.ColorToNative( 252, 93, 95 )

-- tl_fg = timeline text + lines color
local tl_fg_normal = reaper.GetThemeColor("col_tl_fg", 0)
-- local tl_fg_normal_r, tl_fg_normal_g, tl_fg_normal_b = reaper.ColorFromNative(tl_fg_normal)
local tl_fg_recording = reaper.ColorToNative( 255, 255, 255 )

-- tl_fg2 = ???
local tl_fg2_normal = reaper.GetThemeColor("col_tl_fg2", 0)

-- playcursor color
local playcursor_color_normal = reaper.GetThemeColor("playcursor_color", 0) 
local playcursor_color_recording = reaper.ColorToNative( 252, 93, 95 )

--------------------------------------------------------------------------------
---------------------------------- HELPERS -------------------------------------
--------------------------------------------------------------------------------
-- flag for enabling Msg function to display messages in the "Reascript console 
-- output" window 
local debug = 1

function Msg(str)
  if debug == 1 then
    reaper.ShowConsoleMsg(tostring(str) .. "\n\r")
  end
end

--------------------------------------------------------------------------------

function isTrackArmed(trackIdx)
  -- returns MediaTrack type corresponding to track
  local trackMT = reaper.GetTrack(0, trackIdx)
  -- get track state
  local trackName, trackState = reaper.GetTrackState(trackMT)
  local isTrackArmed = (trackState & 64 == 64)
  return isTrackArmed
end





local function allTracks_SetArmedColor ()
  for idx, track in ipairs(allTracks) do 
    if track then 
      if track.armed == 1 then 
        reaper.SetTrackColor(track.trackMT, trackColArmed)
      end 
    end -- end  if track (is not nil) 
  end -- end  for 
end -- end  function

local function allTracks_UnsetArmedColor ()
  for idx, track in ipairs(allTracks) do 
    if track then 
      --if track.armed == 1 then 
        trackOriginalColorIndex = 0
        for idxCol, trackCol in ipairs(originalColors) do 
          if track.trackMT == trackCol.trackMT then 
            trackOriginalColorIndex = trackCol.colorIndex
          end
        end
        reaper.SetTrackColor(track.trackMT, trackOriginalColorIndex)
      --end
    end -- end  if track (is not nil) 
  end -- end  for 
end -- end  function

local function allTracksUpdate_tracksRemoved ()
  allTracks_tmp = {} 
  for i = 0, projTrackCount_current - 1 do
    table.insert( allTracks_tmp, { trackIdx = allTracks[i+1].trackIdx, armed = allTracks[i+1].armed , colorIndex = allTracks[i+1].colorIndex, trackMT = allTracks[i+1].trackMT, trackGUID = allTracks[i+1].trackGUID } )
  end -- end  for
  allTracks = {} 
  allTracks = allTracks_tmp
end  -- end  function

local function allTracks_verifyTracksMatch ()
  for idx, track in ipairs(allTracks) do 
    if track then 
      if track.trackMT ~= reaper.GetTrack(0, idx-1) then 
        Msg("allTracks[" .. idx .. "] does not match track with index " .. idx-1)
        allTracksRefresh ()
        return
      end
    else 
      Msg("allTracks[" .. i .. "] = NULL")
    end  -- end  if track (is not nil)
  end -- end  for
end  -- end  function


--[[
local function timeline_SetRecColor ()
  reaper.SetThemeColor("col_tl_bg",  tl_bg_recording)
  reaper.SetThemeColor("col_tl_fg",  tl_fg_recording)
  reaper.SetThemeColor("col_tl_fg2", tl_fg_recording)
end -- end  function

local function timeline_UnsetRecColor ()
  reaper.SetThemeColor("col_tl_bg", tl_bg_normal)
  reaper.SetThemeColor("col_tl_fg", tl_fg_normal)
  reaper.SetThemeColor("col_tl_fg2", tl_fg2_normal)
end -- end  function
]]





--[[
  Gets relevant data for a track provided the track's index (i.e. position in the project).
]]
function getTrackInfo(trackIdx)
  -- returns MediaTrack type corresponding to track
  local trackMT = reaper.GetTrack(0, trackIdx)
  -- get track state
  local trackName, trackState = reaper.GetTrackState(trackMT)
  local isTrackArmed = (trackState & 64 == 64) and 1 or 0
  -- get track GUID
  trackGUID = reaper.GetTrackGUID(trackMT)
  return trackMT, trackName, trackState, isTrackArmed, trackGUID
end

--[[
  Repopulate the allTracks array/table.
  { {idx, name, armed, colorIndex, trackMT, trackGUID}, ... }
]]
local function allTracksRefresh()
  allTracks_tmp = {} 
  for i = 0, projTrackCount_current - 1 do
    currentTrackMT, currentTrackName, currentTrackState, currentTrackArmed, currentTrackGUID = getTrackInfo(i)
    table.insert( allTracks_tmp, { trackIdx = i, trackName = currentTrackName, armed = currentTrackArmed , colorIndex = reaper.GetTrackColor(currentTrackMT), trackMT = currentTrackMT, trackGUID = currentTrackGUID } )
  end -- end  for
  return allTracks_tmp
end  -- end  function

local function originalColorsRefresh()
  originalColors_tmp = {} 
  for i = 0, projTrackCount_current - 1 do
    currentTrackMT, currentTrackName, currentTrackState, currentTrackArmed, currentTrackGUID = getTrackInfo(i)
    table.insert( originalColors_tmp, { trackMT = currentTrackMT, trackGUID = currentTrackGUID, colorIndex = reaper.GetTrackColor(currentTrackMT) } )
  end -- end  for
  return originalColors_tmp
end  -- end  function

--[[
  Prints the allTracks array/table, where each line represents an array/table entry.
  {idx, name, armed, colorIndex, GUID}
]]
local function allTracksPrint()
  for idx, track in ipairs(allTracks) do 
    if track then 
      Msg("allTracks[" .. idx .. "] = { trackIdx = " .. track.trackIdx .. ", trackName = " .. track.trackName .. ", armed = " .. track.armed .. ", colorIndex = " .. track.colorIndex .. ", trackGUID = " .. track.trackGUID .. " }")
    else 
      Msg("allTracks[" .. idx .. "] = NULL")
    end  -- end  if track (is not nil)
  end -- end  for
end -- end  function


function setRecordingColors()
  elapsed = reaper.time_precise() - time_start
  elasped_s = math.floor(elapsed) 

  if elapsed - elapsed_previous > 1 then
    elapsed_previous = elapsed
    Msg("elasped_s = " .. elasped_s)

    

    -- count tracks in active project and check if changed
    projTrackCount_current = reaper.CountTracks(0)
    

    if projTrackCount_current ~= projTrackCount_previous then
      Msg("The number of tracks in the active project has changed from " .. projTrackCount_previous .. " to " .. projTrackCount_current)
      if projTrackCount_current < projTrackCount_previous then
        --allTracksUpdate_tracksRemoved()
        --allTracks_UnsetArmedColor()
      else
        --allTracks_UnsetArmedColor()
        -- allTracksRefresh()
      end
      projTrackCount_previous = projTrackCount_current
    else
      Msg("There are " .. projTrackCount_current .. " tracks in the active project (no change).")
    end



    -- TODO: check if track order matches previous state

    allTracks = allTracksRefresh()
    allTracksPrint()

    if math.floor(elasped_s % 2) == 1 then 
      allTracks_SetArmedColor()

      --if reaper.GetPlayState() == 5 then -- if recording
        --timeline_SetRecColor()
      --end
    else 
      --allTracks_verifyTracksMatch()
      allTracks_UnsetArmedColor()
      --timeline_UnsetRecColor()
      originalColors = originalColorsRefresh()
    end -- end  if on an even second count 

    reaper.UpdateTimeline()
    reaper.ThemeLayout_RefreshAll() -- hacky way to get the MCP track panel color to update as well, but creates a small period that disallows user actions 

    Msg("......................................")
  end -- end  if elapsed - elapsed_previous > 2
end -- end  setRecordingColors



function main()
  setRecordingColors()
  -- reaper.UpdateTimeline()
  reaper.defer(main)
end



--------------------------------------------------------------------------------
--------------------------------- SCRIPT START ---------------------------------
--------------------------------------------------------------------------------
reaper.ClearConsole()

-- time
time_start = reaper.time_precise()
elapsed = 0
elapsed_previous = 0

-- project track count 
projTrackCount_current = reaper.CountTracks(0)
projTrackCount_previous = projTrackCount_current

-- play state
playstate_previous = 0
playstate_current = 0

-- arrays
armedTracks = {} 
allTracks = allTracksRefresh()
originalColors = originalColorsRefresh()
allTracksPrint()

Msg("")
Msg("......................................")
Msg("")

main()

--[[
https://forums.cockos.com/showthread.php?t=256120
A script is not allowed to "loop". It needs to quickly do its thing and return.
That is because all scripts (and the GUI and...) all run on the same OS thread
one after the other and never in parallel, nor intercepting each other. Hence a
loop in a script would stall Reaper completely. 
So your algorithm needs to be a "state machine". It needs to hold a set of
variables to define a "state". 
Each run might modify the state and return. The next run then acts according to
that state. Each run is triggered by something calling the appropriate action or
by "defer" from the script itself.


]]
