-- SKIN00 - PNIRU JUDGMENT
local params = ...
local player = params.player;
local zoomskin = params.zoomskin;
local baseskin = params.baseskin;
local extraJudgment = params.extraJudgment;

local ShowComboAt = THEME:GetMetric("Combo", "ShowComboAt");
local isReverse = GAMESTATE:GetPlayerState(player):GetPlayerOptions("ModsLevel_Current"):JudgeReverse();
local auxvisible=false;
local JudgeEarly = false;
local PniruState = false;

local TNSframe = {
	TapNoteScore_CheckpointHit = 1;
	TapNoteScore_W1 = 0;
	TapNoteScore_W2 = 1;
	TapNoteScore_W3 = 2;
	TapNoteScore_W4 = 3;
	TapNoteScore_W5 = 4;
	TapNoteScore_Miss = 5;
	TapNoteScore_CheckpointMiss = 5;
};
local TNSframeReversed = {
	TapNoteScore_CheckpointHit = 5;
	TapNoteScore_W1 = 5;
	TapNoteScore_W2 = 5;
	TapNoteScore_W3 = 4;
	TapNoteScore_W4 = 3;
	TapNoteScore_W5 = 2;
	TapNoteScore_Miss = 1;
	TapNoteScore_CheckpointMiss = 1;
};

local JudgeAnimations = {
	W1 = cmd(stoptweening;zoom,0.54;y,-13;diffusealpha,1;
		decelerate,0.12;zoom,0.58;y,-15;
		accelerate,0.12;zoom,0.54;y,-13;
		sleep,0.9;
		accelerate,0.5;y,-14;diffusealpha,0;zoomy,0.50;zoomx,0.72;
	);
	PniruW1 = cmd(stoptweening;zoom,0.54;y,-13;diffusealpha,1;
		decelerate,0.14;zoom,0.60;y,-16;
		accelerate,0.12;zoom,0.55;y,-13;
		sleep,0.9;
		accelerate,0.5;y,-14;diffusealpha,0;zoomy,0.50;zoomx,0.80;
	);
	W3 = cmd(stoptweening;zoom,0.53;y,-13;diffusealpha,1;
		decelerate,0.10;zoom,0.56;y,-14;
		accelerate,0.12;zoom,0.53;y,-13;
		sleep,0.8;
		accelerate,0.5;diffusealpha,0;zoom,0.50;y,-12;
	);
	W4 = cmd(stoptweening;zoom,0.52;y,-13;x,0;diffusealpha,1;
		decelerate,0.1;x,-3;zoom,0.54;
		accelerate,0.1;x,3;zoom,0.53;
		sleep,0.2;
		linear,0.06;x,-2;
		linear,0.06;x,2;
		linear,0.06;x,0;
		sleep,0.6;
		accelerate,0.4;x,4;diffusealpha,0;zoom,0.50
	);
	W5 = cmd(stoptweening;zoom,0.52;y,-13;diffusealpha,1;
		decelerate,0.12;y,-12;zoom,0.54;
		sleep,0.8;
		accelerate,0.5;y,-9;diffusealpha,0;zoom,0.50;
	);

	Miss = cmd(stoptweening;zoom,0.50;y,-13;diffusealpha,1;
		decelerate,0.12;y,-12;zoom,0.53;
		sleep,0.7;
		accelerate,0.5;y,-9;diffusealpha,0;zoom,0.48;
	);
	PniruMiss = cmd(stoptweening;zoom,0.50;y,-13;diffusealpha,1;
		decelerate,0.15;y,-14;zoom,0.55;
		accelerate,0.10;y,-13;zoom,0.52;
		sleep,0.3;
		linear,0.05;y,-12;
		linear,0.05;y,-14;
		sleep,0.5;
		accelerate,0.45;y,-8;diffusealpha,0;zoom,0.48
	);
	-- CheckpointHit: discreto, sin flashes
	CheckpointHit = cmd(stoptweening;zoom,0.52;y,-13;diffusealpha,1;
		decelerate,0.08;zoom,0.54;
		sleep,0.25;
		linear,0.05;y,-12;
		linear,0.05;y,-13;
		sleep,0.25;
		accelerate,0.4;diffusealpha,0;zoom,0.50
	);
};


