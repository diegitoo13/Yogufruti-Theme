return function(PlayerScore)
    local TimingMode = LoadModule("Config.Load.lua")("SmartTimings", "Save/OutFoxPrefs.ini")
    local PumpTiming = string.find(TimingMode, "Pump")

    local PlateText = "Rough"

    local TNSPerfect = "TapNoteScore_W" .. (PumpTiming and "1" or "2")
    local TNSGreat = "TapNoteScore_W" .. (PumpTiming and "2" or "3")
    local TNSGood = "TapNoteScore_W" .. (PumpTiming and "3" or "4")
    local TNSBad = "TapNoteScore_W" .. (PumpTiming and "4" or "5")
	local FailGrade = PlayerScore:GetGrade()
    local bFailed = false
    if PlayerScore.GetFailed then
        bFailed = PlayerScore:GetFailed()
    else
        bFailed = (FailGrade == "Grade_Failed" or FailGrade == "Failed" or tostring(FailGrade) == "Grade_Failed")
    end
    local Checkpoints = PlayerScore:GetTapNoteScores("TapNoteScore_CheckpointHit")
    local Superbs 	= PumpTiming and 0 or PlayerScore:GetTapNoteScores("TapNoteScore_W1")
    local Perfects 	= PlayerScore:GetTapNoteScores(TNSPerfect) + Checkpoints
    local Greats 	= PlayerScore:GetTapNoteScores(TNSGreat)
    local Goods 	= PlayerScore:GetTapNoteScores(TNSGood)
    local Bads	 	= PlayerScore:GetTapNoteScores(TNSBad)
    local Misses 	= PlayerScore:GetTapNoteScores("TapNoteScore_Miss") +
                      PlayerScore:GetTapNoteScores("TapNoteScore_CheckpointMiss")

    -- The good ol' if staircase
    if bFailed then
        PlateText = "Fail"
    elseif Misses == 0 then
        if Bads == 0 then
            if Goods == 0 then
                if Greats == 0 then
                    PlateText = "Perfect"
                else
                    PlateText = "Ultimate"
                end
            else
                PlateText = "Extreme"
            end
        else
            PlateText = "Superb"
        end
    elseif Misses <= 5 then
        PlateText = "Marvelous"
    elseif Misses <= 10 then
        PlateText = "Talented"
    elseif Misses <= 20 then
        PlateText = "Fair"
    else
        PlateText = "Rough"
    end

    return PlateText .. "Game"
end
