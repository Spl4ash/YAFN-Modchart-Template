local runService=game:GetService('RunService');

local module = {};
module.__index=module;

module.new=function(swagBG,swagNotes,parent)
	local newCam=setmetatable({
		bgToClone=swagBG;
		notesToClone=swagNotes;
		localToPrent=parent;
		X=0;
		Y=0;
	},module)
	newCam:setup()
	newCam.updateService=runService.RenderStepped:Connect(function(elapsed)
		newCam:Update(elapsed)
	end)
	return newCam
end;

function module:setup()
	self.curBG=self.bgToClone:Clone()
	self.curBG.Parent=self.localToPrent
	self.curNotes=self.notesToClone:Clone()
	self.curNotes.Parent=self.localToPrent
end

function module:Update(elapsed)
	for i,note in pairs(self.curNotes:GetChildren()) do
		note:Destroy()
	end
	
	for i,note in pairs(self.notesToClone:GetChildren()) do
		local daNote=note:Clone()
		if self.curNotes then
			daNote.Parent=self.curNotes
		end
	end
	
	self.curBG.Position=UDim2.fromScale(self.X,self.Y)
	self.curNotes.Position=self.curBG.Position
end;

function module:kill()
	if self.updateService then
		self.updateService:Disconnect()
		self.updateService=nil
	end
	if self.curBG and self.curNotes then
		self.curBG:Destroy()
		self.curNotes:Destroy()
	end
	self=nil
end;

return module
