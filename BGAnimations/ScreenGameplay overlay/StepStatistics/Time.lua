local pNum = GAMESTATE:GetMasterPlayerNumber()

local af = Def.ActorFrame{}

local function FormatTime(seconds)
    if seconds < 0 then seconds = 0 end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%d:%02d", m, s)
end

-- Elapsed Time
af[#af+1] = LoadFont("Common Normal")..{
    InitCommand=function(self)
        self:zoom(0.7)
        self:halign(1)
        self:x(-20)
        self:y(160)
        self:diffuse(color("#aaaaaa"))
        self:settext("elapsed")
    end
}

af[#af+1] = LoadFont("Common Normal")..{
    InitCommand=function(self)
        self:zoom(1.1)
        self:halign(0)
        self:x(20)
        self:y(160)
        self:diffuse(color("#ffffff"))
    end,
    UpdateCommand=function(self)
        self:settext(FormatTime(GAMESTATE:GetCurMusicSeconds()))
    end
}

-- Song Time
af[#af+1] = LoadFont("Common Normal")..{
    InitCommand=function(self)
        self:zoom(0.7)
        self:halign(1)
        self:x(-20)
        self:y(180)
        self:diffuse(color("#aaaaaa"))
        self:settext("song")
    end
}

af[#af+1] = LoadFont("Common Normal")..{
    InitCommand=function(self)
        self:zoom(1.1)
        self:halign(0)
        self:x(20)
        self:y(180)
        self:diffuse(color("#ffffff"))
        local song = GAMESTATE:GetCurrentSong()
        if song then
            self:settext(FormatTime(song:GetLastSecond()))
        end
    end
}

-- Update loop for time
af.InitCommand=function(self)
    self:SetUpdateFunction(function(self) self:playcommand("Update") end)
end

return af
