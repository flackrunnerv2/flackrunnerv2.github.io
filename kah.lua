print("Script loaded.")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
local Terrain = workspace:FindFirstChildWhichIsA("Terrain")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer.PlayerGui
local Character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local gameFolder = Terrain:FindFirstChild("_Game")
local padsFolder = gameFolder:FindFirstChild("Admin")
local regenPad = padsFolder:FindFirstChild("Regen")
local adminPads = padsFolder:FindFirstChild("Pads")
local SayMessageRequest = ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
local chatFrame: Frame = PlayerGui.Chat.Frame.ChatChannelParentFrame.Frame_MessageLogDisplay.Scroller

local SpamLoop = nil
local SpamActive = false
local FlashLoop = nil
local FlashActive = false
local AnimateLoop = nil
local AnimateActive = false
local BHCheckLoop = nil
local CheckActive = false

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
		print("Attempting to crash server...")
		while task.wait(0.05) do
			runCommandHidden("btools me,fuck")
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
		print("Flashing is now active.")
	end,
	["unflash"] = function()
		print("Flashing is no longer active.")
		FlashActive = false
		FlashLoop = nil
	end,
	["animatehint"] = function(args)
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
		print("Now animating setmessage.")
	end,
	["unanimatehint"] = function()
		print("No longer animating setmessage.")
		AnimateActive = false
		AnimateLoop = nil
	end,
	["spam"] = function(args)
		if not args or #args < 2 then
			return
		end

		local delayTime = tonumber(args[#args]) or 0.5
		
		local commandArgs = table.clone(args)
		table.remove(commandArgs, #commandArgs)

		local commandToSpam = table.concat(commandArgs, " ")

		if SpamActive then
			return
		end

		SpamActive = true

		SpamLoop = task.spawn(function()
			while SpamActive do
				runCommandHidden(commandToSpam)
				task.wait(delayTime)
			end
		end)
		print("Now spamming inputted command.")
	end,
	["unspam"] = function()
		print("Stopped spamming inputted command.")
		SpamActive = false
		SpamLoop = nil
	end,
	["blacklist"] = function(args)
		local target = args[1]

		if not target then return end
		target = target:lower()

		if target == "all" or target == "me" or target == "others" then
			runCommandHidden("setgrav " .. target .. ",fuck" .. " -9e9")
			runCommandHidden("punish " .. target .. ",fuck")
			runCommandHidden("blind " .. target .. ",fuck")
			return
		end

		local player = findPlayer(target)
		if player then
			Blacklist[player.Name] = true
		end
		print("Blacklisted target.")
	end,
	["unblacklist"] = function(args)
		local target = args[1]

		if not target then return end
		target = target:lower()

		if target == "all" or target == "me" or target == "others" then
			runCommandHidden("reset " .. target .. ",fuck")
			return
		end

		local player = findPlayer(target)
		if player then
			runCommandHidden("reset " .. player.Name .. ",fuck")
			Blacklist[player.Name] = nil
		end
		
		print("Unblacklisted target.")
	end,
	["getpad"] = function()
		local Root = Character:FindFirstChild("HumanoidRootPart")
		local freePadColor = Color3.fromRGB(40, 127, 71)

		local foundFreePad = false

		for _, v in pairs(adminPads) do
			local pad = v:FindFirstChild("Head")
			if pad.Color == freePadColor then
				foundFreePad = true
				firetouchinterest(Root, pad, 0)
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
						firetouchinterest(Root, pad, 0)
						break
					end
				end
			end
		end
	end,
	["resetpads"] = function()
		print("Admin pads have been reset.")
		local clickDetector = regenPad:FindFirstChildOfClass("ClickDetector")
		fireclickdetector(clickDetector)
	end,
	["antibh"] = function()
		if CheckActive then
			return
		end

		CheckActive = true
		
		print("Anti ban hammer has been enabled.")

		BHCheckLoop = task.spawn(function()
			while CheckActive do
				for _, p in pairs(Players:GetPlayers()) do
					local character = p.Character
					Character.ChildAdded:Connect(function(ch)
						if ch:IsA("Tool") and ch.Name == "BanHammer" then
							runCommandHidden("ungear " .. p.Name .. ",fuck")
						end
					end)
				end
			end
		end)
	end,
	["unantibh"] = function()
		print("Anti ban hammer has been disabled.")
		CheckActive = false
		BHCheckLoop = nil
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

function getScore(player)
	local SScore = player:FindFirstChild("SScore")
	return SScore.Value
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
			local playerGui = playerInstance.PlayerGui

			if char and char.Parent == workspace then
				runCommandHidden("setgrav " .. playerInstance.Name .. ",fuck" .. " -9e9")
				runCommandHidden("punish " .. playerInstance.Name .. ",fuck")
				runCommandHidden("blind " .. playerInstance.Name .. ",fuck")
			end
		end
	end
end

chatFrame.ChildAdded:Connect(function(child)
	local textLabel = child:FindFirstChildOfClass("TextLabel")
	local textButton = textLabel:FindFirstChildOfClass("TextButton")
	if string.find(textLabel.Text, "You are muted and cannot talk in this channel") and textButton.Text == "{System}" then
		child:Destroy()
	end
end)
