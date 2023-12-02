--//MODCHART UTILS//--

local rep=game:GetService('ReplicatedStorage')
local runServ=game:GetService('RunService')

local modules=rep.Modules

local Conductor=require(modules.Conductor)
local Note=require(modules.Note)
local Receptor=require(modules.Receptor)
local utils=require(script.Parent.ScriptUtil)
local timer=0;
local usingZoroTemplate=true --//ENABLE THIS TO USE Z AXIS AND ZORO NOTE MOVEMENT

local sustainSpeed=0.1

local downscroll=Conductor.Downscroll
local middlescroll=false
local strumLineY=downscroll and 620 or 120
local legacyPsychMode=false
local keyCount=4
local songPosition=0
local screenHeight=720
local arrowSize=0.7
local songSpeed=1

local assets=script.Parent.assets

local beatPoop=false

local curBeat=0

local FlxMath={
	roundDecimal=function(x,y)
		local mult = 10^(y or 0)
		return math.floor(x * mult + 0.5) / mult
	end;
	fastSin=function(x)
		return math.sin(x)
	end,
};

--//TEMPLATE THINGS//--

local template={}

template.ready=false;
template.strumLine={};
template.settings=nil;
template.ForcedMiddleScroll=false;

function template.pos(daNote,rawX,rawY,playerStrums,dadStrums)
	local baseYVal = 0;
	local baseXVal = 0;
	local baseZVal=(template.getProperty('laneZ')+daNote.Z)/10

	if(daNote.MustPress)then
		baseYVal = (playerStrums[daNote.NoteData+1].yWithOffset)
		baseXVal = (playerStrums[daNote.NoteData+1].xWithOffset)
	else
		baseYVal = (dadStrums[daNote.NoteData+1].yWithOffset)
		baseXVal = (dadStrums[daNote.NoteData+1].xWithOffset)
	end

	daNote.Y=baseYVal+((daNote.InitialPos-Conductor.CurrentTrackPos)*(Conductor.Downscroll and -1 or 1)*(1+template.getProperty('reverse.y')*-2))

	if not daNote.IsSustain then
		daNote.X=rawX+baseZVal
	else
		daNote.X=template.lerp(daNote.X,rawX+baseZVal,sustainSpeed/((daNote.susPos or 2)/2))
	end
end


