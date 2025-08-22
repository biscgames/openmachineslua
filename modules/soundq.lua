-- Me and me and me and me have all agreed to make a sound queue library for love2d
-- I disagreed, I also disagreed, since the me's are more voted against the uhhhhhhhh
-- what was it again?
local soundq = {}
local queue = {}
soundq.pushqueue = function(source)
	assert(type(source)=="userdata", "SoundQ only adds source values to the queue.")
	queue[#queue+1]= source:clone()
end
soundq.playqueue = function()
	while #queue > 0 do
		queue[1]:play()
		table.remove(queue,1)
	end
end
soundq.getqueue = function()
	return queue
end
return soundq
