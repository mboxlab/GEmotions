gemotions = gemotions or {}
local gemotions = gemotions
gemotions.emotecooldown = 1
gemotions.emotions = {}
gemotions.packages = {}
local table_insert = table.insert
if SERVER then
	local function AddFiles(path)
		local path = path .. "/"
		for _, name in ipairs(file.Find(path .. "*", "GAME")) do
			resource.AddSingleFile(string.format("%s%s", path, name))
		end
	end

	-- load resources
	AddFiles("materials/gemotions")
	AddFiles("sound/gemotions/ui")
end
function gemotions.RegisterEmote(pack, material, sound)
	if not pack or not material then
		return
	end
	if not gemotions.emotions[pack] then
		gemotions.emotions[pack] = { name = "" }
		table_insert(gemotions.packages, pack)
	end

	table_insert(gemotions.emotions[pack], {
		material = Material(material or ""),
		sound = sound or "",
		name = material:match("/%w+%."):sub(2, -2),
	})
	if SERVER then
		resource.AddSingleFile(string.format("materials/%s", material))
		resource.AddSingleFile(string.format("sound/%s", sound))
	end
end

function gemotions.RegisterPackage(pack, name, order)
	if not gemotions.emotions[pack] then
		gemotions.emotions[pack] = { name = name }

		if order then
			table_insert(gemotions.packages, order, pack)
		else
			table_insert(gemotions.packages, pack)
		end
	else
		gemotions.emotions[pack].name = name
	end
end

local emotions, packages = gemotions.emotions, gemotions.packages
function gemotions.GetPack(id)
	local pack = packages[id]
	if not pack then
		return
	end
	return emotions[pack]
end
if sdk and sdk.walker then
	sdk.walker.include("gemotions", nil, function()
		table.Empty(gemotions.emotions)
		table.Empty(gemotions.packages)
	end)
else
	local include, AddCSLuaFile, ipairs = include, AddCSLuaFile, ipairs
	local sidesfunc = {
		server = function(f)
			if SERVER then
				include(f)
			end
		end,

		shared = function(f)
			if SERVER then
				AddCSLuaFile(f)
			end

			include(f)
		end,

		client = function(f)
			if SERVER then
				AddCSLuaFile(f)
			else
				include(f)
			end
		end,
	}
	local insert, file_Find, type, next, string_Explode, string_GetPathFromFilename =
		table.insert, file.Find, type, next, string.Explode, string.GetPathFromFilename

	local function getSide(dir)
		local path = string_Explode("/", string_GetPathFromFilename(dir))
		local side = "shared"
		for i, v in ipairs(path) do
			if sidesfunc[v] then
				side = v
				break
			end
		end
		return side
	end
	local function includeFile(dir)
		local side = sidesfunc[getSide(dir)] or sidesfunc.shared
		side(dir)
	end

	local function FindRecursive(tbl, dir)
		local dirvalid = type(dir) == "string"
		local files, dirs = file_Find(dirvalid and dir .. "/*" or "*" or "LUA")
		local includedir = dirvalid and (dir .. "/") or ""

		for _, file in next, files do
			insert(tbl, includedir .. file)
		end
		for _, dir in next, dirs do
			FindRecursive(tbl, includedir .. dir)
		end
	end

	local function walk(root)
		local tbl = {}
		FindRecursive(tbl, root)
		return tbl
	end
	for k, v in next, walk("gemotions") do
		includeFile(v)
	end
end
