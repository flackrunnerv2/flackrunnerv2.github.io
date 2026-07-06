print("Script loaded.")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Terrain = workspace:FindFirstChildWhichIsA("Terrain")

local gameFolder = Terrain:FindFirstChild("_Game")
local padsFolder = gameFolder:FindFirstChild("Admin")

local regenPad = padsFolder:FindFirstChild("Regen")
local adminPads = padsFolder:FindFirstChild("Pads")
local SayMessageRequest = ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest

local LocalPlayer = Players.LocalPlayer
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local SpamLoop = nil
local SpamActive = false
local FlashLoop = nil
local FlashActive = false
local AnimateLoop = nil
local AnimateActive = false

local Animations = {
	[1] = {
		"Oooooooooo";
		"oOoooooooo";
		"ooOooooooo";
		"oooOoooooo";
		"ooooOooooo";
		"oooooOoooo";
		"ooooooOooo";
		"oooooooOoo";
		"ooooooooOo";
		"oooooooooO";
		"ooooooooOo";
		"oooooooOoo";
		"ooooooOooo";
		"oooooOoooo";
		"ooooOooooo";
		"oooOoooooo";
		"ooOooooooo";
		"oOoooooooo";
		"Oooooooooo";
	};
};
local Prefix = "!"
local Blacklist = {}
local Commands = {
	["crashserver"] = function()
		for i = 1, 10000 do
			runCommandHidden("btools me")
			task.wait(0.05)
		end
	end,
	["flash"] = function()
		if FlashActive then
			return
		end

		FlashActive = true

		FlashLoop = task.spawn(function()
			while FlashActive do
				runCommandHidden("fogend 0")
				task.wait(0.15)
				runCommandHidden("fogcolor 255 255 255")
				task.wait(0.15)
				runCommandHidden("fogcolor 0 0 0")
				task.wait(0.15)
			end
		end)
	end,
	["unflash"] = function()
		FlashActive = false
		FlashLoop = nil
	end,
	["animatehint"] = function(_, args)
		local animId = tonumber(args[1])
		if not animId then return end

		local frames = Animations[animId]
		if not frames then return end

		if AnimateActive then
			return
		end

		AnimateActive = true

		AnimateLoop = task.spawn(function()
			while AnimateActive do
				for _, frame in ipairs(frames) do
					if not AnimateActive then break end

					runCommandHidden("setmessage " .. frame)
					task.wait(0.15)
				end
			end
		end)
	end,
	["unanimatehint"] = function()
		AnimateActive = false
		AnimateLoop = nil
	end,
	["spam"] = function(_, args)
		if not args or not args[1] then return end

		local commandToSpam = table.concat(args, " ")

		if SpamActive then
			return
		end

		SpamActive = true

		SpamLoop = task.spawn(function()
			while SpamActive do
				runCommandHidden(commandToSpam)
				task.wait(0.5)
			end
		end)
	end,
	["unspam"] = function()
		SpamActive = false
		SpamLoop = nil
	end,
	["blacklist"] = function(args)
		local target = args[1]

		if not target then return end
		target = target:lower()

		if target == "all" or target == "me" or target == "others" then
			runCommandHidden("setgrav " .. target .. " -9e9")
			runCommandHidden("punish " .. target)
			runCommandHidden("blind " .. target)
			return
		end

		local player = findPlayer(target)
		if player then
			Blacklist[player.Name] = true
		end
	end,
	["unblacklist"] = function(args)
		local target = args[1]

		if not target then return end
		target = target:lower()

		if target == "all" or target == "me" or target == "others" then
			runCommandHidden("respawn " .. target)
			return
		end

		local player = findPlayer(target)
		if player then
			runCommandHidden("respawn " .. player.Name)
			Blacklist[player.Name] = nil
		end
	end,
	["getpad"] = function()
		local freePadColor = Color3.fromRGB(40, 127, 71)

		local foundFreePad = false

		for _, v in pairs(adminPads) do
			local pad = v:FindFirstChild("Head")
			if pad.Color == freePadColor then
				foundFreePad = true

				firetouchinterest(Character.PrimaryPart, pad, 0)

				task.delay(0.5, function()
					firetouchinterest(Character.PrimaryPart, pad, 1)
				end)

				break
			end
		end

		if not foundFreePad then
			local clickDetector = regenPad:FindFirstChildOfClass("ClickDetector")

			if clickDetector then
				fireclickdetector(clickDetector)

				task.wait(0.5)

				for _, v in pairs(adminPads) do
					local pad = v:FindFirstChild("Head")

					if pad.Color == freePadColor then
						firetouchinterest(Character.PrimaryPart, pad, 0)

						task.delay(0.5, function()
							firetouchinterest(Character.PrimaryPart, pad, 1)
						end)

						break
					end
				end
			end
		end
	end,
	["resetpads"] = function()
		local clickDetector = regenPad:FindFirstChildOfClass("ClickDetector")
		fireclickdetector(clickDetector)
	end,
	["antibh"] = function()
		local clickDetector = regenPad:FindFirstChildOfClass("ClickDetector")
		fireclickdetector(clickDetector)
	end,
	["antibh"] = function()
		local clickDetector = regenPad:FindFirstChildOfClass("ClickDetector")
		fireclickdetector(clickDetector)
	end,
}

Commands.cmds = function()
	for name in pairs(Commands) do
		if name ~= "cmds" then
			print(Prefix .. name)
		end
	end
end

function runCommandHidden(str)
	SayMessageRequest:FireServer(str, "System")
end

function findPlayer(partialName)
	if not partialName or partialName == "" then
		return nil
	end

	partialName = partialName:lower()

	local bestMatch = nil

	for _, player in ipairs(Players:GetPlayers()) do
		local name = player.Name:lower()

		if name == partialName then
			return player
		end

		if name:sub(1, #partialName) == partialName then
			bestMatch = bestMatch or player
		end
	end

	return bestMatch
end

function executeCommand(msg)
	if msg:sub(1, #Prefix) ~= Prefix then
		return
	end

	msg = msg:sub(#Prefix + 1)

	local args = string.split(msg, " ")
	local commandName = table.remove(args, 1)

	if not commandName then return end
	commandName = commandName:lower()

	local command = Commands[commandName]
	if not command then return end

	command(args)
end

TextChatService.MessageReceived:Connect(function(textChatMessage)
	local textSource = textChatMessage.TextSource
	if textSource then
		if textSource.Name == LocalPlayer.Name then
			executeCommand(textChatMessage.Text)
		end
	end
end)

LocalPlayer.CharacterAdded:Connect(function(newCharacter)
	Character = newCharacter
end)

while task.wait(0.5) do
	for entry in pairs(Blacklist) do

		local targets = {}

		if entry == "all" then
			targets = Players:GetPlayers()
		elseif entry == "me" then
			targets = {LocalPlayer}
		elseif entry == "others" then
			for _, p in ipairs(Players:GetPlayers()) do
				if p ~= LocalPlayer then
					table.insert(targets, p)
				end
			end
		else
			local playerInstance = Players:FindFirstChild(entry)
			if playerInstance then
				targets = {playerInstance}
			end
		end

		for _, playerInstance in ipairs(targets) do
			local char = playerInstance.Character

			if char and char.Parent == workspace then
				runCommandHidden("setgrav " .. playerInstance.Name .. " -9e9")
				runCommandHidden("punish " .. playerInstance.Name)
				runCommandHidden("blind " .. playerInstance.Name)
			end
		end
	end
end
