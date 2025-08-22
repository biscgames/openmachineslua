image_directories = {"machines","items","icons","states"}
loaded_mods = {}

if not love.filesystem.getInfo("mods","directory") then
	love.filesystem.createDirectory("mods")
end
for _,folder in ipairs({"mods","coremods"}) do
	for _,mod in ipairs(love.filesystem.getDirectoryItems(folder)) do
		local dir = folder.."/"..mod
		if love.filesystem.getInfo(dir,"directory") then
			if love.filesystem.getInfo(dir.."/textures","directory") then
				image_directories[#image_directories+1]= dir.."/textures"
			end
			loaded_mods[#loaded_mods+1]= love.filesystem.load(dir.."/init.lua")
		else
			loaded_mods[#loaded_mods+1]= love.filesystem.load(dir)
		end
	end
end
