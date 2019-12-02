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

	local label = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	label:SetPoint("TOPLEFT", 6, -16)
	label:SetText('Ignored Cooldowns')
	label:SetPoint("TOPLEFT", printOnLogin, "BOTTOMLEFT", 0, -8)

	-- DropDown
	local dropdown = CreateFrame("Frame", "CCDIgnored", frame, "UIDropDownMenuTemplate")
	dropdown:SetPoint("TOPLEFT", label, "BOTTOMLEFT", 0, -8)
	dropdown.initialize = function()
		local dd = {}
		for _, entry in pairs(sortHash(cache['crafts']))
		do
			dd.text = entry['name']
			dd.value = entry['name']
			dd.func = function(self)
				toggleIgnoreCooldown(self.value)
				self.checked = isCooldownIgnored(self.value)
				CCDIgnoredString:SetText(getIgnoredString())
			end
			dd.checked = isCooldownIgnored(entry['name'])
			UIDropDownMenu_AddButton(dd)
		end
	end

	local ignored = frame:CreateFontString('CCDIgnoredString', "ARTWORK", "GameFontNormalSmall")
	ignored:SetPoint("TOPLEFT", dropdown, "BOTTOMLEFT", 8, -8)
	ignored:SetText(getIgnoredString())
	ignored:SetJustifyH("LEFT")

	-- Global Ignore
	local labelGlobal = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
	labelGlobal:SetPoint("TOPLEFT", 6, -16)
	labelGlobal:SetText('Ignored Global Cooldowns')
	labelGlobal:SetPoint("TOPLEFT", printOnLogin, "BOTTOMLEFT", 200, -8)

	local dropdownGlobal = CreateFrame("Frame", "CCDGlobalIgnored", frame, "UIDropDownMenuTemplate")
	dropdownGlobal:SetPoint("TOPLEFT", labelGlobal, "BOTTOMLEFT", 0, -8)
	dropdownGlobal.initialize = function()
		local dd = {}
		for _, entry in pairs(sortHash(getGlobalCooldowns()))
		do
			dd.text = entry['name']
			dd.value = entry['name']
			dd.func = function(self)
				toggleIgnoreGlobalCooldown(self.value)
				self.checked = isGlobalCooldownIgnored(self.value)
				CCDGlobalIgnoredString:SetText(getGlobalIgnoredString())
			end
			dd.checked = isGlobalCooldownIgnored(entry['name'])
			UIDropDownMenu_AddButton(dd)
		end
	end

	local ignoredGlobal = frame:CreateFontString('CCDGlobalIgnoredString', "ARTWORK", "GameFontNormalSmall")
	ignoredGlobal:SetPoint("TOPLEFT", dropdownGlobal, "BOTTOMLEFT", 8, -8)
	ignoredGlobal:SetText(getGlobalIgnoredString())
	ignoredGlobal:SetJustifyH("LEFT")

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
	if msg ~= nil and msg ~= ""
	then 
		if msg == 'demo'
		then
			demo()
		end
	else -- TODO print /ccd params
		InterfaceOptionsFrame_OpenToCategory(addonName)
		InterfaceOptionsFrame_OpenToCategory(addonName)
	end
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
			ignored = {},
			globalIgnored = {},
			version = '0'
		}
	end
	if cache['ignored'] == nil
	then
		cache['ignored'] = {}
	end
	if cache['globalIgnored'] == nil
	then
		cache['globalIgnored'] = {}
	end

	local name = UnitName("player")
	local realm = GetRealmName("player")
	if globalCache == nil
	then
		print('Init global')
		globalCache = {
			crafts = {}
		}
	end
	if globalCache['crafts'][realm] == nil
	then
		print('Init global realm')
		globalCache['crafts'][realm] = {}
	end
	if globalCache['crafts'][realm][name] == nil
	then
		print('Init global realm char')
		globalCache['crafts'][realm][name] = {}
	end

	-- checkVersion()
	if cache['config']['onLogin']
	then
		printCached()
	end
