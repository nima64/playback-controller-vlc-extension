-- require('lib/jumpToTimeLib2')
info_videotags = {
	"Video resolution",
	"Color space",
	"Codec",
	"Frame rate"
}
info_audiotags = {
	"Channels", 
	"Sample rate",
	"Codec",
	"Bits per sample",
}
-- Globals ----
os_type = "linux"
has_saved = false
SYNC_FILE_NAME = "syncPointsV3"
IN_selected = false
OUT_selected = false
sync_file_location = nil
media_dir = nil
dir_files = {}
captions_list_tmp = {} -- made because entire list can't be looped(only selected can) 
medias = {}
in_out_time = {nil,nil}
streamInfo = nil
saveDir = nil 
mediaName = nil
syncTime = nil
delta = 0
media_fps = 30
time_format=2 -- 1, 2, 3, 4
---------------
function descriptor()
	return {
		title = "playback controller",
		version = "1.0",
		author = "",
		url = 'http://',
		shortdesc = "playback controller",
		description = "full description",
		capabilities = {"menu", "input-listener", "meta-listener", "playing-listener"}
	}
end
function activate()
	print("activated")
	jumpToTime = newJumpToTime()
	momentsDir = vlc.config.userdatadir()
	saveDir = vlc.config.userdatadir()
	sync_file_location = ("%s/%s.txt"):format(saveDir,SYNC_FILE_NAME)
	createDialog()
	jumpToTime.timeInput = time_txt_inp
	jumpToTime.jumpInput = jump_txt_inp
	jumpToTime.framesInput = frames_txt_inp
	jumpToTime.jump_selection = jump_selection
	jumpToTime.display_jumps()
	input = vlc.object.input()
	if input == nil then
		print("no media selected")
		close()
		return 
	end
	mediaName = vlc.input.item():name()
	loadMedia()
end

function loadMedia()
	medias = {} -- reset medias
	input = vlc.object.input()
	if input == nil then
		print("no media selected")
		close()
		return 
	end
	local plItem = vlc.input.item()
	media_dir = string.match(plItem:uri(),"^file://(.+/).+$")
	if os_type == "windows" then
		media_dir = string.match(plItem:uri(),"^file:///(.+/).+$")
	end
	media_fps = getFPS()
	mediaName = vlc.input.item():name()
	streamInfo = vlc.input.item():info()
	print("media name",mediaName)
	print("media check",medias[mediaName])
	--reset lists
	IN_selected = false
	OUT_selected = false
	media_dir_l:set_text(media_dir)
	unclap_check_box:set_checked(false)
	prodTitle_inp_txt:set_text("")
	scene_inp_txt:set_text("")
	slate_inp_txt:set_text("")
	slate_inp_txt:set_text("")
	jumpToTime.use_selected_click()
	----
	loadSyncPoints()
	display_OUT_l()
	display_IN_l()
	displayCaptions(captions_list)
	display_media_dir(dir_files_list)
	display_audio_video_tags(media_info_list)
end

function input_changed()
	loadMedia()
end

function meta_changed()
	-- delta = delta + (1/media_fps)
	-- if delta > (1/media_fps)*4 then
	-- 	-- print("hello world")
	-- 	-- if unclap_check_box:get_checked() then
	-- 	-- 	d:del_widget(clap_inp_txt)
	-- 	-- 	clap_inp_txt= d:add_("",4,row,1,1)
	-- 	-- 	-- clap_inp_txt:set_text("UNCLAPPED")
	-- 	-- end
	-- 	delta = 0
	-- end	

	-- print("META CHANGED")
end
function playing_changed()
	-- loadMedia()
end
function close()
	-- d:delete()
	vlc.deactivate()
end
function deactivate()
	if d ~= nil then
		d:delete()
	end
