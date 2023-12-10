local common_brain = require("brains/common_brain_functions")

local FlytrapBrain = Class(Brain, function(self, inst)
	Brain._ctor(self, inst)
end)

function FlytrapBrain:OnStart()
	self.bt = BT(self.inst, common_brain.CreatePetBehaviorRoot(self.inst))
end

return FlytrapBrain