local ComboLabelAnimations = {
	-- Combo normal: sutil rebote vertical y salida limpia
	NormalCombo = cmd(stoptweening;zoom,0.33;y,0;diffusealpha,1;
		decelerate,0.10;zoom,0.36;y,-2;
		accelerate,0.10;zoom,0.33;y,0;
		sleep,0.8;
		accelerate,0.4;diffusealpha,0;zoomy,0.30;zoomx,0.28;
	);
	-- Combo puniru: doble pulso con compresión discreta
	PniruCombo = cmd(stoptweening;zoom,0.33;y,0;diffusealpha,1;
		decelerate,0.12;zoom,0.38;y,1;
		accelerate,0.10;zoom,0.33;y,0;
		sleep,0.3;
		linear,0.05;zoom,0.35;y,2;
		linear,0.05;zoom,0.33;y,0;
		sleep,0.6;
		accelerate,0.4;diffusealpha,0;zoomy,0.30;zoomx,0.28;
	);
	-- Miss Combo: caída amortiguada con ligera compresión
	MissCombo = cmd(stoptweening;zoom,0.33;y,0;diffusealpha,1;
		decelerate,0.10;y,2;zoom,0.35;
		sleep,0.7;
		accelerate,0.3;y,5;zoom,0.32;
		accelerate,0.4;y,8;diffusealpha,0;zoom,0.30;
	);
	-- Pniru Break: caída dramática, pero controlada
	PniruBreak = cmd(stoptweening;zoom,0.33;y,0;diffusealpha,1;
		decelerate,0.12;y,1;zoom,0.37;
		accelerate,0.10;y,0;zoom,0.33;
		sleep,0.3;
		linear,0.05;y,2;zoom,0.35;
		linear,0.05;y,0;zoom,0.33;
		sleep,0.5;
		accelerate,0.45;y,6;diffusealpha,0;zoom,0.30;
	);
	-- Checkpoint Pulse: pulso corto y limpio
	CheckpointPulse = cmd(stoptweening;zoom,0.33;y,0;diffusealpha,1;
		decelerate,0.08;zoom,0.35;
		sleep,0.25;
		linear,0.05;zoom,0.34;
		sleep,0.25;
		accelerate,0.4;diffusealpha,0;zoom,0.30;
	);
};

local ComboNumberAnimations = {
	-- Normal Combo Number: rebote controlado, salida limpia
	NormalCombo = cmd(stoptweening;zoom,0.54;y,18;diffusealpha,1;
		decelerate,0.10;zoom,0.57;y,17;
		accelerate,0.10;zoom,0.54;y,18;
		sleep,0.8;
		accelerate,0.4;diffusealpha,0;zoomy,0.50;zoomx,0.48;
	);
	-- Pniru Combo Number: pulso suave, compresión ligera hacia abajo
	PniruCombo = cmd(stoptweening;zoom,0.54;y,18;diffusealpha,1;
		decelerate,0.12;zoom,0.58;y,19;
		accelerate,0.10;zoom,0.54;y,18;
		sleep,0.3;
		linear,0.05;zoom,0.56;y,19;
		linear,0.05;zoom,0.54;y,18;
		sleep,0.6;
		accelerate,0.4;diffusealpha,0;zoomy,0.50;zoomx,0.48;
	);
	-- Miss Combo Number: descenso suave y desaparición amortiguada
	MissCombo = cmd(stoptweening;zoom,0.54;y,18;diffusealpha,1;
		decelerate,0.10;y,20;zoom,0.56;
		sleep,0.7;
		accelerate,0.3;y,23;zoom,0.52;
		accelerate,0.4;y,25;diffusealpha,0;zoom,0.50;
	);
	-- Pniru Break: rebote corto seguido de caída
	PniruBreak = cmd(stoptweening;zoom,0.54;y,18;diffusealpha,1;
		decelerate,0.12;y,19;zoom,0.57;
		accelerate,0.10;y,18;zoom,0.54;
		sleep,0.3;
		linear,0.05;y,19;zoom,0.55;
		linear,0.05;y,18;zoom,0.54;
		sleep,0.5;
		accelerate,0.45;y,24;diffusealpha,0;zoom,0.50;
	);
	-- Checkpoint Pulse: parpadeo sutil sin desplazamiento
	CheckpointPulse = cmd(stoptweening;zoom,0.54;y,18;diffusealpha,1;
		decelerate,0.08;zoom,0.56;
		sleep,0.25;
		linear,0.05;zoom,0.55;
		sleep,0.25;
		accelerate,0.4;diffusealpha,0;zoom,0.50;
	);
};


local t = Def.ActorFrame { };

