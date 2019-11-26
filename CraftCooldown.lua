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

	-- local info = {}
	-- local fontSizeDropdown = CreateFrame("Frame", "BugSackFontSize", frame, "UIDropDownMenuTemplate")
	-- fontSizeDropdown:SetPoint("TOPLEFT", mute, "BOTTOMLEFT", -15, -10)
	-- fontSizeDropdown.initialize = function()
	-- 	wipe(info)
	-- 	local fonts = {"GameFontHighlightSmall", "GameFontHighlight", "GameFontHighlightMedium", "GameFontHighlightLarge"}
	-- 	local names = {L["Small"], L["Medium"], L["Large"], L["X-Large"]}
	-- 	for i, font in next, fonts do
	-- 		info.text = names[i]
	-- 		info.value = font
	-- 		info.func = function(self)
	-- 			addon.db.fontSize = self.value
	-- 			if _G.BugSackFrameScrollText then
	-- 				_G.BugSackFrameScrollText:SetFontObject(_G[self.value])
	-- 			end
	-- 			BugSackFontSizeText:SetText(self:GetText())
	-- 		end
	-- 		info.checked = font == addon.db.fontSize
	-- 		UIDropDownMenu_AddButton(info)
	-- 	end
	-- end
	-- BugSackFontSizeText:SetText(L["Font size"])

	-- local dropdown = CreateFrame("Frame", "BugSackSoundDropdown", frame, "UIDropDownMenuTemplate")
	-- dropdown:SetPoint("LEFT", fontSizeDropdown, "RIGHT", 150, 0)
	-- dropdown.initialize = function()
	-- 	wipe(info)
	-- 	for _, sound in next, LibStub("LibSharedMedia-3.0"):List("sound") do
	-- 		info.text = sound
	-- 		info.value = sound
	-- 		info.func = function(self)
	-- 			addon.db.soundMedia = self.value
	-- 			BugSackSoundDropdownText:SetText(self:GetText())
	-- 		end
	-- 		info.checked = sound == addon.db.soundMedia
	-- 		UIDropDownMenu_AddButton(info)
	-- 	end
	-- end
	-- BugSackSoundDropdownText:SetText(L["Sound"])

	-- local clear = CreateFrame("Button", "BugSackSaveButton", frame, "UIPanelButtonTemplate")
	-- clear:SetText(L["Wipe saved bugs"])
	-- clear:SetWidth(177)
	-- clear:SetHeight(24)
	-- clear:SetPoint("TOPLEFT", fontSizeDropdown, "BOTTOMLEFT", 17, -25)
	-- clear:SetScript("OnClick", function()
	-- 	addon:Reset()
	-- end)
	-- clear.tooltipText = L["Wipe saved bugs"]
	-- clear.newbieText = L.wipeDesc

	frame:SetScript("OnShow", nil)
end)

InterfaceOptions_AddCategory(frame)



frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("TRADE_SKILL_SHOW")
frame:RegisterEvent("TRADE_SKILL_UPDATE")
frame:RegisterEvent("PLAYER_LOGIN")
function frame:OnEvent(event, arg1)
	if event == "ADDON_LOADED"
	then
		init()
	elseif event == 'TRADE_SKILL_SHOW'
	then
		flag = true
	elseif event == "TRADE_SKILL_UPDATE"
	then
		if flag
		then
			printSkills()
			flag = false
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

function checkVersion()
	-- local version = GetAddOnMetadata(addonName, "version")
	-- if (cache['version'] == nil) or (version ~= cache['version'])
	-- then
	-- 	print(version .. 'vs' , cache['version'])
	-- 	cache['version'] = version
	-- 	print(format("%s %s loaded.", prefix, version))
	-- end
	-- print(version)
end

function printSkills()
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
				printSkill(skillName, seconds)
			end
		end
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
		[0] = "|cff15ff00", -- READY
		[2 * 60 * 60] = "|cff00FF96", -- 7200
		[8 * 60 * 60] = "|cffFFF569", -- 14400
		-- [18 * 60 * 60] = "|cffffffff",
		[24 * 60 * 60] = "|cffFF7D0A", -- 86400
		[48 * 60 * 60] = "|cffC41F3B", -- 172800
		[99 * 60 * 60] = "|cff19180a",
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
			-- print(tostring(seconds) .. "s = " .. tostring(t) .. 'v' .. grad[t] .. 'xxxx|r')
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