end
function createDialog()
	d = vlc.dialog("mmt and jt mashup")
	local row = 1
	d:add_label("Production title",1,row)
	prodTitle_inp_txt = d:add_text_input("",2,row,3,1);
	row = row + 1
	d:add_label("scene",1,row)
	d:add_label("slate",2,row)
	d:add_label("take",3,row)
	d:add_label("clap",4,row)
	row=row + 1
	scene_inp_txt = d:add_text_input("",1,row,1,1)
	slate_inp_txt = d:add_text_input("",2,row,1,1)
	take_inp_txt = d:add_text_input("",3,row,1,1)
	clap_inp_txt= d:add_text_input("",4,row,1,1)
	row = row +1
	confirm_btn = d:add_button("confirm",confirmClick,1,row)
	d:add_button("IN",IN_click,2,row)
	d:add_button("OUT",OUT_click,3,row)
	unclap_check_box = d:add_check_box("unclapped",true,4,row)
	row = row +1
	IN_l = d:add_label("",2,row)
	OUT_l = d:add_label("",3,row)
	row = row +1
	d:add_label("<b>Sync points for this media:</b>",1,row,2,1)
	d:add_label("<b>Files:</b>",3,row)
	d:add_label("<p style='text-align:right;'>Sort: <span style='color:blue;'>filename</span></p>",4,row)
	row = row +1
	captions_list = d:add_list(1,row,2,1)
	dir_files_list = d:add_list(3,row,2,1)
	row = row +1 
	d:add_button("Pause||>Play",vlc.playlist.pause,1,row)	
	d:add_button("Remove syncpoint",deleteSelected_Click(captions_list),2,row)	
	d:add_button("Open File",open_file_click(dir_files_list),3,row)
	d:add_button("Change DIR",change_dir_click(),4,row)
	row = row +1
	d:add_button("<<Backward",jumpToTime.backward_click,1,row)	
	d:add_button("Forward>>",jumpToTime.forward_click,2,row)	
	media_info_list = d:add_list(3,row,2,6)
	row = row + 1
	-- d:add_label("<center>jump length</center> ",1,row)
	--d:add_label("<center>jump length</center> ",1,row)
	d:add_button("Jump",jump_selected_click(captions_list),1,row)
	d:add_button("Use Selected",jumpToTime.use_selected_click,2,row)
	row = row + 1
	jump_txt_inp = d:add_text_input("",1,row)
	jump_selection = d:add_dropdown(2,row)
	row = row +1
	d:add_label(("<p style='text-align:right;'>%s</p>"):format("Frames"),1,row)
	frames_txt_inp = d:add_text_input("",2,row)
	row = row +1
	d:add_label(("<p style='text-align:right;'>%s</p>"):format("Time and frames"),1,row)
	d:add_text_input("",2,row)
	row = row +1
	d:add_label(("<p style='text-align:right;'>%s</p>"):format("Time"),1,row)
	time_txt_inp = d:add_text_input("",2,row)
	row = row +1
	d:add_button("Get time",jumpToTime.get_time_click,1,row)
	d:add_button("Set time",jumpToTime.set_time_click,2,row)
	media_dir_l = d:add_label("directoy yet to be display",3,row,2,1)
	media_dir_row = row
end
function change_dir_click()
	local change = false
	return function()
		change = not change
		if change then
			d:del_widget(media_dir_l)
			media_dir_txt_inp = d:add_text_input(media_dir,3,media_dir_row,2,1)
		else
			local newdir = media_dir_txt_inp:get_text()
			media_dir = dir_exists(newdir) and newdir or media_dir
			if media_dir:sub(-1,-1) ~= "/" then
				media_dir = media_dir .. "/"
			end
			display_media_dir(dir_files_list)
			d:del_widget(media_dir_txt_inp)
			media_dir_l = d:add_label(media_dir,3,media_dir_row,2,1)
		end
	end
end
function IN_click()
	IN_selected = not IN_selected
	-- if IN_selected then
		in_out_time[1] = IN_selected and vlc.var.get(input,"position") or nil
		medias[mediaName]["metas"][4] = in_out_time[1]
		-- medias[mediaName]["metas"][6] = in_out_time[2]
	-- end
	saveSyncPoints()
	display_IN_l()
	displayCaptions(captions_list)
end
function OUT_click()
	OUT_selected = not OUT_selected
	in_out_time[2] = OUT_selected and vlc.var.get(input,"position") or nil 
	medias[mediaName]["metas"][5] = in_out_time[2]
	saveSyncPoints()
	display_OUT_l()
	displayCaptions(captions_list)