function template.NoteModifiers(daNote)
	
	local xOffset=0;
	local yOffset=0;
	local zOffset=0;
	
	if template.getProperty('ZigZag.x')~=0 then
		xOffset +=  math.sin((Conductor.songPosition - daNote.StrumTime) / 50) * template.getProperty('ZigZag.x');
		if daNote.IsSustain then
			daNote.NoteObject.Rotation=math.sin((Conductor.songPosition - daNote.StrumTime) / 50) * template.getProperty('ZigZag.x');
		end
	end
	if template.getProperty('ZigZag.z')~=0 then
		zOffset +=  math.sin((Conductor.songPosition - daNote.StrumTime) / 50) * template.getProperty('ZigZag.z');
	end
	if template.getProperty('ZigZag.angle')~=0 then
		daNote.NoteObject.Rotation=math.sin((Conductor.songPosition - daNote.StrumTime) / 50) * template.getProperty('ZigZag.angle');
	end
	if template.getProperty('DrunkNote.x')~=0 then
		xOffset +=  template.getProperty('DrunkNote.x') * (math.cos( ((songPosition*0.001) + ((template.GetData(daNote)%keyCount)*0.2) + (template.strumLine[template.GetData(daNote)].X*0.45)*(10/screenHeight)) * (template.getProperty('DrunkNote.x')*0.2)) * arrowSize*0.5);
	end
	if template.getProperty('DrunkNote.z')~=0 then
		zOffset +=  template.getProperty('DrunkNote.z') * (math.cos( ((songPosition*0.001) + ((template.GetData(daNote)%keyCount)*0.2) + (template.strumLine[template.GetData(daNote)].X*0.45)*(10/screenHeight)) * (template.getProperty('DrunkNote.z')*0.2)) * arrowSize*0.5);
	end
	if template.getProperty('IncomingAngle.curve.z')~=0 then
		zOffset -=  math.sin((Conductor.songPosition - daNote.StrumTime) / Conductor.BPM) * template.getProperty('IncomingAngle.curve.z');
	end
	if template.getProperty('IncomingAngle.curve.x')~=0 then
		xOffset -=  math.sin((Conductor.songPosition - daNote.StrumTime) / Conductor.BPM) * template.getProperty('IncomingAngle.curve.x');
	end
	if template.getProperty('IncomingAngle.smooth')~=0 then
		if Conductor.Downscroll then
			if Conductor.songPosition >= daNote.StrumTime then
				daNote.Y = (daNote.ReceptorTarget.yWithOffset or daNote.ReceptorTarget.Y) + (Conductor.songPosition - daNote.StrumTime) * (0.45 * FlxMath.roundDecimal(shared.songData.speed, 2))
			else
				daNote.Y = (daNote.ReceptorTarget.yWithOffset or daNote.ReceptorTarget.Y) - (0.9 * (Conductor.songPosition - daNote.StrumTime) * (Conductor.songPosition - daNote.StrumTime) / 1000)
			end
		else
			if Conductor.songPosition >= daNote.StrumTime then
				daNote.Y = (daNote.ReceptorTarget.yWithOffset or daNote.ReceptorTarget.Y) - (Conductor.songPosition - daNote.StrumTime) * (0.45 * FlxMath.roundDecimal(shared.songData.speed, 2))
			else
				daNote.Y = (daNote.ReceptorTarget.yWithOffset or daNote.ReceptorTarget.Y) + (0.9 * (Conductor.songPosition - daNote.StrumTime) * (Conductor.songPosition - daNote.StrumTime) / 1000)
			end
		end
	end

	xOffset+=template.getProperty('noteOffset'..template.GetData(daNote)..'.x')*(Conductor.songPosition - daNote.StrumTime) / 100
	yOffset+=template.getProperty('noteOffset'..template.GetData(daNote)..'.y')*(Conductor.songPosition - daNote.StrumTime) / 100
	zOffset+=template.getProperty('noteOffset'..template.GetData(daNote)..'.z')*(Conductor.songPosition - daNote.StrumTime) / 100
	
	daNote.X+=xOffset
	daNote.Y+=yOffset
	daNote.Z+=zOffset
end


function template.onBeatHit(currBeat)
	curBeat=currBeat
	beatPoop=not beatPoop
	if template.getProperty('beat')~=0 then
		for i=0,7 do
			local data=template.GetData(template.strumLine[i]);
			local daOffset=0;

			if beatPoop then
				daOffset+=template.getProperty('beat')
			else
				daOffset-=template.getProperty('beat')
			end
			template.setProperty('strumOffset3'..data..'.x',daOffset)
			template.tweenProperty('strumOffset3'..data..'.x',0,0.5,'cubeOut')
		end
	end
end

template.Strum3dLine={}

function template.onStart()
	for i=0,7 do
		template.strumLine[i].GUI.ScaleType=Enum.ScaleType.Stretch
		template.strumLine[i].Alpha=0
		template.strumLine[i].ChangeSize=false
		local Note3d=assets.Note3d:Clone()
		Note3d.Parent=template.strumLine[i].GUI
		Note3d.Size=UDim2.fromScale(1,1)
		Note3d.AnchorPoint=Vector2.new(.5,.5)
		Note3d.Position=UDim2.fromScale(.5,.5)
		template.Strum3dLine[i]=Note3d
	end
	template.Note3dXML=require(script.Parent.assets.Note3d.XML)
	middlescroll=template.settings.MiddleScroll or false
end

--//RECEPTOR FUNCTIONS//--

function Receptor:vibrate(mag)
	local curMag=mag;
	local curAcc=(mag*2)/100;
	local data=template.GetData(self);

	template.DisconnectRS(self,'vibrateService')

	self.vibrateService=runServ.RenderStepped:Connect(function(elapsed)
		template.setProperty('strumOffset3'..data..'.y',math.sin(elapsed*1000) * curMag * (data%2==0 and 2 or -2))
		curMag-=curAcc
		if curMag<=0 or curMag>mag then
			template.setProperty('strumOffset3'..data..'.y',0)
			template.DisconnectRS(self,'vibrateService')
		end
	end);
