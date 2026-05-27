local pn = ...
local TimingMode = LoadModule("Config.Load.lua")("SmartTimings","Save/OutFoxPrefs.ini") or "Original"
local Scoring = LoadModule("Config.Load.lua")("ScoringSystem", "Save/OutFoxPrefs.ini") or "Phoenix"
if TimingMode == "Pump Phoenix" then
    Scoring = "Phoenix"
end
local ShouldReverse = LoadModule("Config.Load.lua")("LifePositionBelow","Save/OutFoxPrefs.ini")

local styleType = GAMESTATE:GetCurrentStyle():GetStyleType()
local isDouble = (styleType == "StyleType_OnePlayerTwoSides" or styleType == "StyleType_TwoPlayersSharedSides")

local BarW = isDouble and 754 or 388
local BarH = 34
local MeterW = isDouble and 736 or 370
local MeterH = 20

local MeterHot = false
local MeterHotPro = false
local MeterDanger = false
local MeterFail = false

local SongPos = GAMESTATE:GetPlayerState(pn):GetSongPosition()
local MeterActor
local MeterUpdate = function(self)
    if not MeterActor then return end
    local MeterVelocity = -(SongPos:GetCurBPS() * 0.5)
    if SongPos:GetFreeze() or SongPos:GetDelay() then MeterVelocity = 0 end
    MeterActor:texcoordvelocity(MeterVelocity, 0)
end

local IsReverse = GAMESTATE:GetPlayerState(pn):GetCurrentPlayerOptions():Reverse() > 0 and ShouldReverse
local ScoreDisplay = LoadModule("Config.Load.lua")("ScoreDisplay", CheckIfUserOrMachineProfile(string.sub(pn, -1) - 1).."/OutFoxPrefs.ini")
local SongProgress = LoadModule("Config.Load.lua")("SongProgress", CheckIfUserOrMachineProfile(string.sub(pn, -1) - 1).."/OutFoxPrefs.ini")
local ProLifebar = LoadModule("Config.Load.lua")("ProLifebar", CheckIfUserOrMachineProfile(string.sub(pn, -1) - 1).."/OutFoxPrefs.ini") and string.find(TimingMode, "Pump")
local ProLifebarMax = 1
local ProLifebarCrop = 1