end
function display_OUT_l()
	if OUT_selected then
		OUT_l:set_text("<p style='text-align:center;color:blue;'>OUT selected</p>")
		print(vlc.var.get(input,"position"))
	else
		OUT_l:set_text("")
	end
end
function display_IN_l()	
	if IN_selected then
		IN_l:set_text("<p style='text-align:center;color:blue;'>IN selected</p>")
		print(vlc.var.get(input,"position"))
	else
		IN_l:set_text("")
	end
end
function display_media_dir(list)
	list:clear()
	-- local files = {}
	dir_files = {}
	local files = vlc.io.readdir(media_dir)
	if not files then
		--list:add_value("couldn't find dir",1)
		print("Error: couldn't find dir ")
		return false
	end
	for i, f in pairs(files) do
		if (f ~= "." and f ~= "..") then
			dir_files[#dir_files+1] = f
		end
	end
	table.sort(dir_files)
	for i,f in pairs(dir_files) do 
			if medias[f] and next(medias[f]["captions"]) then
				f = "#" .. f
			end
		list:add_value(f,i)
	 end
	return true
end
function displayCaptions(list)
	list:clear()
	captions_list_tmp = {}
	local count = 1
	local newcap = ""
	local display_meta = function (metaNum) 
		if medias[mediaName]["metas"][metaNum] and (metaNum == 4 or metaNum == 5) then 
			local s = (metaNum == 4) and "IN" or "OUT"
			list:add_value(s,count)
			count = count +1
		end
	end
	display_meta(4)
	display_meta(5)
	for cap, v in pairs(medias[mediaName]["captions"]) do 
		local a,b,c,d = cap:match("scene:(.+)/slate:(.+)/take:(.+)/clap:(.+)/")
		newcap = ("%s-%s-%s-%s"):format(a,b,c,d)
		table.insert(captions_list_tmp,newcap)
		list:add_value(newcap,count)
		count = count + 1
	end
end
function display_audio_video_tags(list)
	list:clear()
	local addTags = function (stream,list)
		if stream then
			local whichTag = (stream["Type"] == "Video") and info_videotags or info_audiotags
			for _, tag in pairs(whichTag) do 
				if stream[tag] then
					list:add_value(tag.. " " .. stream[tag] )
				end
			end
			list:add_value("")
		end
	end
	addTags(streamInfo["Stream 0"],list)
	addTags(streamInfo["Stream 1"],list)
end
--Click Functions
function confirmClick()
	local title = prodTitle_inp_txt:get_text()
	local scene = scene_inp_txt:get_text()
	local slate = slate_inp_txt:get_text()
	local take = take_inp_txt:get_text()
	local clap = clap_inp_txt:get_text()
	local unclapChecked = unclap_check_box:get_checked()
	if scene == "" or slate == "" or take == "" or (clap == "" and not unclapChecked) then
		print("one field is empty")
		return 
	elseif unclapChecked then --none are empty except clap
		clap = "unclapped"
	end
	local caption = ("scene:%s/slate:%s/take:%s/clap:%s/"):format(
		scene,
		slate,
		take,
		clap
	)
	syncTime = vlc.var.get(input,"position")
	medias[mediaName]["captions"][caption] = syncTime
	medias[mediaName]["metas"][1] = vlc.var.get(input,"position")
	medias[mediaName]["metas"][2] = os.date("%d/%m/%Y")
	medias[mediaName]["metas"][3] = vlc.var.get(input,"time")
	medias[mediaName]["metas"][6] = title

	saveSyncPoints()
	displayCaptions(captions_list)
	display_media_dir(dir_files_list)
	--Reset States
	has_saved = true
	IN_selected = false
	OUT_selected = false
	in_out_time = {nil,nil}
	-- IN_l:set_text("") 
	-- OUT_l:set_text("") 
	scene_inp_txt:set_text("")
	slate_inp_txt:set_text("")
	take_inp_txt:set_text("")
	clap_inp_txt:set_text("")
end
function open_file_click(list)
	return function()
		local sel,_ = unpack(getSelected(list))
		if sel then
			if sel:len() > 2 and sel:sub(1,1) == "#" then
				sel = sel:sub(2,-1)
				print("opened synced"..sel)
			end
			local dir = (os_type == "windows") and media_dir:gsub("/","\\") or media_dir
			local uriGen = vlc.strings.make_uri(dir .. sel)
			local item = {path=uriGen}
			vlc.playlist.add({item})
		end
	end
end
function jump_selected_click(list)
	return function()
		local sel,inorout = unpack(getSelected(list))
		if sel == nil then
			print("invalid selection")
			return 
		end
		local a,b,c,d = sel:match("(.+)-(.+)-(.+)-(.+)")
		local cap = ("scene:%s/slate:%s/take:%s/clap:%s/"):format(a,b,c,d)
		local time = medias[mediaName]["captions"][cap]
		if inorout then
			if inorout == "IN" and medias[mediaName]["metas"][4] then
				local pos = medias[mediaName]["metas"][4]
				print("IN ",pos)
				vlc.var.set(input,"position",pos)
			elseif inorout == "OUT" and medias[mediaName]["metas"][5] then
				local pos = medias[mediaName]["metas"][5]
				vlc.var.set(input,"position",pos)
				print("OUT ",pos)
			end
		else
			local pos = medias[mediaName]["captions"][cap]
			vlc.var.set(input,"position",pos)
		end
	end
end
function deleteSelected_Click(list)
	return function()
		local sel,inorout = unpack(getSelected(list))
		if sel == nil then
			print("invalid selection")
			return 
		end
		local a,b,c,d = sel:match("(.+)-(.+)-(.+)-(.+)")
		local cap = ("scene:%s/slate:%s/take:%s/clap:%s/"):format(a,b,c,d)
		local time = medias[mediaName]["captions"][cap]
		print(inorout,sel)
		if inorout then --check if in and out was selected
			if inorout == "IN" then
				medias[mediaName]["in_outs"][cap][1] = nil
			elseif inorout == "OUT" then
				medias[mediaName]["in_outs"][cap][2] = nil
			end
		else
			medias[mediaName]["captions"][cap] = nil
			medias[mediaName]["in_outs"][cap] = nil
		end
		displayCaptions(captions_list)
		saveSyncPoints()
	end
end
function getSelected(list)-- returns first item selected
	local sel = nil
	--local inoutIdx = nil
	local inorout = nil
	for k, v in pairs(list:get_selection()) do 
		sel = v
		if v == "IN" or v== "OUT" then
			--inoutIdx = k
			inorout = v
			for k2,v2 in pairs(captions_list_tmp) do 
				if v2 ~= "IN" and v2 ~= "OUT" and k2 > k then
					sel = v2
					break
				end
			end
		end
		break
	end
	return {sel,inorout}
end
-- File loading/reading 
function saveSyncPoints()
	local f = getSyncFile("w")
	for mname, v in pairs(medias) do 
		local a,b,c,_in,_out,d = unpack(v["metas"],1,table.maxn(v["metas"]))
		local meta_data = ("%s~%s~%s~%s~IN:%s~OUT:%s~Title:%s"):format(mname,a,b,c,_in,_out,d)	
		meta_data = meta_data:gsub("nil","")
		f:write(meta_data.."\n")
		if v["captions"] ~= nil and next(v["captions"]) ~= nil then
			for cap, time in pairs(v["captions"]) do 
				print(cap,time)
				f:write(cap,"~",time,"*&")
			end
		else
			f:write("nil")
		end
		f:write("\n")
	end
	f:flush()
	f:close()
end
function loadSyncPoints()
	local f = getSyncFile("r")
	local mname,pos,date,time,_in,_out,title = nil,nil,nil,nil,nil,nil
	local count = 0
	local reset_media_meta = function (line)  
		mname,pos,date,time,_in,_out,title = line:match("(.+)~(.*)~(.*)~(.*)~(.*)~(.*)~(.*)")
		if (pos == "") then pos = nil end
		if (date == "") then date = nil end
		if (time == "") then time = nil end
		_in = _in:match("[^IN:].+") 
		_out =  _out:match("[^OUT:].+") 
		title = title:match("[^Title:].+") 
		-- print(mname,pos,date,time,_in,_out,title )
		medias[mname] = medias[mname] or {}
		medias[mname]["metas"] = {[1]=pos,[2]=date,[3]=time,[4]=_in,[5]=_out,[6]=title}
		medias[mname]["captions"] = {}
	end
	local reset_media_syncpoints = function(chunk)
		local cap,time = chunk:match("(.*)~(.*)")
		medias[mname]["captions"][cap] = time
	end
	for l in f:lines() do 
		if l ~= nil then
			if count%2 == 0 then
				reset_media_meta(l)
			elseif l ~= "nil" then
				local itr = l:gmatch("[^*&]+")
				for i in itr do 
					reset_media_syncpoints(i)
				end
			end
		end
		count = count +1
	end
	f:close()
	checkIsNewMedia()
end
function getSyncFile(mode) -- checks if file exists
	local f = io.open(sync_file_location,mode)
	if f == nil then
		local newF = io.open(sync_file_location,"w")
		newF:write("")
		newF:close()
		f = io.open(sync_file_location,mode)
	end
	return f
end
function checkIsNewMedia()
	print("media check2",medias[mediaName])
	if medias[mediaName] == nil then
		print("this media hasn't been saved")
		medias[mediaName] = {}
		medias[mediaName]["captions"] = {}
		medias[mediaName]["metas"] = {nil,nil,nil,nil,nil,nil}
	else
		if medias[mediaName]["metas"] and medias[mediaName]["metas"][6] then -- if media then set if has title
			title = medias[mediaName]["metas"][6]
			prodTitle_inp_txt:set_text(title)
		else
			print("NO title found")
		end
		if medias[mediaName]["metas"][4] then
			IN_selected = true
			display_IN_l()
		end
		if medias[mediaName]["metas"][5] then
			OUT_selected = true
			display_OUT_l()
		end
		has_saved = true
	end
end
function dir_exists(dir)
	if vlc.io.readdir(dir) then
		return true
	else
		return false
	end
end
--------------------
function newJumpToTime()
	time_format=2 -- 1, 2, 3, 4
	local this = {}
	this.timeInput = nil
	this.jumpInput = nil	
	this.framesInput = nil
	this.jump_selection = nil
	this._jumps = { {"1/FPS", "vlcfps"},{"2 sec", 2},{"20 sec", 20},{"1 min", "1:00"},{"5 min", "5:00"},{"10 min", "10:00"},{"1/2 sec", 0.5},{"1/x", "reciprocal"},{"1/23.976", 1/23.976},{"1/24", 1/24},{"1/25", 1/25},{"1/29.97", 1/29.97},{"1/30", 1/30},{"1/60", 1/60},}
	this.get_time_click = function()
		local input = vlc.object.input()
		displayPlayerTime(this.timeInput)
		local s = vlc.var.get(input,"time")/1000000
		print("time ",s*getFPS())
		this.framesInput:set_text(math.floor(s*getFPS()))
	end
	this.set_time_click = function()
		setPlayerTime(this.timeInput)
	end
	this.change_timeformat_click = function()
		changeTimeFormat(timeInput)
	end
	this.use_selected_click = function()
			print("jump slected")
			this.jumpSelected(this.jump_selection,this.jumpInput)
	end
	this.backward_click = function()
		clickJump(this.jumpInput,-1)
	end
	this.forward_click = function()
		clickJump(this.jumpInput,1)
	end
	this.get_frames_click = function()
		local input = vlc.object.input()
		local s = vlc.var.get(input,"time")/1000000
		print("time ",s*getFPS())
		this.framesInput:set_text(math.floor(s*getFPS()))
	end
	this.display_jumps = function()
		local list = this.jump_selection
		list:clear()
		for i, v in pairs(this._jumps) do 
			list:add_value(v[1],i)
		end
	end
	this.jumpSelected = function(targeDropDwn,targetInp)
		local selected_jump = this._jumps[targeDropDwn:get_value()][2]
		if selected_jump=="reciprocal" then
			local number = string.gsub(targetInp:get_text(),",",".") -- various decimal separators
			number = tonumber(number)
			if number==nil or number==0 then
				return
			else
				targetInp:set_text(1/number)
			end
		elseif selected_jump=="vlcfps" then
			if vlc.input.item() then
				for k0,v0 in pairs(vlc.input.item():info()) do
					for k1,v1 in pairs(v0) do
						if tonumber(v1) then targetInp:set_text(1/v1) return end
					end
				end
			end
			targetInp:set_text(0)
		else
			targetInp:set_text(selected_jump)
		end
	end
	return this
end

function getFPS()
	if vlc.input.item() then
		local videoInfo = (vlc.input.item():info())["Stream 0"]
		if videoInfo then
			return videoInfo["Frame rate"]
		end
	end
end
function clickJump(obj,dir)
	local input = vlc.object.input()
	if input then vlc.var.set(input,"time-offset",dir * String2time(obj:get_text())) end
end

function changeTimeFormat(obj)
	time_format_next()
	local time = String2time(obj:get_text())
	obj:set_text(Time2string(time))
end

function time_format_next()
	time_format = (time_format%4)+1; print(time_format)	
end

function setPlayerTime(obj)
	local inp = vlc.object.input()
	local txtInp_val = obj:get_text()
	if inp then
		print(txtInp_val)
		vlc.var.set(inp,"time",String2time(txtInp_val))
	end
end

function displayPlayerTime(obj)
	local inp = vlc.object.input()
	local time = vlc.var.get(inp,"time")
	if inp then
		obj:set_text(Time2string(time))
	end
end
function click_Jump(obj,dir)
	local input=vlc.object.input()
	if input then vlc.var.set(input, "time-offset", direction * String2time(textinput_jump:get_text())) end
end
function Time2string(timestamp)
	timestamp=timestamp/1000000 -- VLC 3 microseconds fix
	if not time_format then time_format=3 end
	if time_format==3 then -- H:m:s,ms
		return string.format("%02d:%02d:%06.3f", math.floor(timestamp/3600), math.floor(timestamp/60)%60, timestamp%60):gsub("%.",",")
	elseif time_format==2 then -- M:s,ms
		return string.format("%02d:%06.3f", math.floor(timestamp/60), timestamp%60):gsub("%.",",")
	elseif time_format==1 then -- S,ms
		return string.format("%5.3f", timestamp):gsub("%.",",")
	elseif time_format==4 then -- D/h:m:s,ms
		return string.format("%d/%02d:%02d:%06.3f", math.floor(timestamp/(24*60*60)), math.floor(timestamp/(60*60))%24, math.floor(timestamp/60)%60, timestamp%60):gsub("%.",",")
	end
end

function String2time(timestring)
	timestring=string.gsub(timestring,",",".") -- various decimal separators
	local tt=ReverseTable(SplitString(timestring,"[:/%*%-%+]")) -- delimiters :/*-+
	return ((tonumber(tt[1]) or 0) + (tonumber(tt[2]) or 0)*60 + (tonumber(tt[3]) or 0)*3600 + (tonumber(tt[4]) or 0)*24*3600)*1000000 -- VLC 3 microseconds fix
end
function SplitString(s, d) -- string, delimiter pattern
	local t={}
	local i=1
	local ss, j, k
	local b=false
	while true do
		j,k = string.find(s,d,i)
		if j then
			ss=string.sub(s,i,j-1)
			i=k+1
		else
			ss=string.sub(s,i)
			b=true
		end
		table.insert(t, ss)
		if b then break end
	end
	return t
end

function ReverseTable(t) -- table
	local rt={}
	local n=#t
	for i, v in ipairs(t) do
		rt[n-i+1]=v
	end
	return rt
end

-------------------------
function doNothing()
end
function shallow_copy(t) 
	local t2 = {}
	for k,v in pairs(t) do
	   t2[k] = v
	end
	return t2
end
function printInfo()
	local streamInfo = (vlc.input.item()):streamInfo()
	for i, v in pairs(streamInfo) do 
		print("\n"..i)
		for k,w in pairs(v) do 
			print(k,w)
		end
	end
end
function format_time(s)
  local hours = s/(60*60)
  s= s%(60*60)
  local minutes =s/60 
  local seconds = s%60
  return string.format("%02d:%02d:%02d",hours,minutes,seconds)
end
