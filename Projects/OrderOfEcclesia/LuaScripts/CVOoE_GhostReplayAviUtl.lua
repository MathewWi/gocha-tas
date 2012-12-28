-- wrapper for emulua gui functions for aviutl
-- the easiest way to draw emulua overlays in avi

-- Directory prefix
local root_dir = ""

-- Check engine and import library
if not aviutl then error("This script runs under lua for aviutl.") end
require "gd"

-- Copy pose_info from GhostReplay.lua and paste here
pose_info = { { "shanoadb.png", 128, 128, 64, 100 } }

-- a script generated by GhostReplay.lua
local drawcodefname = root_dir .. "aviutl_guidraw.lua"

-- emulua compatible gui functions
gui = {
yoffset = 192, -- DS bottom screen
opacityValue = 1.0,
opacity = function(level)
	gui.opacityValue = math.max(0.0, tonumber(level))
end;
transparency = function(trans)
	gui.opacityValue = (4.0 - trans) / 4.0
end;
parsecolor = function(color)
	if type(color) == "nil" then
		return nil
	elseif type(color) == "string" then
		local name = color:lower()
		if color:sub(1,1) == "#" then
			local val = tonumber(color:sub(2), 16)
			local missing = math.max(0, 9 - #color)
			val = val * math.pow(2, missing * 4)
			if missing >= 2 then val = val - (val%256) + 255 end
			return math.floor(val/0x1000000)%256, math.floor(val/0x10000)%256, math.floor(val/0x100)%256, val%256
		elseif name == "rand" then
			return math.random(0,255), math.random(0,255), math.random(0,255), 255
		else
			local s_colorMapping = {
				{ "white",     255, 255, 255, 255 },
				{ "black",       0,   0,   0, 255 },
				{ "clear",       0,   0,   0,   0 },
				{ "gray",      127, 127, 127, 255 },
				{ "grey",      127, 127, 127, 255 },
				{ "red",       255,   0,   0, 255 },
				{ "orange",    255, 127,   0, 255 },
				{ "yellow",    255, 255,   0, 255 },
				{ "chartreuse",127, 255,   0, 255 },
				{ "green",       0, 255,   0, 255 },
				{ "teal",        0, 255, 127, 255 },
				{ "cyan" ,       0, 255, 255, 255 },
				{ "blue",        0,   0, 255, 255 },
				{ "purple",    127,   0, 255, 255 },
				{ "magenta",   255,   0, 255, 255 }
			}
			for i, e in ipairs(s_colorMapping) do
				if name == e[1] then
					return e[2], e[3], e[4], e[5]
				end
			end
			error("unknown color " .. color)
		end
	elseif type(color) == "number" then
		return math.floor(color/0x1000000)%256, math.floor(color/0x10000)%256, math.floor(color/0x100)%256, color%256
	elseif type(color) == "table" then
		local r, g, b, a = 0, 0, 0, 255
		for k, v in pairs(color) do
			if k == 1 or k == "r" then
				r = v
			elseif k == 2 or k == "g" then
				g = v
			elseif k == 3 or k == "b" then
				b = v
			elseif k == 4 or k == "a" then
				a = v
			end
		end
		return r, g, b, a
	elseif type(color) == "function" then
		error("color function is not supported")
	else
		error("unknown color " .. tostring(color))
	end
end;
getpixel = function(x,y)
	y = y + gui.yoffset
	local yv, cb, cr = aviutl.get_pixel(aviutl.get_ycp_edit(), x, y)
	return aviutl.yc2rgb(yv, cb, cr)
end;
text = function(x,y,str,color,outlinecolor)
	y = y + gui.yoffset
	if color == nil then color = "white" end
	if outlinecolor == nil then outlinecolor = "black" end
	local drawtext = function(x,y,str,color)
		local r, g, b, a = gui.parsecolor(color)
		local yv, cb, cr = aviutl.rgb2yc(r, g, b)
		local av = math.floor((1.0-(a/255.0 * gui.opacityValue)) * 4096)
		av = math.max(0, math.min(4096, av))
		aviutl.draw_text(aviutl.get_ycp_edit(), x, y, str, r, g, b, av, "Arial", 12)
	end
	-- FIXME: transparent text
	drawtext(x-1,y-1,str,outlinecolor)
	drawtext(x+1,y-1,str,outlinecolor)
	drawtext(x-1,y+1,str,outlinecolor)
	drawtext(x+1,y+1,str,outlinecolor)
	drawtext(x,y,str,color)
end;
box = function(x1,y1,x2,y2,fillcolor,outlinecolor)
	y1, y2 = y1 + gui.yoffset, y2 + gui.yoffset
	if x1 > x2 then x1, x2 = x2, x1 end
	if y1 > y2 then y1, y2 = y2, y1 end

	if fillcolor == nil then fillcolor = { 255, 255, 255, 63 } end
	local rf, gf, bf, af = gui.parsecolor(fillcolor)
	local yvf, cbf, crf = aviutl.rgb2yc(rf, gf, bf)
	local avf = math.floor((1.0-(af/255.0 * gui.opacityValue)) * 4096)
	avf = math.max(0, math.min(4096, avf))
	if outlinecolor == nil then outlinecolor = { rf, gf, bf, 255 } end
	local ro, go, bo, ao = gui.parsecolor(outlinecolor)
	local yvo, cbo, cro = aviutl.rgb2yc(ro, go, bo)
	local avo = math.floor((1.0-(ao/255.0 * gui.opacityValue)) * 4096)
	avo = math.max(0, math.min(4096, avo))

	local ycp_edit = aviutl.get_ycp_edit()
	aviutl.line(ycp_edit, x1, y1, x2, y1, yvo, cbo, cro, avo)
	if y1 ~= y2 then
		aviutl.line(ycp_edit, x1, y1+1, x1, y2, yvo, cbo, cro, avo)
		if x1 ~= x2 then
			aviutl.line(ycp_edit, x2, y1+1, x2, y2, yvo, cbo, cro, avo)
			aviutl.line(ycp_edit, x1+1, y2, x2-1, y2, yvo, cbo, cro, avo)
		end
	end
	if (x2 - x1 >= 2) and (y2 - y1 >= 2) then
		aviutl.box(ycp_edit, x1+1, y1+1, x2-1, y2-1, yvf, cbf, crf, avf)
	end
end;
line = function(x1,y1,x2,y2,color,skipfirst)
	y1, y2 = y1 + gui.yoffset, y2 + gui.yoffset
	if color == nil then color = "white" end
	if skipfirst == nil then skipfirst = false end
	local r, g, b, a = gui.parsecolor(color)
	local yv, cb, cr = aviutl.rgb2yc(r, g, b)
	local av = math.floor((1.0-(a/255.0 * gui.opacityValue)) * 4096)
	av = math.max(0, math.min(4096, av))
	aviutl.line(aviutl.get_ycp_edit(), x1, y1, x2, y2, yv, cb, cr, av, skipfirst)
end;
pixel = function(x,y,color)
	y = y + gui.yoffset
	if color == nil then color = "white" end
	local r, g, b, a = gui.parsecolor(color)
	local yv, cb, cr = aviutl.rgb2yc(r, g, b)
	local av = math.floor((1.0-(a/255.0 * gui.opacityValue)) * 4096)
	av = math.max(0, math.min(4096, av))
	aviutl.set_pixel(aviutl.get_ycp_edit(), x, y, yv, cb, cr, av)
end;
gdoverlay = function(...)
	local arg = {...}
	local index = 1
	local x, y = 0, 0
	if type(arg[index]) == "number" then
		x, y = arg[index], arg[index+1]
		index = index + 2
	end
	y = y + gui.yoffset
	local gdStr = arg[index]
	index = index + 1
	local hasSrcRect = ((#arg - index + 1) > 1)
	local sx, sy, sw, sh = 0, 0, 0, 0
	if hasSrcRect then
		sx, sy, sw, sh = arg[index], arg[index+1], arg[index+2], arg[index+3]
		index = index + 4
	end
	local av = ((arg[index] ~= nil) and arg[index] or 1.0)
	av = math.floor((1.0-(av * gui.opacityValue)) * 4096)
	av = math.max(0, math.min(4096, av))
	if hasSrcRect then
		aviutl.gdoverlay(aviutl.get_ycp_edit(), x, y, gdStr, sx, sy, sw, sh, av)
	else
		aviutl.gdoverlay(aviutl.get_ycp_edit(), x, y, gdStr, av)
	end
end
}
-- alternative names
gui.readpixel = gui.getpixel
gui.drawtext = gui.text
gui.drawbox = gui.box
gui.rect = gui.box
gui.drawrect = gui.box
gui.drawline = gui.line
gui.setpixel = gui.pixel
gui.drawpixel = gui.pixel
gui.writepixel = gui.pixel
gui.drawimage = gui.gdoverlay
gui.image = gui.gdoverlay
-- special shorter names
OPAC = gui.opacity
PIXEL = gui.pixel
DOT = gui.pixel
LINE = gui.line
BOX = gui.box
IMG = gui.gdoverlay
-- and more
gui.gdoverlayclip = function(...)
	local arg = {...}
	local index = 1
	local x, y = 0, 0
	local screentype = "bottom"

	if type(arg[index]) == "string" and (arg[index] == "top" or arg[index] == "bottom" or arg[index] == "both") then
		screentype = arg[index]
		index = index + 1
	end
	if type(arg[index]) == "number" then
		x, y = arg[index], arg[index+1]
		index = index + 2
	end
	local gdStr = arg[index]
	index = index + 1
	local hasSrcRect = ((#arg - index + 1) > 1)
	local sx, sy, sw, sh = 0, 0, 65535, 65535
	if hasSrcRect then
		sx, sy, sw, sh = arg[index], arg[index+1], arg[index+2], arg[index+3]
		index = index + 4
	end
	local opacity = ((arg[index] ~= nil) and arg[index] or 1.0)

	-- screen clip
	if screentype == "top" then
		if y+sh > 0 then sh = -y end
	elseif screentype == "bottom" then
		if y < 0 then sy, sh, y = sy - y, sh + y, 0 end
	end

	gui.gdoverlay(x, y, gdStr, sx, sy, sw, sh, opacity)
end
IMGT = function(...) gui.gdoverlayclip("top", ...) end
IMGB = function(...) gui.gdoverlayclip("bottom", ...) end

-- return if an image is a truecolor one
gd.isTrueColor = function(im)
	if im == nil then return nil end
	local gdStr = im:gdStr()
	if gdStr == nil then return nil end
	return (gdStr:byte(2) == 254)
end
-- create a blank truecolor image
gd.createTrueColorBlank = function(x, y)
	local im = gd.createTrueColor(x, y)
	if im == nil then return nil end

	local trans = im:colorAllocateAlpha(255, 255, 255, 127)
	im:alphaBlending(false)
	im:filledRectangle(0, 0, im:sizeX() - 1, im:sizeY() - 1, trans)
	im:alphaBlending(true) -- TODO: restore the blending mode to default
	return im
end
-- return a converted image (source image won't be changed)
gd.convertToTrueColor = function(imsrc)
	if imsrc == nil then return nil end
	if gd.isTrueColor(imsrc) then return imsrc end

	local im = gd.createTrueColor(imsrc:sizeX(), imsrc:sizeY())
	if im == nil then return nil end

	im:alphaBlending(false)
	local trans = im:colorAllocateAlpha(255, 255, 255, 127)
	im:filledRectangle(0, 0, im:sizeX() - 1, im:sizeY() - 1, trans)
	im:copy(imsrc, 0, 0, 0, 0, im:sizeX(), im:sizeY())
	im:alphaBlending(true) -- TODO: set the mode which imsrc uses

	return im
end
-- flip an image about the vertical axis
gd.flipVertical = function(im)
	if im == nil then return nil end
	im:alphaBlending(false)
	for x = 0, im:sizeX() do
		for y = 0, math.floor(im:sizeY()/2) - 1 do
			local c1, c2 = im:getPixel(x, y), im:getPixel(x, im:sizeY()-1-y)
			im:setPixel(x, y, c2)
			im:setPixel(im:sizeX()-1-x, y, c1)
		end
	end
	im:alphaBlending(true) -- TODO: restore the mode
	return im
end
-- flip an image about the horizontal axis
gd.flipHorizontal = function(im)
	if im == nil then return nil end
	im:alphaBlending(false)
	for y = 0, im:sizeY() do
		for x = 0, math.floor(im:sizeX()/2) - 1 do
			local c1, c2 = im:getPixel(x, y), im:getPixel(im:sizeX()-1-x, y)
			im:setPixel(x, y, c2)
			im:setPixel(im:sizeX()-1-x, y, c1)
		end
	end
	im:alphaBlending(true) -- TODO: restore the mode
	return im
end
-- applies vertical and horizontal flip
gd.flipBoth = function(im)
	gd.flipVertical(im)
	gd.flipHorizontal(im)
	return im
end

-- load pose data
function read_pose(info)
	local im1 = gd.convertToTrueColor(gd.createFromPng(root_dir .. info[1]))

	if im1 == nil then error("Cannot load image: " .. info[1]) end

	local im1rev = gd.convertToTrueColor(gd.createFromPng(root_dir .. info[1]))
	gd.flipHorizontal(im1rev)

	return { im1:gdStr(), im1rev:gdStr() }
end
pose_data = {}
for i,info in ipairs(pose_info) do
	table.insert(pose_data, read_pose(info))
end

-- load draw script
function load_drawcode(filename)
	local f = 1
	local drawcode = {}

	-- compile each line
	for line in io.lines(filename) do
		drawcode[f] = assert(loadstring(line))
		f = f + 1
	end
	return drawcode
end
drawcode = load_drawcode(drawcodefname)

-- aviutl: process a frame
function func_proc()
	local f = aviutl.get_frame() + 1
	if drawcode[f] then drawcode[f]() end
end

-- aviutl: finalize script
function func_exit()
end
