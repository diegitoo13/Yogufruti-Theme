--[[
Part of the PMOD Project
Rebuilt and refactored by INTRMNS
Legacy hardcoded logic removed
2026_05
]]

local params = ...
local player = params.player;
local baseskin = params.baseskin;
local extraJudgment = params.extraJudgment;

local ShowComboAt = THEME:GetMetric("Combo", "ShowComboAt");


local judgeReverse = GAMESTATE:GetPlayerState(player):GetPlayerOptions('ModsLevel_Current'):JudgeReverse();

--frame correspondiente de cada judgment
local TNSframe = {
	TapNoteScore_CheckpointHit  = extraJudgment and 0 or 1,
	TapNoteScore_W1             = 0,
	TapNoteScore_W2             = 1,
	TapNoteScore_W3             = 2,
	TapNoteScore_W4             = 3,
	TapNoteScore_W5             = 4,
	TapNoteScore_Miss           = 5,
	TapNoteScore_CheckpointMiss = 5,
}

--frames para RG
local TNSframeReversed = {
	TapNoteScore_CheckpointHit	= 5,
	TapNoteScore_W1				= 5,
	TapNoteScore_W2				= 5,
	TapNoteScore_W3				= 4,
	TapNoteScore_W4				= 3,
	TapNoteScore_W5				= 2,
	TapNoteScore_Miss			= 1,
	TapNoteScore_CheckpointMiss	= 1,
}

local ynxmode = 0;
local zoomaux=0.5;
local auxvisible=false;

--########################################--
local t = Def.ActorFrame {};

t[#t+1] = Def.ActorFrame {
	--init
	InitCommand=function(self)
		local this = self:GetChildren()
		this.Judge:animate(false);
		this.combo:vertalign(top);
		
		this.Judge:visible(false);
		this.combo:visible(false);
		this.label:visible(false);
	end;
	--parche
	OnCommand=function(self)
		self:sleep(1):queuecommand("MakeVisible");
	end;
	MakeVisibleCommand=function(self)
		auxvisible=true;
	end;

	
	--judges
	LoadActor("JudgeLabel") .. {	Name="Judge";	
		InitCommand=function(self)
			if GAMESTATE:GetPlayerState(player):GetPlayerOptions('ModsLevel_Preferred' ):NXMode() then				
				ynxmode=-50;
				if GAMESTATE:GetPlayerState(player):GetPlayerOptions('ModsLevel_Preferred' ):Drop() then
					ynxmode=140;
				end;
			else
				ynxmode=60;
			end;
			self:diffusealpha(0):y(-64+ynxmode):zoom(.75);
		end;
		NormalCommand=function(self)
			self:diffusealpha(1);
			self:zoom(.75);
			self:y(-64+ynxmode);
			self:linear(.1);
			self:zoom(0.5);
			self:y(-53+ynxmode);
			self:linear(.3);
			self:diffusealpha(0.8);
			self:sleep(0);
			self:linear(0.3);
			self:diffusealpha(0);
			self:zoomx(1);
			self:zoomy(0);
		end;
	};
		
	--label
	LoadActor("ComboLabel") .. {	Name="label";
		InitCommand=function(self)
			if GAMESTATE:GetPlayerState(player):GetPlayerOptions('ModsLevel_Preferred' ):NXMode() then				
				ynxmode=-50;
				if GAMESTATE:GetPlayerState(player):GetPlayerOptions('ModsLevel_Preferred' ):Drop() then
					ynxmode=140;
				end;
			else
				ynxmode=60;
			end;
			self:diffusealpha(0):y(-25+ynxmode):zoom(.75);
		end;
		NormalCommand=function(self)
			self:diffusealpha(1);
			self:zoom(.75);
			self:y(-25+ynxmode);
			self:linear(.1);
			self:zoom(0.5);
			self:y(-26+ynxmode);
			self:linear(.3);
			self:diffusealpha(0.8);
			self:sleep(0);
			self:linear(0.3);
			self:diffusealpha(0);
			self:zoomx(1);
			self:zoomy(0);
		end;		
	};
	
	--combo
	Def.BitmapText {
		File = "Combo numbers.ini";
		Name= "combo";
		InitCommand=function(self)
			if GAMESTATE:GetPlayerState(player):GetPlayerOptions('ModsLevel_Preferred' ):NXMode() then				
				ynxmode=-50;
				if GAMESTATE:GetPlayerState(player):GetPlayerOptions('ModsLevel_Preferred' ):Drop() then
					ynxmode=140;
				end;
			else
				ynxmode=55;
			end;
			self:diffusealpha(0):y(ynxmode):zoom(1.4*zoomaux);
		end;
		NormalCommand=function(self)
			self:diffusealpha(1);
			self:zoom(.74);
			self:y(-5+ynxmode);
			self:linear(.1);
			self:zoom(0.7);
			self:y(-17+ynxmode);
			self:linear(.3);
			self:diffusealpha(0.8);
			self:linear(0.3);
			self:diffusealpha(0);
		end;		
	};
	
	--"PERFECT"!
	JudgmentMessageCommand=function(self,param)
		local this = self:GetChildren()
		local iTns = TNSframe[param.TapNoteScore]
		
		if judgeReverse then
			iTns = TNSframeReversed[param.TapNoteScore]
		end
		--no player, no job
		if param.Player ~= player then return end
		if param.HoldNoteScore then return end
		if not iTns then return end
		if not auxvisible then return end
		
		this.Judge:visible(true);
		this.Judge:stoptweening();
		this.Judge:setstate(iTns);
		this.Judge:queuecommand("Normal");
		
	end;

	ComboCommand=function(self,param)
		local this = self:GetChildren()
		local combo = param.Misses or param.Combo;
		
		-- Congruencia con métricas
		if not combo or combo < ShowComboAt or not auxvisible then
			this.combo:visible(false);
			this.label:visible(false);
			return;
		end;
		
		-- Lógica de color simplificada
		local isMiss = param.Misses ~= nil
		local ccolor = (isMiss ~= judgeReverse) and color("1,0.1,0.1,1") or color("1,1,1,1")
		
		-- Aplicación uniforme
		for _, obj in pairs({this.combo, this.label}) do
			obj:visible(true);
			obj:stoptweening();
			obj:diffuse(ccolor);
			if obj.settextf then obj:settextf("%03i", combo) end
			obj:queuecommand("Normal");
		end
	end;
};

return t;

--[[
Part of the PMOD Project
Rebuilt and refactored by INTRMNS
Legacy hardcoded logic removed
2026_05
]]