end

function Receptor:TweenX(value:Dynamic, duration:Float, ease:String)
	utils.numberTween(self,value,duration,ease,'X')
end

function Receptor:TweenY(value:Dynamic, duration:Float, ease:String)
	utils.numberTween(self,value,duration,ease,'Y')
end

function Receptor:TweenZ(value:Dynamic, duration:Float, ease:String)
	utils.numberTween(self,value,duration,ease,'Z')
end

function Receptor:SetOffset(value:Dynamic, Sufix:String)
	local data=template.GetData(self);
	template.setProperty('strumOffset'..data..'.'..Sufix,value)
end

function Receptor:Jump(Sufix:String, value:Dynamic, Acceleration:Dynamic)
	local data=template.GetData(self);
	local vel=value
	local rightSufix=string.lower(Sufix)

	template.DisconnectRS(self,'jumpService')
	template.setProperty('strumOffset2'..data..rightSufix,0)

	self.jumpService=runServ.RenderStepped:Connect(function()
		template.setProperty('strumOffset2'..data..rightSufix,template.getProperty('strumOffset2'..data..rightSufix)-vel)
		vel-=Acceleration
		if vel<=-value then
			template.setProperty('strumOffset2'..data..rightSufix,0)
			template.DisconnectRS(self,'jumpService')
		end
	end)
end

function Receptor:TweenSize(value:Dynamic, duration:Float, ease:String, Sufix:String)
	local data=template.GetData(self);
	local rightSufix=string.upper(Sufix)
	utils.numberTween(self,value/100,duration,ease,'scaleOffset'..rightSufix)
end

function Receptor:SetSize(value:Dynamic, Sufix:String)
	local data=template.GetData(self);
	local rightSufix=string.upper(Sufix)
	self['scaleOffset'..rightSufix]=value/100
end


--//UNUSED//--

local useNotePaths=0
local pathCount=0
local pathSize=0

local currentXOffset=0
local currentYOffset=0
local currentZOffset=0
local currentAlphaOffset=0
local currentAngleOffset=0

local allowCrossScriptModifiers=false

function template.makeGraphic()end
function template.setObjectCamera()end
function template.addLuaSprite()end
function template.runHaxeCode()end
function template.getSuddenStartLine()end
function template.getSuddenEndLine()end
function template.getHiddenEndLine()end
function template.getHiddenStartLine()end
function template.tweenAngle()end
function template.tweenFadeIn()end
function template.addPlayfield()end

--//VARS//--

local mods={
	tipsy=0;
	drunk=0;
	tipsySpeed=1;
	drunkSpeed=1;
	incomingAngle={0,0};
	playerIncomingAngle={0,0};
	opponentIncomingAngle={0,0};
}

local noteRotX = 0
local targetNoteRotX = 0

local defaultSusScaleY = -1 --store scaley for all sustains
local defaultSusEndScaleY = -1
local scrollSwitch = 52 --height to move to when reverse
local rad = math.pi/180;


--//FUNCTIONS//--

function template.DisconnectRS(obj,servName)
	if obj[servName] then
		obj[servName]:Disconnect()
		obj[servName]=nil
	end
end

function template.GetData(obj)
	return obj.NoteData;
end

function template.makeLuaSprite(name,xy,value1,value2)
	mods[name]=0
	mods[name..'.alpha']=0
	mods[name..'.angle']=0
	mods[name..'.x']=value1
	mods[name..'.y']=value2
end

function template.setProperty(property,value)
	mods[property]=value or 0
end

function template.tweenProperty(property:String, value:Dynamic, duration:Float, ease:String)
	utils.numberTween(mods,value or 0,duration,ease,property)
end

function template.getProperty(property,value)
	return mods[property] or 0
end

