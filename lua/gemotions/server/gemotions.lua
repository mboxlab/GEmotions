local antispam = {}

util.AddNetworkString("gemotions")
net.Receive("gemotions", function(_, ply)
	antispam[ply] = antispam[ply] or RealTime()
	if antispam[ply] > RealTime() then
		return
	end
	antispam[ply] = RealTime() + gemotions.emotecooldown
	local selected, pack = net.ReadUInt(7), net.ReadUInt(7)
	local packtbl = gemotions.GetPack(pack)
	if not packtbl or not packtbl[selected] then
		return
	end
	net.Start("gemotions")
	net.WriteUInt(selected, 7)
	net.WriteUInt(pack, 7) -- PACK ID
	net.WritePlayer(ply)
	net.Broadcast()
end)