t[#t+1] =  Def.ActorFrame {	--MainFrame (vacio intencional)
	Def.ActorFrame {
		InitCommand=cmd(y,30;diffusealpha,0.96;);
		LoadActor("JudgeLabel") .. {	Name="Judge";	
			InitCommand=cmd(animate,false;setstate,0;zoom,.54;y,-13;vertalign,bottom;);
		};
		LoadActor("ComboLabel") .. {	Name="Combo";
			InitCommand=cmd(animate,false;setstate,1;zoom,1/3;y,0-2;);
		};
		Def.BitmapText { File = "Kinn/Kinn black ComboPniru 60px.ini";
			Name="NumberPniru";
			InitCommand=cmd(zoom,.54;y,18-2;vertalign,top;diffusealpha,0;);
		};
		Def.BitmapText { File = "Kinn/Kinn black ComboMiss 60px.ini";
		Name="NumberMiss";
			InitCommand=cmd(zoom,.54;y,18-2;vertalign,top;diffusealpha,0;);
		};
		Def.BitmapText { File = "Kinn/Kinn black ComboNormal 60px.ini";
		Name="NumberNormal";
			InitCommand=cmd(zoom,.54;y,18-2;vertalign,top;diffusealpha,0;);
		};
		MakeVisibleCommand=function()
			auxvisible=true;
		end;
		ScreenChangedMessageCommand=function()
			auxvisible=false;
		end;
		OnCommand=function(self)
			auxvisible=false;
			self:GetChild("Judge"):diffusealpha(0);
			self:GetChild("Combo"):diffusealpha(0);
			self:GetChild("NumberPniru"):diffusealpha(0);
			self:GetChild("NumberMiss"):diffusealpha(0);
			self:GetChild("NumberNormal"):diffusealpha(0);
			self:sleep(1):queuecommand("MakeVisible");
			
		end;
		JudgmentMessageCommand=function(self,param)
			if not auxvisible then return end;
			if param.Player ~= player or not param.TapNoteScore then return end;
			
			local iFrame = (isReverse and TNSframeReversed[param.TapNoteScore]) or TNSframe[param.TapNoteScore]
				if not iFrame then return end

			local this = self:GetChildren();	
				this.Judge:setstate(iFrame);
			
		-- logica de animaciones
			local tns = ToEnumShortString(param.TapNoteScore);
			if tns == "W1" or tns == "W2" then	
				if PniruState then
					JudgeAnimations.PniruW1(this.Judge);
				else
					JudgeAnimations.W1(this.Judge);
				end;
			elseif tns == "Miss" or tns == "CheckpointMiss" then
				if PniruState then
					JudgeAnimations.PniruMiss(this.Judge);
				else
					JudgeAnimations.Miss(this.Judge);
				end;
			else
				local vcmd = JudgeAnimations[tns];
				if vcmd then
					JudgeAnimations[tns](this.Judge);
				end;
			end;
		end;
		ComboCommand=function(self,param)
			local this = self:GetChildren();
			local comboVal = param.Misses or param.Combo;
			local misses = tonumber(param.Misses or 0);
			local hasMiss = (misses > 0);
			
			if not comboVal or comboVal < ShowComboAt then
				this.Combo:visible(false);
				this.NumberPniru:visible(false);
				this.NumberMiss:visible(false);
				this.NumberNormal:visible(false);
				return;
			end;
			
			local comboState = 1;
			if isReverse then
				comboState = param.Misses and 1 or 2;
			else
				if comboVal >= 1000 then
					PniruState = param.Misses and false or true;
					comboState = 0;
				elseif hasMiss then
					if PniruState then
						PniruState = false;
					end;
					comboState = 2;
				else
					comboState = 1;
				end;
			end;
				this.Combo:visible(true):setstate(comboState):diffusealpha(1);
			
			local showPniru  = (not isReverse) and comboVal >= 1000;
			local showMiss   = (isReverse and not hasMiss) or (not isReverse and hasMiss);
			local showNormal = (isReverse and hasMiss) or (not isReverse and not hasMiss and comboVal < 1000)
				
			local comboType
				if param.Misses then
					comboType = PniruState and "PniruBreak" or "MissCombo"
				elseif param.CheckpointHit then
					comboType = "CheckpointPulse"
				else
					comboType = PniruState and "PniruCombo" or "NormalCombo"
				end

			ComboLabelAnimations[comboType](this.Combo);
				if showPniru then
					this.NumberPniru:visible(true):settextf("%02i",comboVal);
					this.NumberMiss:visible(false);
					this.NumberNormal:visible(false);
					ComboNumberAnimations[comboType](this.NumberPniru);
				elseif showMiss then
					this.NumberMiss:visible(true):settextf("%02i",comboVal);
					this.NumberPniru:visible(false);
					this.NumberNormal:visible(false);
					ComboNumberAnimations[comboType](this.NumberMiss);
				else
					this.NumberNormal:visible(true):settextf("%02i",comboVal);
					this.NumberPniru:visible(false);
					this.NumberMiss:visible(false);
					ComboNumberAnimations[comboType](this.NumberNormal);
				end;
		end;
	};
};

return t;

--[[
Part of the PMOD Project
External skin module (Puniru)
Original implementation by INTRMNS
Created for the PMOD theme architecture
2026_03
]]