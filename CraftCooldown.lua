local prefix = "|cff1784d1C|cffffa500CD|r: "
local flag = false

local addonName = 'CraftCooldown'
local frame = CreateFrame("FRAME")
frame.name = addonName
frame:Hide()
frame:SetScript("OnShow", function(frame)
	local function newCheckbox(label, description, onClick)
		local check = CreateFrame("CheckButton", "CCDCheck" .. label, frame, "InterfaceOptionsCheckButtonTemplate")
		check:SetScript("OnClick", function(self)
			local tick = self:GetChecked()
			onClick(self, tick and true or false)
		end)
		check.label = _G[check:GetName() .. "Text"]
		check.label:SetText(label)
		check.tooltipText = label
		check.tooltipRequirement = description
		return check
	end

	local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
	title:SetPoint("TOPLEFT", 16, -16)
	title:SetText(addonName)

	local printOnOpen = newCheckbox(
		"Print cooldowns when opening trade skill window",
		"",
		function(self, value) cache['config']['onOpen'] = value end)
	printOnOpen:SetChecked(cache['config']['onOpen'])
	printOnOpen:SetPoint("TOPLEFT", title, "BOTTOMLEFT", -2, -16)

	local printOnLogin = newCheckbox(
		"Print cooldowns on login",
		"",
		function(self, value) cache['config']['onLogin'] = value end)
	printOnLogin:SetChecked(cache['config']['onLogin'])
	printOnLogin:SetPoint("TOPLEFT", printOnOpen, "BOTTOMLEFT", 0, -8)

	frame:SetScript("OnShow", nil)
end)

InterfaceOptions_AddCategory(frame)



frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("TRADE_SKILL_UPDATE")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("BAG_UPDATE_COOLDOWN")
frame:RegisterEvent("BAG_UPDATE")
frame:RegisterEvent("BAG_OPEN")

function frame:OnEvent(event, arg1)
	if event == "ADDON_LOADED"
	then
		init()
	elseif event == 'BAG_UPDATE' or event == 'BAG_UPDATE_COOLDOWN' or event == 'BAG_OPEN'
	then
		refreshItems()
	elseif event == 'TRADE_SKILL_SHOW'
	then
		flag = true
	elseif event == "TRADE_SKILL_UPDATE"
	then
		if flag
		then
			printSkills()
			flag = false
		else
			refreshSkills()
		end
	end
end
frame:SetScript("OnEvent", frame.OnEvent);

SLASH_CRAFTCOOLDOWN1 = '/ccd'
function SlashCmdList.CRAFTCOOLDOWN(msg)
	InterfaceOptionsFrame_OpenToCategory(addonName)
	InterfaceOptionsFrame_OpenToCategory(addonName)
end

function init()

	if cache == nil
	then
		cache = {
			crafts = {},
			config = {
				['onLogin'] = true,
				['onOpen'] = true,
			},
			version = '0'
		}
	end
	-- checkVersion()
	if cache['config']['onLogin']
	then
		printCached()
	end
end

-- function checkVersion()
	-- local version = GetAddOnMetadata(addonName, "version")
	-- if (cache['version'] == nil) or (version ~= cache['version'])
	-- then
	-- 	print(version .. 'vs' , cache['version'])
	-- 	cache['version'] = version
	-- 	print(format("%s %s loaded.", prefix, version))
	-- end
	-- print(version)
-- end

function refreshSkills()
	local skills = {}
	for a=0, GetNumTradeSkills(), 1
	do
		skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(a);
		seconds,y = GetTradeSkillCooldown(a);
		if seconds and seconds > 0
		then
			-- cooldown = seconds / 60 / 60
			cache['crafts'][skillName] = time() + seconds
			if cache['config']['onOpen']
			then
				table.insert(skills, {skillName, seconds})
			end
		end
	end
	return skills
end

function refreshItems()
	for bag = 0, 4
	do
		for slot = 1, GetContainerNumSlots(bag)
		do
			local item = GetContainerItemLink(bag, slot);
			if item ~= nil
			then
				local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(item);
				if sName == "Salt Shaker" -- or sName == "Second Wind"
				then
					local startTime, duration, isEnabled = GetContainerItemCooldown(bag, slot);
					local readyAt = startTime + duration - GetTime() + time()
					if cache['crafts'][sName] == nil
					then
						print(format("%s Added [%s]", prefix, sName))
					end
					cache['crafts'][sName] = readyAt
				end	
			end
		end
	end
end

function printSkills()
	for _, row in pairs(refreshSkills())
	do
		printSkill(row[1], row[2])
	end
end

function printSkill(skillName, seconds)
	local gradient = getGradient(seconds)
	if seconds < 0
	then
		print(format("%s%s%s !READY! |r[%s%s|r]", prefix, gradient, skillName, gradient, disp_time(seconds*-1)))
	else
		print(format("%s%s%s |r[%s%s|r]", prefix, gradient, skillName, gradient, disp_time(seconds)))
	end
end

function getGradient(seconds)
	local grad = {
		[0] = "|cff00ffff", -- READY
		[1 * 60 * 60] = "|cff7cfc00",
		[2 * 60 * 60] = "|cff32cd32",
		[4 * 60 * 60] = "|cff228b22",
		[8 * 60 * 60] = "|cff006400",
		[12 * 60 * 60] = "|cffffd700",
		[24 * 60 * 60] = "|cffff8c00",
		[48 * 60 * 60] = "|cffff0000",
		[99 * 60 * 60] = "|cff8b0000",
	}
	local keys = {}
	for t,c in pairs(grad)
	do
		table.insert(keys, t)
	end
	table.sort(keys)
	for _, t in pairs(keys)
	do
		if seconds < t
		then 
			return grad[t]
		end
	end
	print("This should not have happened!")
end


function disp_time(time)
	local days = floor(time/86400)
	local hours = floor(mod(time, 86400)/3600)
	local minutes = floor(mod(time,3600)/60)
	local seconds = floor(mod(time,60))
	return format("%dd %dh %dm %ds",days,hours,minutes,seconds)
end

function printCached()
	for _, entry in pairs(sortHash(cache['crafts']))
	do
		skillName = entry['name']
		seconds = entry['seconds']
		readyAt = seconds - time()
		printSkill(skillName, readyAt)
	end
end

function sortHash(hash)
	local keys = {}
	local tbl = {}
	for key, val in pairs(hash)
	do
		table.insert(keys, key)
	end
	table.sort(keys)
	for _, key in pairs(keys)
	do
		local entry = {
			['name'] = key,
			['seconds'] = hash[key]
		}
		table.insert(tbl, entry)
	end
	return tbl
end