function template.setupModifiers()
	for i = 0,(keyCount*2)-1 do 
		template.makeLuaSprite('strumOffset'..i, '', 0, 0)
		template.makeLuaSprite('strumOffset2'..i, '', 0, 0)
		template.makeLuaSprite('scaleMulti'..i, '', 1, 1)
		template.makeLuaSprite('reverse'..i, '', 0, 0)
		template.makeLuaSprite('confusion'..i, '', 0, 0)


		template.makeLuaSprite('incomingAngle'..i, '', 0, 0)
		template.makeLuaSprite('noteRot'..i, '', 0, 0)

		template.makeLuaSprite('noteOffset'..i, '', 0, 0)

		if useNotePaths then 
			for j = 0,pathCount do 
				template.makeLuaSprite(i..'NotePath'..j, '', -500, 0)
				template.makeGraphic(i..'NotePath'..j, 15, pathSize, '0xFFFFFFFF')
				template.setObjectCamera(i..'NotePath'..j, 'hud')
				template.setProperty(i..'NotePath'..j..'.alpha', 0)
				template.addLuaSprite(i..'NotePath'..j, false)
			end
		end

	end

	template.makeLuaSprite('globalStrumOffset', '', 0, 0) --general x,y,z movement
	template.makeLuaSprite('playerStrumOffset', '', 0, 0)
	template.makeLuaSprite('opponentStrumOffset', '', 0, 0)

	template.makeLuaSprite('incomingAngle', '', 0, 0) --angle that notes come at (x,y)
	template.makeLuaSprite('playerIncomingAngle', '', 0, 0)
	template.makeLuaSprite('opponentIncomingAngle', '', 0, 0)

	template.makeLuaSprite('noteRot', '', 0, 0) --spins strums around the center of the screen (x,y)
	template.makeLuaSprite('playerNoteRot', '', 0, 0) --changing y also changes incoming angle to match
	template.makeLuaSprite('opponentNoteRot', '', 0, 0)

	template.makeLuaSprite('screenRot', '', 0, 0) --spins screen using a raymarcher shader (x,y)

	template.makeLuaSprite('brake', '', 0, 0) --slows notes down near strumline (y)
	template.makeLuaSprite('playerBrake', '', 0, 0)
	template.makeLuaSprite('opponentBrake', '', 0, 0)

	template.makeLuaSprite('boost', '', 0, 0) --speeds up notes down near strumline (y)
	template.makeLuaSprite('playerBoost', '', 0, 0)
	template.makeLuaSprite('opponentBoost', '', 0, 0)

	template.makeLuaSprite('speed', '', 1, 1)

	template.makeLuaSprite('twist', '', 0, 0) --noteRot but changes for notes as they move, y on low value is pretty cool

	--using lua sprites so you can tween lol
	--changing angle changes the z, not actual angle, to change note angle use confusion
	template.makeLuaSprite('tipsy', '', 0, 0) 
	template.makeLuaSprite('drunk', '', 0, 0)
	template.makeLuaSprite('tipsySpeed', '', 1, 1)
	template.makeLuaSprite('drunkSpeed', '', 1, 1)


	template.makeLuaSprite('playerNotePathAlpha', '', 0, 0)
	template.setProperty('playerNotePathAlpha.alpha', 0)
	template.makeLuaSprite('opponentNotePathAlpha', '', 0, 0)
	template.setProperty('opponentNotePathAlpha.alpha', 0)

	template.makeLuaSprite('dark', '', 0, 0) --strum alpha
	template.makeLuaSprite('stealth', '', 0, 0) --note alpha
	template.setProperty('dark.alpha', 0)
	template.setProperty('stealth.alpha', 0)

	template.makeLuaSprite('sudden', '', 0, 0)
	template.makeLuaSprite('hidden', '', 0, 0)
	template.setProperty('sudden.alpha', 0)
	template.setProperty('hidden.alpha', 0)

	template.makeLuaSprite('noteOffset', '', 0, 0)
	template.makeLuaSprite('playerNoteOffset', '', 0, 0)
	template.makeLuaSprite('opponentNoteOffset', '', 0, 0)

	--setProperty('hidden.y', -0.7)



	template.makeLuaSprite('scale', '', 0.7, 0.7) --0.7 = default scale
	template.makeLuaSprite('confusion', '', 0, 0) --angle

	template.makeLuaSprite('reverse', '', 0, 0) --only y does stuff

	template.makeLuaSprite('waveShit', '', 0,0)


	if not legacyPsychMode then --for cross script stuff
		template.runHaxeCode([[
			game.setOnLuas("currentXOffset", 0);
			game.setOnLuas("currentYOffset", 0);
			game.setOnLuas("currentZOffset", 0);
			game.setOnLuas("currentAngleOffset", 0);
			game.setOnLuas("currentAlphaOffset", 1);
		]])
	end
