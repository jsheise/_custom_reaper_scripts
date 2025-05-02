

--[[
  BLOCK COMMENT TEMPLATE
]]

--[[
The last thing I was working on was how to manage tracks getting moved around.

Fortunately, I've got the script recognizing when tracks are moved around
and updating allTracks when that happens (i.e. when the actual track order no 
longer matches that recorded in allTracks).

However, the problem I was facing was the fact that this update will associate
the recording highlight color to the tracks due to the "refresh" called in 
that update.

]]

--[[
Scenarios to consider
 - User switches to different project tab
 - Track becomes armed/disarmed
 - Ensure that "recording" track color is not captured as original color
    - i.e. what if track count changes while tracks are highlighted with 
      recording red? That'd trigger allTracksRefresh and capture the current red color
    - possible approach: if tracks are currently highilghted ("up" phase) AND 
      the track count has changed, then create a temp copy of allTracks from 
      which we can pull the original color rather than the current highlight
      color, checking if the track is armed beforehand
  - TODO: deleting tracks in middle of track list
  - TODO: moving tracks around
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

function getTrackInfo(trackIdx)
  -- returns MediaTrack type corresponding to track
  local trackMT = reaper.GetTrack(0, trackIdx)
  
  -- get track state
  local trackName, trackState = reaper.GetTrackState(trackMT)
  
  local isTrackArmed = (trackState & 64 == 64)
  
  return trackMT, trackName, trackState, isTrackArmed
end

function isTrackArmed(trackIdx)
  -- returns MediaTrack type corresponding to track
  local trackMT = reaper.GetTrack(0, trackIdx)
  
  -- get track state
  local trackName, trackState = reaper.GetTrackState(trackMT)
  
  local isTrackArmed = (trackState & 64 == 64)
  
  return isTrackArmed
end

-- instantiate and initialize allTracks to empty table/array
allTracks = {} 

local function allTracksRefresh ()
  allTracks = {} 
  for i = 0, projTrackCount_current - 1 do
    currentTrackMT, currentTrackName, currentTrackState, currentTrackArmed = getTrackInfo(i)
    table.insert( allTracks, { trackIdx = i, armed = 0 , colorIndex = reaper.GetTrackColor(currentTrackMT), trackMT = currentTrackMT } )

    if currentTrackArmed then
      Msg("Track with index " .. i .. " is ARMED")
      -- table.insert( allTracks, { trackIdx = i, armed = 1 , colorIndex = reaper.GetTrackColor(currentTrackMT), trackMT = currentTrackMT } )
      allTracks[i+1].armed = 1
    else
      Msg("Track with index " .. i .. " is NOT armed")
      -- table.insert( allTracks, { trackIdx = i, armed = 0 , colorIndex = reaper.GetTrackColor(currentTrackMT), trackMT = currentTrackMT } )
    end -- end  if currentTrackArmed

  end -- end  for
end  -- end  function

local function allTracksPrint ()
  for idx, track in ipairs(allTracks) do 
    if track then 
      Msg("allTracks[" .. idx .. "] = { trackIdx = " .. track.trackIdx .. ", armed = " .. track.armed .. ", colorIndex = " .. track.colorIndex .. " }")
    else 
      Msg("allTracks[" .. idx .. "] = NULL")
    end  -- end  if track (is not nil)
  end -- end  for
end -- end  function

local function allTracks_SetArmedColor ()
  for idx, track in ipairs(allTracks) do 
    if track then 
      if isTrackArmed(track.trackIdx) then 
        reaper.SetTrackColor(track.trackMT, trackColArmed)
        track.armed = 1
      else
        track.armed = 0
      end 
    end -- end  if track (is not nil) 
  end -- end  for 
end -- end  function

local function allTracks_UnsetArmedColor ()
  for idx, track in ipairs(allTracks) do 
    if track then 
      if isTrackArmed(track.trackIdx) then 
        reaper.SetTrackColor(track.trackMT, track.colorIndex)
        track.armed = 1
      else
        if track.armed == 1 then
          reaper.SetTrackColor(track.trackMT, track.colorIndex)
        end 
        track.armed = 0
      end
    end -- end  if track (is not nil) 
  end -- end  for 
end -- end  function

local function allTracksUpdate_tracksRemoved ()
  allTracks_tmp = {} 

  for i = 0, projTrackCount_current - 1 do
    table.insert( allTracks_tmp, { trackIdx = allTracks[i+1].trackIdx, armed = allTracks[i+1].armed , colorIndex = allTracks[i+1].colorIndex, trackMT = allTracks[i+1].trackMT } )
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
        allTracksUpdate_tracksRemoved()
        allTracks_UnsetArmedColor()
      else
        allTracks_UnsetArmedColor()
        allTracksRefresh()
      end
      projTrackCount_previous = projTrackCount_current

    else
      Msg("There are " .. projTrackCount_current .. " tracks in the active project (no change).")
    end

    allTracksPrint()

    -- if on an odd second count
    if math.floor(elasped_s % 2) == 1 then 
      allTracks_SetArmedColor()
      if reaper.GetPlayState() == 5 then -- if not recording
        timeline_SetRecColor()
      end
    -- if on an even second count
    else 
      allTracks_verifyTracksMatch()
      allTracks_UnsetArmedColor()
      timeline_UnsetRecColor()
    end -- end  if on an even second count 

    Msg("......................................")
  end -- end  if elapsed - elapsed_previous > 2
end -- end  setRecordingColors

function main()
  setRecordingColors()
  reaper.UpdateTimeline()
  reaper.defer(main)
end

--------------------------------------------------------------------------------
--------------------------------- SCRIPT START ---------------------------------
--------------------------------------------------------------------------------
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
