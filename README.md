# Instructions


<<Spl4ash YAFN Template 1.0>>

>> feel free to port this to other engines
>> use this in your game if you want, its free to use
>> my discord tag if you have any question: spl4ash


<<TEMPLATE SUPPORTS (1.0)>>

{
-->3D Notes
-->Custom Note Colours
-->Custom Note Models
-->Custom Note/Strum Modifiers
-->Custom Receptor Functions
-->Custom Note Offsets
-->Multi Note Cam
-->Properties(Psych Engine Like)
-->Number Tweens
-->Strum Tweens
}

<<YAFN ENGINE CHANGES INSTRUCTIONS>>

--//NOTECLASS CHANGES//--
--default yafn notes have a weird x offset(note position + receptor position), so i changed it a little


function NoteClass:Update()
	if(self.Destroyed)then return end
	self.Animation:UpdateSize();
	
	if shared.internalSettings.notesShareTransparencyWithReceptors then
		self.Animation.Alpha = 1- (self.DefaultTransparency + ((1-self.DefaultTransparency) * (1-self.ReceptorTarget.Alpha)))
	else
		self.Animation.Alpha = 1- (self.DefaultTransparency + ((1-self.DefaultTransparency) * self.Transparency))
	end
	self.Size=self.Animation.Size
	local X,Y = self.Size.X*self.Scale.X,self.Size.Y*self.Scale.Y
	--self.NoteObject.Position=UDim2.new(0,(self.X+self.Offset.X)*self.Animation.Scale.X,(50+self.Y+self.Offset.Y+(Y/2)+self.Sink)/Conductor.screenSize.Y,0)+UDim2.new(0,self.Animation.FrameOffset.X,0,self.Animation.FrameOffset.Y)

	self.NoteObject.Size=UDim2.new((X * self.Animation.Scale.X)/self.Animation.ScaleFactors.X,0,((Y-self.Sink) * self.Animation.Scale.Y)/self.Animation.ScaleFactors.Y,0)
	if(self.NoteObject.Parent)then
		self.NoteObject.Position = UDim2.new((((self.X+self.Offset.X)-self.Animation.FrameOffset.X)/shared.noteScaleRatio.X),0,((self.Y+self.Offset.Y+self.Sink)-self.Animation.FrameOffset.Y)/(Conductor.screenSize.Y),0)
		if shared.internalSettings.notesRotateWithReceptors and (not self.IsSustain) then
			self.NoteObject.Rotation = self.ReceptorTarget.GUI.Rotation--shared.Receptors[self.RawData[2]+1].GUI.Rotation
		end
	end
	if(self.MustPress)then
		if((self.Type=='Sword' or self.Type=='Glitch') and self.StrumTime<Conductor.SongPos-20 or self.StrumTime<Conductor.SongPos-Conductor.safeZoneOffset and not self.GoodHit)then
			self.TooLate=true
		end
		if(not self.TooLate)then
			if(self.IsSustain) then
				self.CanBeHit = (self.StrumTime > Conductor.SongPos - 80 and self.StrumTime < Conductor.SongPos + 80)
			elseif(self.Type == "Ice") then
				self.CanBeHit = (self.StrumTime > Conductor.SongPos - (Conductor.safeZoneOffset*.15) and self.StrumTime < Conductor.SongPos + (Conductor.safeZoneOffset*.25))
			elseif(self.Type=='Poison') then
				self.CanBeHit = (self.StrumTime > Conductor.SongPos - (Conductor.safeZoneOffset*.4) and self.StrumTime < Conductor.SongPos + (Conductor.safeZoneOffset*.2))
			elseif(self.Type=='ExTricky' or self.Type=='kill' or self.Type == "FireNote" or self.Type == "Disease") then -- Shaggy kill notes & Halo notes
				self.CanBeHit = (self.StrumTime > Conductor.SongPos - (Conductor.safeZoneOffset*.3) and self.StrumTime < Conductor.SongPos + (Conductor.safeZoneOffset*.2))
			elseif(self.Type=='Karma' or self.Type=='Bone' or self.Type=="Phantom") then
				self.CanBeHit = (self.StrumTime > Conductor.SongPos - (Conductor.safeZoneOffset*.6) and self.StrumTime < Conductor.SongPos + (Conductor.safeZoneOffset*.4))
			elseif((self.Type=='RuriaVoid' or self.Type=='RuriaHurt') and self.Side=='Left' ) then
				self.CanBeHit = (self.StrumTime > Conductor.SongPos - Conductor.safeZoneOffset and self.StrumTime < Conductor.SongPos + Conductor.safeZoneOffset)
			else
				self.CanBeHit = (self.StrumTime > Conductor.SongPos - self.Hitbox and self.StrumTime < Conductor.SongPos + self.Hitbox)
			end
		else
			self.CanBeHit=false
		end
	elseif not (self.MustPress) or Conductor.BotPlay then
		self.CanBeHit=false
		if(self.StrumTime<=Conductor.SongPos and self.Type~='Glitch' and self.Type~='Sword')then
			self.GoodHit=true
		end
	end

	if(self.TooLate and self.NoteObject.ImageTransparency<(.6 * (1 - self.NoteObject.ImageTransparency)))then
		self.NoteObject.ImageTransparency=.6 * (1 - self.NoteObject.ImageTransparency)
	end
end


--//GAME HANDLER CHANGES//--

REPLACE THE daNote:SetPosition( TO THIS

daNote:SetPosition(
	receptor.xWithOffset or receptor.X,
	yPos
)

<<-->>