end

function toggleIgnoreCooldown(cooldown)
	if isCooldownIgnored(cooldown)
	then
		unIgnoreCooldown(cooldown)
	else
		ignoreCooldown(cooldown)
	end
end

function toggleIgnoreGlobalCooldown(cooldown)
	if isGlobalCooldownIgnored(cooldown)
	then
		unIgnoreGlobalCooldown(cooldown)
	else
		ignoreGlobalCooldown(cooldown)
	end
end

function ignoreCooldown(cooldown)
	cache['ignored'][cooldown] = true
end

function unIgnoreCooldown(cooldown)
	cache['ignored'][cooldown] = nil
end

function ignoreGlobalCooldown(cooldown)
	cache['globalIgnored'][cooldown] = true
end

function unIgnoreGlobalCooldown(cooldown)
	cache['globalIgnored'][cooldown] = nil
end

function isCooldownIgnored(cooldown)
	if cache['ignored'][cooldown] == nil
	then
		return false
	else
		return cache['ignored'][cooldown]
	end
end

function isGlobalCooldownIgnored(cooldown)
	if cache['globalIgnored'][cooldown] == nil
	then
		return false
	else
		return cache['globalIgnored'][cooldown]
	end
end

function getIgnoredString()
	local ignoredArr = {}
	for key, val in pairs(cache['ignored'])
	do
		table.insert(ignoredArr, key)
	end

	return table.concat(ignoredArr, "\n")
end

function getGlobalIgnoredString()
	local ignoredArr = {}
	for key, val in pairs(cache['globalIgnored'])
	do
		table.insert(ignoredArr, key)
	end

	return table.concat(ignoredArr, "\n")
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
			-- cache['crafts'][skillName] = time() + seconds
			cacheCooldown(skillName, time() + seconds)
			if cache['config']['onOpen']
			then
				table.insert(skills, {skillName, seconds})
			end
		end
	end
	return skills
end

function cacheCooldown(cooldown, readyAt)
	cache['crafts'][cooldown] = readyAt
	local name = UnitName("player")
	local realm = GetRealmName("player")
	globalCache['crafts'][realm][name][cooldown] = readyAt
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
					cacheCooldown(sName, readyAt)
					-- cache['crafts'][sName] = readyAt
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

function demo()
	local matrix = {
		{ 0, "READY"}, -- READY
		{ 1 * 60 * 60, "0-1h"},
		{ 2 * 60 * 60, "1-2h"},
		{ 4 * 60 * 60, "2-4h"},
		{ 8 * 60 * 60, "4-8h"},
		{ 12 * 60 * 60, "8-12h"},
		{ 24 * 60 * 60, "12-24h"},
		{ 48 * 60 * 60, "24-48h"},
		{ 99 * 60 * 60, "48h+"}
	}
	for _, row in pairs(matrix)
	do
		local t, s = row[1], row[2]
		printSkill(s, t-60)
	end
end

function printSkill(skillName, seconds)
	local gradient = getGradient(seconds)
	if isCooldownIgnored(skillName) or isGlobalCooldownIgnored(skillName)
	then
		return
	end
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
	return grad[99 * 60 * 60]
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

	for _, entry in pairs(sortHash(getGlobalCooldowns()))
	do
		skillName = entry['name']
		seconds = entry['seconds']
		readyAt = seconds - time()
		printSkill(skillName, readyAt)
	end
end

function getGlobalCooldowns(includeCurrentCharacter)
	local cName = UnitName("player")
	local cRealm = GetRealmName("player")
	local data = {}
	for realm, realms in pairs(globalCache['crafts'])
	do
		for char, chars in pairs(realms)
		do
			for cooldown, seconds in pairs(chars)
			do
				if not (cName == char and cRealm == realm and not includeCurrentCharacter)
				then
					data[ format("(%s-%s) %s", char, realm, cooldown) ] = seconds
				end
			end
		end
	end
	return data
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