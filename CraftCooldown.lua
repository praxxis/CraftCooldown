local prefix = "|cff1784d1C|cffffa500CD|r: "

SLASH_CRAFTCOOLDOWN1 = '/ccd'
function SlashCmdList.CRAFTCOOLDOWN(msg)
	for a=0, GetNumTradeSkills(), 1
	do
		skillName, skillType, numAvailable, isExpanded, altVerb, numSkillUps = GetTradeSkillInfo(a);
		seconds,y = GetTradeSkillCooldown(a);
		if seconds and seconds > 0
		then
			cooldown = seconds / 60 / 60
			print(format("%s%s [%s]", prefix, skillName, disp_time(seconds)))
		end
	end
end

function disp_time(time)
	local days = floor(time/86400)
	local hours = floor(mod(time, 86400)/3600)
	local minutes = floor(mod(time,3600)/60)
	local seconds = floor(mod(time,60))
	return format("%dd %dh %dm %ds",days,hours,minutes,seconds)
end