end

function template.runModifiers(data, curPos,x,y)
	--this is where mod math template.gets applied to strums/notes
	local xOffset = 0
	local yOffset = 0
	local zOffset = 0
	local angle = 0
	local alpha = 1

	xOffset = xOffset + template.getProperty('strumOffset'..data..'.x') --add strum offsets
	yOffset = yOffset + template.getProperty('strumOffset'..data..'.y')
	zOffset = zOffset + template.getProperty('strumOffset'..data..'.angle') --using angle because

	xOffset = xOffset + template.getProperty('strumOffset2'..data..'.x') --add strum offsets
	yOffset = yOffset + template.getProperty('strumOffset2'..data..'.y')
	zOffset = zOffset + template.getProperty('strumOffset2'..data..'.angle') --using angle because

	xOffset = xOffset + template.getProperty('strumOffset3'..data..'.x') --add strum offsets
	yOffset = yOffset + template.getProperty('strumOffset3'..data..'.y')
	zOffset = zOffset + template.getProperty('strumOffset3'..data..'.angle') --using angle because

	xOffset = xOffset + template.getProperty('strumOffset4'..data..'.x') --add strum offsets
	yOffset = yOffset + template.getProperty('strumOffset4'..data..'.y')
	zOffset = zOffset + template.getProperty('strumOffset4'..data..'.angle') --using angle because

	xOffset = xOffset + template.getProperty('globalStrumOffset.x') --add strum offsets
	yOffset = yOffset + template.getProperty('globalStrumOffset.y')
	zOffset = zOffset + template.getProperty('globalStrumOffset.angle')

	if data < keyCount then 
		xOffset = xOffset + template.getProperty('opponentStrumOffset.x') --add strum offsets
		yOffset = yOffset + template.getProperty('opponentStrumOffset.y')
		zOffset = zOffset + template.getProperty('opponentStrumOffset.angle')
		alpha = alpha*template.getProperty('opponentStrumOffset.alpha')
		if curPos ~= 0 then 
			xOffset = xOffset + template.getProperty('opponentNoteOffset.x') --add note offsets
			yOffset = yOffset + template.getProperty('opponentNoteOffset.y')
			zOffset = zOffset + template.getProperty('opponentNoteOffset.angle')
		end
	else 
		xOffset = xOffset + template.getProperty('playerStrumOffset.x') --add strum offsets
		yOffset = yOffset + template.getProperty('playerStrumOffset.y')
		zOffset = zOffset + template.getProperty('playerStrumOffset.angle')
		alpha = alpha*template.getProperty('playerStrumOffset.alpha')
		if curPos ~= 0 then 
			xOffset = xOffset + template.getProperty('playerNoteOffset.x') --add note offsets
			yOffset = yOffset + template.getProperty('playerNoteOffset.y')
			zOffset = zOffset + template.getProperty('playerNoteOffset.angle')
		end
	end

	--drunk


	if template.getProperty('drunk.x') ~= 0 then 
		xOffset = xOffset + template.getProperty('drunk.x') * (math.cos( ((songPosition*0.001) + ((data%keyCount)*0.2) + (template.strumLine[data].X*0.45)*(10/screenHeight)) * (template.getProperty('drunkSpeed.x')*0.2)) * arrowSize*0.5);
	end
	if template.getProperty('drunk.y') ~= 0 then 
		yOffset = yOffset + template.getProperty('drunk.y') * (math.cos( ((songPosition*0.001) + ((data%keyCount)*0.2) + (template.strumLine[data].Y*0.45)*(10/screenHeight)) * (template.getProperty('drunkSpeed.y')*0.2)) * arrowSize*0.5);
	end
	if template.getProperty('drunk.angle') ~= 0 then 
		zOffset = (zOffset + template.getProperty('drunk.angle') * (math.cos( ((songPosition*0.001) + ((data%keyCount)*0.2) + (zOffset*0.45)*(10/screenHeight)) * (template.getProperty('drunkSpeed.angle')*0.2)) * arrowSize*0.5));
	end
	if template.getProperty('drunk.stair')~=0 then
		yOffset+=math.sin(songPosition*0.001)*(data%keyCount)*(2.0)*template.getProperty('drunk.stair')
		xOffset+=math.sin(songPosition*0.001)*(data%keyCount)*(2.0)*template.getProperty('drunk.stair')
	end

	--tipsy
	if template.getProperty('tipsy.x') ~= 0 then 
		xOffset = xOffset + template.getProperty('tipsy.x') * ( math.cos( songPosition*0.001 *(1.2) + (data%keyCount)*(2.0) + template.getProperty('tipsySpeed.x')*(0.2) ) * arrowSize*0.4 );
	end
	if template.getProperty('tipsy.y') ~= 0 then 
		yOffset = yOffset + template.getProperty('tipsy.y') * ( math.cos( songPosition*0.001 *(1.2) + (data%keyCount)*(2.0) + template.getProperty('tipsySpeed.y')*(0.2) ) * arrowSize*0.4 );
	end
	if template.getProperty('tipsy.angle') ~= 0 then 
		zOffset = (zOffset + template.getProperty('tipsy.angle') * ( math.cos( songPosition*0.001 *(1.2) + (data%keyCount)*(2.0) + template.getProperty('tipsySpeed.angle')*(0.2) ) * arrowSize*0.4 ));
	end



	--reverse (scroll flip)
	if template.getProperty('reverse.y') ~= 0 or template.getProperty('reverse'..data..'.y') ~= 0 then 
		yOffset = yOffset + (Conductor.Downscroll and -scrollSwitch or scrollSwitch) * (template.getProperty('reverse.y') + template.getProperty('reverse'..data..'.y'))
	end
	

	--confusion (note angle)
	if template.getProperty('confusion.angle') ~= 0 or template.getProperty('confusion'..data..'.angle') ~= 0 then 
		angle = angle + template.getProperty('confusion.angle') + template.getProperty('confusion'..data..'.angle')
	end

	if template.getProperty('stealth.alpha') ~= 0 then --notes
		if curPos ~= 0 then 
			alpha = alpha - template.getProperty('stealth.alpha')
		end
	end

	if template.getProperty('dark.alpha') ~= 0 then --strums
		if curPos == 0 then 
			alpha = alpha - template.getProperty('dark.alpha')
		end
	end

	if template.getProperty('hidden.alpha') ~= 0 then
		if curPos ~= 0 then 
			local fHiddenVisibleAdjust = template.scale( (-curPos / songSpeed), template.getHiddenStartLine(), template.getHiddenEndLine(), -1, 0);
			fHiddenVisibleAdjust = template.clamp( fHiddenVisibleAdjust, -1, 0 );
			alpha = alpha + template.getProperty('hidden.alpha') * fHiddenVisibleAdjust;
		end
	end
	if template.getProperty('sudden.alpha') ~= 0 then
		if curPos ~= 0 then 
			local fSuddenVisibleAdjust = template.scale( (-curPos / songSpeed), template.getSuddenStartLine(), template.getSuddenEndLine(), -1, 0);
			fSuddenVisibleAdjust = template.clamp( fSuddenVisibleAdjust, -1, 0 );
			alpha = alpha + template.getProperty('sudden.alpha') * fSuddenVisibleAdjust;
		end
	end

	if template.getProperty('waveShit.angle') ~= 0 then 
		zOffset =(zOffset + (64*template.getProperty('waveShit.angle')) * -math.sin((songPosition*0.001*math.pi)-data))
	end
	if template.getProperty('waveShit.y') ~= 0 then 
		yOffset = yOffset + (32*template.getProperty('waveShit.y')) * math.cos((songPosition*0.001*math.pi)-(data%2))
	end

	--add any custom modifiers here lol 
	--though you can do it cross script with the hscript function

	if not legacyPsychMode and allowCrossScriptModifiers then 
		template.runHaxeCode([[
			var data = ]]..data..[[;
			var curPos = ]]..curPos..[[;
			var arrowSize = ]]..arrowSize..[[;
			var keyCount = ]]..keyCount..[[;
	
			var func = game.variables["customModifierFunction"]; //cross script mods!!!!!!
			func(data, curPos, arrowSize, keyCount);
		]])

		xOffset = xOffset + currentXOffset
		yOffset = yOffset + currentYOffset
		zOffset = zOffset + currentZOffset
		angle = angle + currentAngleOffset
		alpha = alpha * currentAlphaOffset
	end

	return xOffset, yOffset, zOffset, angle, alpha
	--do divide 1000 on z so it matches more closely to the other axis