local t = Def.ActorFrame {
    InitCommand=function(self)
		self:SetUpdateFunction(MeterUpdate):addy(IsReverse and 100 or -100)

		if ProLifebar then
			local StepData = GAMESTATE:GetCurrentSteps(pn)
			local StepLevel = StepData:GetMeter()
			-- Temporarily raise three decimals for the overflow formula
			ProLifebarMax = 1000
			-- Limit co-op and other level >30 charts
			if StepLevel > 30 then
				ProLifebarMax = ProLifebarMax + 2700
			else
				ProLifebarMax = ProLifebarMax + StepLevel * StepLevel * 3
			end
			-- Bring the value back to our smaller, usable number
			ProLifebarMax = ProLifebarMax / 1000
			-- The Pro lifebar crop should only start to change when life reaches overflow,
			-- so for our calculations we will subtract the normal life limit of 1
			ProLifebarCrop = 1 / (ProLifebarMax - 1)
		end
	end,

    OnCommand=function(self) self:easeoutexpo(1):addy(IsReverse and -100 or 100):playcommand("Refresh", {Player = pn, Life = 0.5}) end,

    -- This message command is only used if the Gameplay.Life module is active. Due to it being able to
    -- manipulate the player's health, it can restore life and break certain fail conditions, so the visible
    -- health has been decoupled from the engine one.
    UpdateLifeMessageCommand=function(self, params) self:playcommand("Refresh", params) end,

    -- This is required only if a Pump timing mode is not being used.
    LifeChangedMessageCommand=function(self, params)
        if not string.find(TimingMode, "Pump") then
            self:playcommand("Refresh", { Player = params.Player, Life = params.LifeMeter:GetLife() })
        end
    end,

    RefreshMessageCommand=function(self, params)
        if params.Player == pn then
            local LifeAmount = params.Life or 0.5

            if LifeAmount <= 0.33 and not MeterDanger then
                self:GetChild("Meter"):setstate(1) -- Switch to Red (state 1)
		        self:GetChild("Tip"):visible(0)
		        self:GetChild("Tip-Danger"):visible(1)
                MeterDanger = true
            elseif LifeAmount > 0.33 and MeterDanger and not MeterFail then
                self:GetChild("Meter"):setstate(pn == PLAYER_1 and 0 or 1) -- Switch back to P1 (0) / P2 (1)
		        self:GetChild("Tip-Danger"):visible(0)
                MeterDanger = false
            end

			-- Let's branch out this code so that things aren't too messy/hard to understand
			if ProLifebar then
				-- Only show the rainbow meter if the overflow health is full
				if LifeAmount >= ProLifebarMax and not MeterHotPro then
					self:GetChild("RainbowMeter"):stoptweening():linear(0.5):diffusealpha(1)
					MeterHotPro = true
				elseif LifeAmount < ProLifebarMax and MeterHotPro then
					self:GetChild("RainbowMeter"):diffusealpha(0)
					MeterHotPro = false
				end

				if LifeAmount >= 1 and not MeterHot then
					MeterHot = true
				elseif LifeAmount < 1 and MeterHot then
					MeterHot = false
				end

				self:GetChild("Meter"):finishtweening():linear(0.1):cropright(1 - LifeAmount)
				self:GetChild("Pulse"):finishtweening():linear(0.1):cropright(1 - LifeAmount)

				local ProLifeAmount = ProLifebarCrop * (LifeAmount - 1)
				if ProLifeAmount < 0 then ProLifeAmount = 0 end

				self:GetChild("ProMeter"):finishtweening():linear(0.1):cropright(1 - ProLifeAmount)
				self:GetChild("ProPulse"):finishtweening():linear(0.1):cropright(1 - ProLifeAmount)
				
				-- lifebar tip for the pro meter
				-- make sure the pro tip only appears when you actually have pro lifebar available, and hide it like usual when capped
				-- this could probably be done better but it works so whatever :V
				if ProLifeAmount <= 0 then
					self:GetChild("Tip-Pro"):finishtweening():linear(0.1):x(-(((MeterW) / 2) - (0)))
					self:GetChild("Tip-Pro"):visible(0)
				elseif ProLifeAmount > 0 and ProLifeAmount <= 0.999 and not MeterHotPro then
					self:GetChild("Tip-Pro"):finishtweening():linear(0.1):x(-(((MeterW) / 2) - ((MeterW) * ProLifeAmount)))
					self:GetChild("Tip-Pro"):visible(1)
				elseif ProLifeAmount >=1 or MeterHotPro then
					self:GetChild("Tip-Pro"):finishtweening():linear(0.1):x(-(((MeterW) / 2) - ((MeterW) * 1)))
					self:GetChild("Tip-Pro"):visible(0)
				end
			else
				-- Normal lifebar shenanigans
				if LifeAmount >= 1 and not MeterHot then
					self:GetChild("RainbowMeter"):stoptweening():linear(0.5):diffusealpha(1)
					MeterHot = true
				elseif LifeAmount < 1 and MeterHot then
					self:GetChild("RainbowMeter"):diffusealpha(0)
					MeterHot = false
				end

				self:GetChild("Meter"):finishtweening():linear(0.1):cropright(1 - LifeAmount)
				self:GetChild("Pulse"):finishtweening():linear(0.1):cropright(1 - LifeAmount)
			end
			
			self:GetChild("Tip"):finishtweening():linear(0.1):x(-(((MeterW) / 2) - ((MeterW) * LifeAmount)))
			self:GetChild("Tip-Danger"):finishtweening():linear(0.1):x(-(((MeterW) / 2) - ((MeterW) * LifeAmount)))
			
			-- garbage to make sure that the lifebar actually tweens properly and doesn't just run away from the edge of the lifebar
			-- extra tweening despite lifebar being capped out is just to ensure less jank when the lifebar exits a 'hot' state
			if LifeAmount >=1 and MeterHot and not MeterFail then
				self:GetChild("Tip"):finishtweening():linear(0.1):x(-(((MeterW) / 2) - ((MeterW) * 1)))
				self:GetChild("Tip"):visible(0)
		    elseif LifeAmount > 0.33 and not MeterDanger and not MeterFail then
				self:GetChild("Tip"):visible(1)
			end
			
			-- gdi i forgot about the danger/fail tip fleeing too if you lose it when failing
			-- this took way too long to figure out for whatever reason aaaaaaaaaa
			if LifeAmount >=1 and MeterFail then
			    self:GetChild("Tip-Danger"):finishtweening():linear(0.1):x(-(((MeterW) / 2) - ((MeterW) * 1)))
				self:GetChild("Tip-Danger"):visible(0)
		    elseif LifeAmount > 0 and LifeAmount <= 0.999 and MeterFail then
				self:GetChild("Tip-Danger"):visible(1)
			end

            local PlayerOptions = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
            if LifeAmount <= 0 and not MeterFail then
                MeterFail = true
                self:GetChild("Meter"):setstate(2) -- Switch to Grey/Failed (state 2)
            elseif LifeAmount > 0 and MeterFail and (PlayerOptions:FailSetting() == "FailType_Off") then
                MeterFail = false
                self:GetChild("Meter"):setstate(pn == PLAYER_1 and 0 or 1)
            end
        end
    end,



    Def.Sprite {
        Name="BarBody",
        Texture=isDouble and "../../Phoenix/SG-BACKBARDOUBLE 1x2.PNG" or "../../Phoenix/SG-BACKBARONE 1x2.PNG",
        InitCommand=function(self)
            self:animate(false)
            :setstate(pn == PLAYER_1 and 0 or 1)
            :zoomto(BarW, BarH)
        end
    },

    Def.Quad {
        Name="BarEdgeL",
        InitCommand=function(self)
            self:visible(false):zoomto(0, 0)
        end
    },

    Def.Sprite {
        Name="BarEdgeR",
        InitCommand=function(self)
            self:visible(false):zoomto(0, 0)
        end
    },

    Def.Sprite {
        Name="Mask",
        Texture="../../Phoenix/SG-MASKBAR.PNG",
        InitCommand=function(self)
            self:zoomto(MeterW, MeterH)
            :MaskSource()
        end
    },

    Def.Sprite {
        Name="Meter",
        Texture=isDouble and "../../Phoenix/SG-REALBARDOUBLE 1x3.png" or "../../Phoenix/SG-REALBARONE 1x3.png",
        InitCommand=function(self)
            self:animate(false)
            :setstate(pn == PLAYER_1 and 0 or 1)
            :zoomto(MeterW, MeterH)
            :cropright(0.5)
            :MaskDest():ztestmode("ZTestMode_WriteOnFail")
        end
    },

    Def.Sprite {
        Name="Pulse",
        Texture="../../Phoenix/SG-PULSE.png",
        InitCommand=function(self)
            self:visible(false)
        end
    },

	Def.Sprite {
        Name="ProMeter",
        Texture=isDouble and "../../Phoenix/SG-GLOWBARDOUBLEP 1x4.png" or "../../Phoenix/SG-GLOWBARONEP 1x4.png",
        InitCommand=function(self)
            self:animate(false)
            :setstate(pn == PLAYER_1 and 2 or 3)
            :zoomto(MeterW, MeterH)
            :cropright(1)
            :MaskDest():ztestmode("ZTestMode_WriteOnFail")
        end
    },

    Def.Sprite {
        Name="ProPulse",
        Texture="../../Phoenix/SG-PULSE.png",
        InitCommand=function(self)
            self:visible(false)
        end
    },

    Def.Sprite {
        Name="RainbowMeter",
        Texture=THEME:GetPathG("", "UI/RainbowBar"),
        InitCommand=function(self)
            self:zoomto(MeterW, MeterH)
            :texcoordvelocity(-0.5, 0)
            :diffusealpha(0)
            :MaskDest():ztestmode("ZTestMode_WriteOnFail")
        end
    },
	
    Def.Sprite {
        Name="Tip",
        Texture="../../Phoenix/SG-TIP 1x2.png",
        InitCommand=function(self)
            self:animate(false)
            :setstate(pn == PLAYER_1 and 0 or 1)
            :zoomto(30, 50)
            self:pulse():effectmagnitude(1.0,1.25,1.0):effectclock("bgm"):effecttiming(1,0,0,0)
        end
    },

    Def.Sprite {
        Name="Tip-Danger",
        Texture="../../Phoenix/SG-TIP 1x2.png",
        InitCommand=function(self)
            self:animate(false)
            :setstate(1) -- Red tip
			self:visible(0)
            :zoomto(30, 50)
            self:pulse():effectmagnitude(1.0,1.25,1.0):effectclock("bgm"):effecttiming(1,0,0,0)
		end
    },
	
    Def.Sprite {
        Name="Tip-Pro",
        Texture="../../Phoenix/SG-TIP 1x2.png",
        InitCommand=function(self)
            self:animate(false)
            :setstate(pn == PLAYER_1 and 0 or 1)
			self:visible(0)
            :zoomto(30, 50)
            self:pulse():effectmagnitude(1.0,1.25,1.0):effectclock("bgm"):effecttiming(1,0,0,0)
		end
    },

    Def.BitmapText{
        Font="Montserrat semibold 20px",
        InitCommand=function(self)
            self:x(BarW / 2 - 10):zoom(0.8):skewx(-0.2):halign(1)
            :diffuse(Color.Yellow):shadowlength(1):playcommand("Refresh")
        end,
        JudgmentMessageCommand=function(self, params)
            if pn == params.Player and ScoreDisplay == "Percent" then
                local PSS = STATSMAN:GetCurStageStats():GetPlayerStageStats(pn)
                local TotalAcc = PSS:GetCurrentPossibleDancePoints()
                local CurrentAcc = PSS:GetActualDancePoints()

                if TotalAcc ~= 0 then
                    self:settext(math.floor(CurrentAcc / TotalAcc * 10000) / 100 .. "%")
                else
                    self:settext("0%")
                end
            end
        end,
        UpdateScoreMessageCommand=function(self, params)
            if pn == params.Player and ScoreDisplay == "Score" then
                self:settext(((Scoring == "New" or Scoring == "Phoenix") and FormatScore(params.Score) or params.Score))
            end
        end
    }
}

if SongProgress then
    t[#t+1] = Def.ActorFrame {
        Def.SongMeterDisplay {
            InitCommand=function(self)
                self:SetStreamWidth(BarW - 12):y(-(BarH / 2) - 1)
            end,
            Stream=Def.Quad {
                InitCommand=function(self) self:zoomto(384, 2):diffuse(Color.Yellow) end
            }
        }
    }
end

return t