end

function template.clamp(val, min, max)
	if val < min then
		val = min
	elseif max < val then
		val = max
	end
	return val
end
--https://stackoverflow.com/questions/5294955/how-to-scale-down-a-range-of-numbers-with-a-known-min-and-max-value
function template.scale(valueIn, baseMin, baseMax, limitMin, limitMax)
	return ((limitMax - limitMin) * (valueIn - baseMin) / (baseMax - baseMin)) + limitMin
end

function template.lerp(a, b, ratio)
	return a + ratio * (b - a); --the funny lerp
end

--//--//--

function template.thisStart(allReceptors)

	for i=0,3 do
		template.strumLine[i]=allReceptors[i+5]
	end
	for i=4,7 do
		template.strumLine[i]=allReceptors[i-3]
	end

	for i = 0, (keyCount*2)-1 do 
		local swagStrum=template.strumLine[i]
		
		swagStrum.angle=0
		swagStrum.scale={
			['x']=swagStrum.Size.X,
			['y']=swagStrum.Size.Y,
		}

		swagStrum.Z=0
		swagStrum.NoteData=i

		swagStrum.DefaultScale=swagStrum.Scale
		swagStrum.scaleOffsetX=0
		swagStrum.scaleOffsetY=0

		swagStrum.DefFrameSizeX=swagStrum.AnimData.Frames[swagStrum.Frame].FrameSize.X
		swagStrum.DefFrameSizeY=swagStrum.AnimData.Frames[swagStrum.Frame].FrameSize.Y

	end
	template.ready=true
	function Note:SetPosition(rawX,rawY)
		
		local noteStep=math.floor((self.StrumTime/1000) * (Conductor.BPM/15))
		
		if not self.Z then
			self.Z=0
		end

		if self.ScaleType~=Enum.ScaleType.Stretch then
			self.NoteObject.ScaleType=Enum.ScaleType.Stretch
		end

		if not self.NoteObject:FindFirstChild('Note3d') and not self.IsSustain then
			local Note3d=assets.Note3d:Clone()
			Note3d.Parent=self.NoteObject
			Note3d.Size=UDim2.fromScale(1,1)
			Note3d.AnchorPoint=Vector2.new(.5,.5)
			Note3d.Position=UDim2.fromScale(.5,.5)
			local swagNote=Note3d.WorldModel.swagNote
			local daXml=template.Note3dXML
			local insideColor=nil
			local outsideColor=nil
			if noteStep%2==0 then
				insideColor=daXml.notesInside[2][1]
				outsideColor=daXml.notesOutSide[2][1]
			else
				insideColor=daXml.notesInside[1][1]
				outsideColor=daXml.notesOutSide[1][1]
			end
			swagNote.Inside.Color=insideColor
			swagNote.outSide.Color=outsideColor
		elseif self.NoteObject:FindFirstChild('Note3d') and not self.IsSustain then
			local swagNote=self.NoteObject.Note3d.WorldModel.swagNote
			swagNote.Inside.Orientation=self.ReceptorTarget.GUI.Note3d.WorldModel.swagNote.Inside.Orientation
			swagNote.outSide.Orientation=swagNote.Inside.Orientation
			self.Transparency=1
		end

		if not self.NoteObject:FindFirstChild('swagScale') then
			local swagScale=Instance.new('UIScale')
			swagScale.Name='swagScale'
			swagScale.Parent=self.NoteObject
		else
			local baseZVal=(template.getProperty('laneZ')+self.Z)/1000

			if not self.IsSustain then
				self.Scale=Vector2.new(self.ReceptorTarget.Scale.X+baseZVal,self.ReceptorTarget.Scale.Y+baseZVal)
			else
				self.Scale=Vector2.new(self.ReceptorTarget.Scale.X+baseZVal,self.Scale.Y)
			end
		end

		template.pos(self,rawX,rawY,template.playerStrums,template.dadStrums)
		template.NoteModifiers(self)
	end

	if not middlescroll and template.ForcedMiddleScroll then
		local addStrum=0;
		local addStrum2=0;
		if template.playerStrums[1].Side=='Left' then
			addStrum=1280
			addStrum2=34.8
		else
			addStrum=-34.8
			addStrum2=1280
		end
		--for i=0,3 do
			--template.setProperty('strumOffset4'..(i+4)..'.x',addStrum)
			--template.setProperty('strumOffset4'..i..'.x',addStrum2)
		--end
	end

	template.onStart()

end

function template.thisUpdate(elapsed)
	songPosition=Conductor.SongPos
	songSpeed=shared.songData.speed

	if template.ready then
		for i=0,(keyCount*2)-1 do
			local daStrum=template.strumLine[i]
			local daStrum3D=template.Strum3dLine[i].WorldModel.swagNote
			local rotOffset=template.Note3dXML.rotationOffset[daStrum.NoteData%4+1]
			daStrum.GUI.Rotation=daStrum.angle

			daStrum3D.Inside.Orientation=Vector3.new(template.getProperty('swagAngleOffset'..i..'.x'),template.getProperty('swagAngleOffset'..i..'.y'),rotOffset+template.getProperty('swagAngleOffset'..i..'.z'))
			daStrum3D.outSide.Orientation=daStrum3D.Inside.Orientation
			daStrum3D.outSide.Color=(template.Note3dXML[daStrum.CurrAnimation][daStrum.NoteData%4+1][daStrum.Frame] or template.Note3dXML.static[daStrum.NoteData%4+1][1])

			daStrum.GUI.Size=UDim2.fromScale((daStrum.DefFrameSizeX*daStrum.Scale.X)/(daStrum.ScaleFactors or daStrum.GUI.Parent.AbsoluteSize).X,(daStrum.DefFrameSizeY*daStrum.Scale.Y)/(daStrum.ScaleFactors or daStrum.GUI.Parent.AbsoluteSize).Y)


			local xOffset, yOffset, zOffset, angle, alpha=template.runModifiers(i,daStrum.Y,daStrum.X,daStrum.Y)

			daStrum.Scale=Vector2.new(daStrum.DefaultScale.X+daStrum.scaleOffsetX+((daStrum.Z+(zOffset*10))/100),daStrum.DefaultScale.Y+daStrum.scaleOffsetY+((daStrum.Z+(zOffset*10))/100))
			daStrum:UpdateSize()

			daStrum.GUI.Position =UDim2.new(
				((daStrum.X+((daStrum.Z/10)+xOffset+zOffset)*10) * (shared.autoSize * shared.customSize))/shared.noteScaleRatio.X,0,
				(daStrum.Y+((daStrum.Z/10)+yOffset+zOffset)*10)/720, 0--(shared.handler.settings.Downscroll and -self.GUI.AbsoluteSize.Y/2 or self.GUI.AbsoluteSize.Y)
			)
			daStrum.xWithOffset=(daStrum.X+((daStrum.Z/10)+xOffset+zOffset)*10)
			daStrum.yWithOffset=(daStrum.Y+((daStrum.Z/10)+yOffset+zOffset)*10)
		end
	end
end

return template

