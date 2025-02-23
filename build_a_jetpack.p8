pico-8 cartridge // http://www.pico-8.com
version 42
__lua__
-- build a jetpack
-- ◆ aymeri100.fr

max_lvl=8

-- game data
gd={
	lvl=0,
	money=0,
	paused=false,
	ending=false,
	mf=10,
	totaltime=0,
	started=false,
}

local musics={
	shop=16,
	surface=34,
	sect_a=35,
	sect_b=0,
	sect_c=24,
	sect_d=12,
	sky=48,
	danger=15,
	last=56,
	ending=57,
}

local sfxs={
	swim=31,
	gameover=30,
	pickup=32,
	error=33,
	buy=35,
	click=37,
	click2=38,
	damage=39,
	oxy_regen=40,
	jetpack=41,
}

-- fishes

function _init()
	i_raft()
	i_player()
	gen_objects()
	i_effects()
	
	music(musics.surface)
	
	u_balloon()
end




function _draw()
	if gd.lvl <= -4 do
		cls(1)
		d_stars_bg()
	else
		cls(12)
	end

	
	if _last_lvl() do
		d_star()
	end

	
	if gd.lvl==-1 do
		d_low_clouds()
	end
	
	if gd.lvl < 0 and not _last_lvl() do
		d_balloon()
	end
	
	if gd.lvl == 0 do
		d_clouds()
		d_waves()
		d_raft()
	elseif gd.lvl>0 do
		d_walls()
	end
	if gd.lvl>=0 do
		d_jumpc()
		d_bubbles()
	end
	
	
	if not gd.started do
		ta("build a",48,12,7)
		ta("jetpack",48,22,9)
		
		local col=11
		if flr(time()*6)%2 == 1 do
			col=7
		end
		to("press ❎ to start",32,80,col)
		print("1/100 aymeri100.fr",32,120,0)
		return
	end
	
	if not gd.ending do
		d_objects()
	end
	d_player()
	
	d_ui()
	if gd.paused do
		ta("paused",52,32,7)
	end
end

function _last_lvl()
	return gd.lvl==-8
end


function _update60()
	if not gd.started do
		if btnp(❎) do
			gd.started=true
		end
		u_effects()
		u_raft()
		return
	end
	if btnp(🅾️) and not p.of and not gd.ending do
		gd.paused = not gd.paused
	end
	if gd.paused do
		return
	end
	if gd.lvl<=-4 do
		u_stars_bg()
	end
	if _last_lvl() do
		u_star()
	end
	if gd.lvl == -1 do
		u_effects()
	end
	if gd.lvl == 0 do
		u_effects()
		u_raft()
	end
	if gd.lvl>=0 do
		u_bubbles()
		u_jumpc()
	end

	u_player()
	if not gd.ending do
		u_objects()
	 u_music()
	end
	u_ui()
	
	if gd.ending do
		return
	end
	if p.y > 128 do
		p.y=0
		gd.lvl+=1
		_level_changed()
	elseif p.y < 0 do
		p.y=128
		gd.lvl-=1
		_level_changed()
	end
end


local cm=-1
function set_music(id)
	if cm ~= id do
		music(id)
	end
	cm=id
end

function u_music()
	if low_oxy() do
		set_music(musics.danger)
	elseif _last_lvl() do
		set_music(musics.last)
	elseif gd.lvl < 0 do
		set_music(musics.sky)
	elseif gd.lvl == 0 do
		set_music(musics.surface)
	elseif gd.lvl <= 2 do
		set_music(musics.sect_a)
	elseif gd.lvl <= 4 do
		set_music(musics.sect_b)
	elseif gd.lvl <= 6 do
		set_music(musics.sect_c)
	elseif gd.lvl <= 8 do
		set_music(musics.sect_d)
	end
end

function _level_changed()
	bubbles={}
	jumpc={}
	gd.lvl=max(min(gd.lvl, max_lvl), -8)
	c_stars_bg()
	if gd.lvl<0 do
		u_balloon()
	end
	if p.dead do
		music(-1)
		sfx(sfxs.gameover)
		gd.lvl=0
		r_player()
	else
		u_music()
	end
end


function sea_lvl()
	if gd.lvl==0 do
		return 56
	end
	return 0
end
-->8
-- player

p={}



local oxy_lvls={
	0.015,
	0.08,
	0.15,
	0.30,
	0.60,
	0.8,
	1.4,
	2.0,
	3.0,
}

function i_player()
	p={
		x=60,
		y=40,
		cm=true,
		fx=false, -- flip x
		vx=0,     -- vel x
		vy=0,     -- vel y
		iw=false, -- in water
		of=false, -- on floor
		inv={},   -- inventory
		inv_s=10, -- inventory size
		oxy=100,
		dead=false,
		jpow=0, -- jetpack power
		jmpow=0,
		-- equipments
		moxy=100,
		max_prs=1, -- max pression
		pr=10,     -- pickup radius
		swimspeed=0
	}
end

function low_oxy()
	return (olps()*60*8 > p.oxy) and p.iw and p.cm
end

-- reset
function r_player()
	p.x=64
	p.y=40
	p.inv={}
	p.dead=false
	p.oxy=100
end

function d_player()
	local pspr=1
	if p.dead do
		pspr+=16
	end
	spr(pspr,p.x,p.y,1,1,p.fx)
	local jx=p.x-4
	if p.fx do
		jx+=8
	end
	if p.jmpow>0 do
		if j_on() or gd.ending do
			spr(19,jx,p.y+7+cos(time()*10.0)*0.75,1,1,p.fx)
		end
		spr(3,jx,p.y,1,1,p.fx)
	end
	local x,y=p_center()
	if m.cm==2 and m.sb==5 do
		circ(x,y,p.pr+cos(time())*1.5,10)
	end
end

function p_center()
	return p.x+4,p.y+4
end

local upp=false

function j_on()
	return btn(⬆️) and p.cm and not p.iw and p.jpow>0
end

function u_player()
	if gd.lvl==0 do
		if p.y > sea_lvl() do
			p.iw=true
			p.of=false
		else
			p.iw=false
			local rx,ry,rw,rh=raft_coll()
			if(p.y+8>=ry and
						p.x+4>rx and
						p.x<rx+rw)then
				p.of=true
				p.y=ry-8
			else
				p.of=false
			end
		end
	elseif gd.lvl>0 do
		p.iw=true
	end
	
	if j_on() do
			upp = true
			if p.vy>-1.0 do
					p.vy=p.vy-0.35
					p.jpow-=1*0.95
			end
			sfx(sfxs.jetpack)
	end
	if not btn(⬆️) and upp do
		upp = false
		p.vy=0
	end
	if p.of do
		p.jpow=min(p.jpow+p.jmpow*0.01,p.jmpow)
		p.vy=0
		if btnp(⬆️) and p.cm do
				p.vy=-2
		end
	elseif p.iw do
		if btnp(⬆️) do
				add_jumpc(p_center())
				p.vy=-1.8-(p.swimspeed*0.2)
				sfx(sfxs.swim)
		end
		printh(p.y)
		p.vy=min(p.vy+0.2,0.8)
	else
		p.vy=min(p.vy+0.15,4.0)
	end
	if gd.ending and p.vy<64 do
		p.vx=0
		p.vy=-1
	elseif p.dead do
		p.vx=0
		p.vy=-1
	else
		if p.cm do
			if btn(⬅️) and p.x>6 do
				p.vx=max(p.vx-0.2,-1)
				p.fx=true
			elseif btn(➡️) and p.x<116 do
				p.vx=min(p.vx+0.2,1)
				p.fx=false
			end
		end
		p.vx*=0.75
	end
	
	

	p.x+=p.vx
	p.y+=p.vy
	
	if gd.lvl==max_lvl and p.y>108 do
		p.y=108
	end
	
	----------------
	if p.iw do
		p.oxy-=olps()
	else
		local noxy=min(p.oxy+p.moxy/200,p.moxy)
		if p.oxy~=noxy do
			sfx(sfxs.oxy_regen)
		end
		p.oxy=noxy
	end
	if p.oxy <= 0 do
		p.dead = true
	end
end



function olps()
	if p.iw do
		local lvl_v=oxy_lvls[gd.lvl+1]
		if gd.lvl==p.max_prs do
			return lvl_v
		elseif gd.lvl<p.max_prs do
			return lvl_v*0.5
		else
			return lvl_v*3.0
		end
	end
	return 0
end
-->8
-- raft

r={}
local lg=6 -- log size

function i_raft()
	r={
		lvl=0,
		s=5, -- size
		y=58,
		storage={0,0,0,0},
		b={
			radar=0,
			jetpack=0,
			net=0,
			statue=0,
		},
	}
end

function d_raft()
	local sx=64-(r.s*lg)/2
	for i=1,r.s do
		local oy=cos((time()+i*0.15))*0.2
		spr(16,sx+(i-1)*lg,r.y+oy)
	end
	spr(192,64-8,r.y-16,2,2)
	if r.b.jetpack>0 do
		spr(224,62,r.y-16,2,2)
	end
	if r.b.radar>0 do
		spr(226,42,r.y-16,2,2,true)
	end
	if r.b.statue==1 do
		spr(194,72,r.y-16,2,2)
	end
	
	--local x,y,w,h=raft_coll()
	--rect(x,y,x+w,y+h,3)
end

function raft_coll()
	local sx=64-(r.s*lg)/2
	return sx,r.y,r.s*lg,8
end

function u_raft()
end
-->8
-- objects

local o_data={
-- name
       	      -- spr id
	               -- spr size
	                 -- speed
	                     -- price
	                      -- min lvl
	                   	  --max lvl
	                         --hstl


--------- [resources] ---------

{"wood",      48,1,1, 0,  1,4,0,{3,6,8,4}},
{"rock",      49,1,1, 0,  3,5,0,{9,14,12}},
{"strings",   50,1,1, 0,  2,4,0,{11,13,9}},
{"gold",      51,1,1, 0,  6,8,0,{7,12,22}},
     
--------- [ fishes ] ----------
{"tuna",      0, 2,1, 2,  0,2,0,{10,5,1}},
{"cod",       2, 2,2, 8,  0,3,0,{1,5,10,5}},
{"pollock",   4, 2,3, 12, 2,4,0,{5,10,5}},
{"mackerel",  34,1,10,15, 2,4,0,{5,10,5}},
{"flounder",  6, 2,10,25, 3,4,0,{5,10}},
{"mahi",      10,2,10,35, 4,6,0,{5,10,5}},
{"halibut",   12,2,10,50, 5,7,0,{5,10,5}},
{"snapper",   8, 2,10,60, 6,7,0,{5,10}},
{"grouper",   36,2,10,75, 7,8,0,{5,10,7}},
{"marlin",    74,2,10,100,7,8,0,{5,10,7}},
{"pufferfish",14,2,5, 60, 6,8,0 ,{5,10,5}},

----- [ hostiles fishes ] -----
{"spikefin",  42,2,2, 15, 2,5,1,{3,8,10,5}},
{"barracuda", 38,2,4, 70,  5,7,1,{5,10,5}},
{"shark",     40,2,5,250,7,8,1 ,{5,10}},

------------ [sky] ------------
{"spacefish",46, 2,2, 60,-4,-3,0,{5,5}},
{"skyfish",35, 1,2, 40,-3,-2,0,{10,5}},
{"cloudswim",44, 2,2, 15,-2,-1,0,{5,10}},

}

c={
	name=   1,
	s_id=   2,
	s_size= 3,
	speed=  4,
	price=  5,
	min_lvl=6,
	max_lvl=7,
	hostile=8,
	rarity= 9,
}


o={} -- objects

local max_spawn_timer=500
local spawn_timer=max_spawn_timer

function get_possible_objects(lvl)
	local p_id={} -- possible objects
	for i,obj in ipairs(o_data) do
		local o_min = obj[c.min_lvl]
		local o_max = obj[c.max_lvl]

		if lvl>=o_min and lvl<=o_max do
				local blvl=lvl
				local rarity=obj[c.rarity][blvl-o_min+1]
				add(p_id,{
					id=i,
					rarity=rarity
				})
		end
	end
	return p_id
end

function gen_objects()
	for lvl=-4,max_lvl do
		o[lvl] = {}
		for i=1,5 do
			add_random_object(lvl)
		end
	end
end

function obj_spawn_timer()
	for lvl=-4,max_lvl do
		if #o[lvl] < gd.mf do
			add_random_object(lvl)
		end
	end
end

function add_random_object(lvl)
	local p_id=get_possible_objects(lvl)
	local miny = 0
	
	if lvl == 0 do
		miny=56
	end
	local y=rnd(104-miny)+miny
	local dir=sgn(rnd(20)-10)
	local x=rnd(96)-48
	if dir == 1 do
		x+=128
	end
	
	local sum=0
	for _,v in ipairs(p_id) do
		sum+=v.rarity
	end
	

	
	local rnd_sum=flr(rnd(sum))

	local rsum=0
	local rnd_id=1
	for _,v in ipairs(p_id) do
		rsum+=v.rarity
		if rnd_sum<rsum do
			rnd_id=v.id
			break
		end
		
	end
	
	add(o[lvl],{
		id=rnd_id,
		x=x,
		y=y,
		do_b=_oi({id=rnd_id},c.price)>0,
		bt=rnd(60)+30,
		dir=sgn(rnd(20)-10),
		ydir=(rnd(100)-50)/100,
		ht=60*5+rnd(60*5), -- hostile timer
		pt=0, -- pickup timer
	})
end


function d_objects()
	for obj in all(o[gd.lvl]) do
		local s_size=_oi(obj,c.s_size)
		spr(
			_oi(obj,c.s_id)+64,
			obj.x, obj.y,
			s_size, s_size,
			sgn(obj.dir)==-1
		)
		if _obj_host(obj) do
			local x,y=obj_middle(obj)
			if (time()*100)%100<50 do
				spr(6,x-4,y-16)
			end
			
		end
--		circ(
--		obj.x+s_size*4,
--		obj.y+s_size*4,
--		p.pr,10)
	end
end

function u_objects()
	for obj in all(o[gd.lvl]) do
		local speed=_oi(obj,c.speed)/10
		if _oi(obj,c.hostile) == 1 and obj.ht>0 do
			local dx,dy=normalize(p.x-obj.x,p.y-obj.y)
			obj.x+=dx*speed
			obj.y+=dy*speed
			obj.ht-=1
			if dx<0 do
				obj.dir=-1
			elseif dx>0 do
				obj.dir=1
			end
		else
			obj.x+=speed*obj.dir
			obj.x%=128
			obj.y+=cos(time())*0.05
			if obj.y<sea_lvl() or obj.y>100 do
				obj.ydir=-obj.ydir
			end
			obj.y+=obj.ydir*speed
		end

		
		if obj.do_b do
			obj.bt-=1
			if obj.bt <= 0 do
				obj.bt=rnd(300)+300
				add_b(obj_middle(obj))
			end
		end
		
		obj.pt-=1
		local s_size=_oi(obj,c.s_size)
		
		local rad=p.pr
		if _obj_host(obj) do
			rad=10
		end
		if dist(
						p.x+4,p.y+4,
						obj.x+s_size*4,
						obj.y+s_size*4)<rad and
						obj.pt <=0 do
				
				if obj_picked(obj) do
					del(o[gd.lvl],obj)
				else
					obj.pt=60
				end
		end
	end
	spawn_timer-=1
	if spawn_timer < 0 do
		obj_spawn_timer()
		spawn_timer=max_spawn_timer+rnd(60)-30
	end
end

function obj_middle(obj)
	local s_size=_oi(obj,c.s_size)
	return obj.x+s_size*4, obj.y+s_size*4
end

-- obj info
function _oi(obj,col)
	return o_data[obj.id][col]
end

function _obj_host(obj)
	return (_oi(obj,c.hostile)==1
	and obj.ht>0)
end


function obj_picked(obj)
 if _obj_host(obj) do
 	p.oxy-=min(p.moxy*0.25,1000)
 	obj.ht=0
 	sfx(sfxs.damage)
 	return false
 end
	local id=obj.id
	if #p.inv < p.inv_s do
		sfx(sfxs.pickup)
		add_n(
			_oi(obj,c.name),
			tostr(_oi(obj,c.price)) .. "$",
			_oi(obj,c.s_id)+64,
			_oi(obj,c.s_size)
		)
		add(p.inv,id)
		if gd.lvl<0 do
			p.vy=-3.0
		end
		return true
	end
	sfx(sfxs.error)
	return false
end
-->8
-- ui
-- menu


function _dr(bi,y,sx,ex)
	spr(bi,sx,y)
	for i=2,13 do
		spr(bi+1,i*8,y)
	end
	spr(bi+2,ex,y)
end

function get_prs_icon()
	local prs_spr=35
	if not p.iw do
		prs_spr=32
	elseif gd.lvl==p.max_prs do
		prs_spr=34
	elseif gd.lvl<p.max_prs do
		prs_spr=33
	end
	return prs_spr
end

function d_player_info()
	local tc_inv=7
	if #p.inv == p.inv_s do
		tc_inv=8
	end
	local txt_inv=tostr(#p.inv)
	if p.inv_s < 9999 do
		txt_inv=txt_inv.."/"..p.inv_s
	end

	local num_items=min(5,#p.inv)
	if m.open do
		num_items=min(15,#p.inv)
	end
	for i=1,num_items do
		local index=#p.inv-num_items+i
		local id=p.inv[index]
		local spr_id=_oi(
		{id=id},c.s_id)
		local spr_size=_oi(
		{id=id},c.s_size)
			spr(
			spr_id+64,
			32+i*4-spr_size*4,
			m.y+cos(time()+i*0.4)-spr_size*4,
			spr_size,spr_size )
			i+=1
	end
	to(
		txt_inv,
	 12,m.y-2,tc_inv
	)
	if m.open do
		to(gd.money .. "$",
		110-#tostr(gd.money)*4,m.y-2,7)
	else
		local txt=""
		local bspr=151
		if p.iw or p.jmpow==0 do
			txt=tostr(max(flr(p.oxy),0))
		else
			bspr=153
			txt=tostr(max(flr(p.jpow),0))
		end
		spr(bspr,62-#txt*2,m.y-3)
		to(txt,72-#txt*2,m.y-2,7)

		spr(get_prs_icon(),108,m.y-3)
		
		local lvltxt=gd.lvl
		if gd.lvl < 0 do
			lvltxt="sky"
		end
		if gd.lvl==max_lvl do
			lvltxt="max"
		end
		lvltxt=tostr(lvltxt)
		spr(152,96-#lvltxt*4,m.y-4)
		to(lvltxt,106-#lvltxt*4,m.y-2,7)
	end
end

local notifs={}

function add_n(text,info,s_id,s_size)
	if info=="0$" do
		info=""
	end
	add(notifs,{
		text=text,
		info=info,
		s_id=s_id,
		s_size=s_size,
		time=120,
	})
end

function d_notifs()
	for k,n in ipairs(notifs) do
		local s_id=gk(n,"s_id",-1)
		local s_size=gk(n,"s_size",1)
		local text=gk(n,"text","")
		local info=gk(n,"info","")
		local w=16+(#text+#n.info)*4+4
		local y=4+(k-1)*12
		local px,py=p_center()
		if px>4 and px<w and py>y and py<y+16 do
		else
			print(info,4+#text*4,y+3,9)		
			to(text,2,y+3,7)	
		end

	end
end

function u_notifs()
	for k,n in ipairs(notifs) do
		n.time-=1
		if n.time <= 0 do
			del(notifs,n)
		end
	end
end

function d_ui()
	if gd.ending do
		ta("congratulations!",32,80,10)
		local tt=gd.totaltime
		local t="total time: "
		t = t .. tostr(flr(tt/60)) .. "m "
		t = t .. tostr(flr(tt%60)) .. "s"
		
		ta(t,32,96,7)
	 return
	end
	if low_oxy() do
		for x=0,3+cos(time())*1.8 do
			for y=0,3+sin(time())*1.8 do
				rect(x,y,127-x,127-y,8)
			end
		end
	end
	_dr(128,m.y,8,112)
	for i=1,5 do
		_dr(144,m.y+i*8,8,112)
	end
	
	d_notifs()
	if m.cm==3 do
		d_mat_list(r.storage,16,m.y-2)
	else
		d_player_info()
	end
	if m.open do
		d_menu()
	end
	
	if low_oxy() do
		for x=0,3+cos(time())*1.8 do
			for y=0,3+sin(time())*1.8 do
				rect(x,y,127-x,127-y,8)
			end
		end
		d_warning("low oxygen: rise to surface",80)
	end
	if gd.lvl>p.max_prs do
		d_warning("caution: high pressure zone",96)

	end
	

end

function d_warning(txt,y)
	local _,py=p_center()
	if py<y-4 or py>y+16+4 do
		for x=0,8 do
			spr(22,x*16,y,2,2)
		end
		to(txt,10,y+4,7)
	else
		print(txt,10,y+4,1)
	end

end



function u_ui()
	if p.of and btnp(🅾️) do
		sfx(sfxs.click2)
		if m.open and m.cm~= 1 do
			set_menu(1)
			return
		end
		m.open=not m.open
		p.cm=not p.cm
		if m.open do
			music(musics.shop)
			set_menu(1)
		else
			music(musics.surface)
		end
	end
	
	u_notifs()
	u_menu()
end
-->8
-- effects

local clouds={}
local waves={}
bubbles={}
local b={}
local stars={}

-- jump circles
jumpc={}

function u_balloon()
	if gd.lvl < 0 do
		b={
			x=rnd(128-48)+24,
			y=rnd(128-56)+24,
		}
	end
end

function i_effects()
	-- layer 1
	for i=1,60 do
		add(clouds,{
			x=rnd(127),
			y=rnd(20)+28,
			r=rnd(10)+10,
			spd=rnd(10)+5,
			col=7,
		})
	end
	-- layer 2
	for i=1,60 do
		add(clouds,{
			x=rnd(127+64)-64,
			y=rnd(10)+48,
			r=rnd(7)+5,
			spd=rnd(5)+2,
			col=6,
		})
	end
	
	for i=1,16 do
		add(waves,{
			x=64,
			y=56+i,
			w=40+rnd(20)+(16-i)*3,
			spd=rnd(16),
		})
	end
end

function c_stars_bg()
stars={}
	for i=1,20 do
		add(stars,{
			x=rnd(128),
			y=rnd(128),
			s=10+rnd(4),
		})
	end
end

function u_stars_bg()
	for s in all(stars) do
		s.y+=1
		if s.y>136 do
			s.y=-8
		end
	end
end

function d_stars_bg()
	for s in all(stars) do
		spr(s.s,s.x,s.y)
	end
end

function d_low_clouds()
	for cl in all(clouds) do
		circfill(cl.x,cl.y+72,cl.r,cl.col)
	end
end

function d_jumpc()
	for c in all(jumpc) do
		local d=c.r/2
		oval(c.x-d,c.y-d/2,c.x+d,c.y+d/2,6)
	end
end

function add_jumpc(x,y)
	add(jumpc,{
		x=x,
		y=y,
		r=10,
	})
end

function u_jumpc()
	for c in all(jumpc) do
		if flr(time()*60)%2==0 do
			c.r-=1
			if c.r<= 0 do
				del(jumpc,c)
			end
		end
	end
end

function d_clouds()
	for cl in all(clouds) do
		circfill(cl.x,cl.y,cl.r,cl.col)
	end
end

function d_balloon()
	b.y+=cos(time())*0.12
	spr(36,b.x-8,b.y,2,2)
	local txt=(8+gd.lvl).."km to go"
	rectfill(
		b.x-#txt*2-2,
		b.y+16,
		b.x+#txt*2+1,
		b.y+24,4)
	rect(
		b.x-#txt*2-2,
		b.y+16,
		b.x+#txt*2+1,
		b.y+24,2)
	print(txt,b.x-#txt*2,b.y+18,7)
end

function _dlc(x,y,w,c)
	line(x-w/2,y,x+w/2,y,c)
end

function d_waves()
	rectfill(0,57,128,80,12)
	for w in all(waves) do
		if w.y < 60 do
			_dlc(w.x,w.y,w.w+16,1)
		else
			_dlc(w.x,w.y,w.w,7)
			_dlc(w.x+w.w/4,w.y,w.w/11,12)
			_dlc(w.x-w.w/4,w.y,w.w/9,12)
		end

	end
end

function u_effects()
	for cl in all(clouds) do
		cl.x+=cl.spd*0.005
		
		cl.y+=cos(time())*cl.spd*0.002
		
		if cl.x-cl.r>128 do
			cl.x=-cl.r
		end
	end
	
	for w in all(waves) do
		w.w+=cos(time()*w.spd*0.05)*0.05
	end
end

function u_bubbles()
	for b in all(bubbles) do
		b.i-=1
		if b.i <= 0 and b.r < 3 do
			b.r+=1
			b.i=(rnd(4)+4)*b.r
		end
		b.x+=cos(time())*0.5
		b.y-=0.75
		
		if b.y<sea_lvl()+8 do
			b.r-=1
			if b.r==-1 do
				del(bubbles,b)
			end
		end
	end
end

function d_bubbles()
	for b in all(bubbles) do
		circ(b.x,b.y,b.r,13)
	end
end

function add_b(x,y)
	add(bubbles,{
		x=x,
		y=y,
		i=rnd(8)+8,
		r=0,
	})
end

function d_walls()
	for y=0,8 do
		spr(4,0,y*16,2,2)
		spr(4,112,y*16,2,2,true)
	end
end

function ppx()
	return (p.x-64)/16
end

function ppy()
	return (p.y-64)/64
end

-->8
-- star

local s={
	x=64,
	y=32,
}

function d_star()
	spr(24,s.x-8,s.y-8+cos(time())*4,2,2)
end

function u_star()
	if dist(s.x,s.y,p.x,p.y) < 8 do
		if gd.ending do
			return
		end
		gd.ending=true
		p.cm=false
		gd.totaltime=time()
		p.vy=-2
		set_music(musics.ending)
	end
end
-->8
-- menu

local menus={
	{
		{
name="sell",
icon=1,
hint="gain money with fishes",
		},
		{
name="shop",
icon=3,
hint="buy new gears",
		},
		{
name="raft",
icon=4,
hint="upgrade your raft",
		},
		{
name="credits",
icon=17,
		},
	},
	{
		{
icon=5,
name="diving suit",
hint="+ prs. resistance",
lvl=0,
max_lvl=8,
price=9,
base_price=9,
		},
		{
icon=6,
name="o2 mask",
hint="x2 max oxygen",
lvl=0,
max_lvl=8,
base_price=10,
price=10,
		},
		{
name="backpack",
icon=7,
hint="+10 storage",
lvl=0,
max_lvl=7,
base_price=12,
price=12,
		},
		{
name="fins",
icon=8,
hint="swim faster",
lvl=0,
max_lvl=7,
base_price=13,
price=13,
		},
		{
name="magnet",
icon=9,
hint="bigger pickup rad.",
lvl=0,
max_lvl=8,
base_price=11,
price=11,
		},
	},
	{
		{
name="expand",
lvl=0,
icon=11,
max_lvl=3,
hint="unlock new things",
costs={
	{1,1,0,0},
	{5,3,0,0},
	{10,5,0,0},
},
		},
{
name="jetpack",
lvl=0,
icon=10,
max_lvl=3,
disabled=true,
hint="to the moon!!",
costs={
	{3,5, 0, 0},
	{0,5, 10,0},
	{0,25,25,25},
		},
},
		{
name="radar",
lvl=0,
icon=12,
max_lvl=5,
disabled=true,
hint="more fishes",
costs={
	{3,0, 3, 0},
	{0,0, 5,0},
	{0,3, 8,0},
	{0,5,6,1},
	{0,8,6,3},
},
},
		{
name="gold statue",
disabled=true,
hint="you're the king",
lvl=0,
max_lvl=1,
costs={
	{0,0,0,25}
},
		},
	},
	{
		{
			icon=18,
			name="aymeri",
		},
		{
			icon=19,
			name="website",
			hint="aymeri100.fr",
		},
		{
			icon=20,
			name="1/100",
			hint="- september 2024",
		}
	}
}

m={
	y=120,
	open=false,
	cm=1,
	sb=1,
	bo=1,
	old_sb=1,
}

function _mtw()
	local tw=0
	for id,mbtn in ipairs(menus[m.cm]) do
		tw+=#gk(mbtn,"name","")*4+4
	end
	return tw
end



function d_mat_list_tw(val)
 local tw=0
 for k,v in ipairs(val) do
  if v>0 do
   tw+=11+#tostr(v)*4
  end
 end
 return tw
end

-- values
function d_mat_list(val,x,y,col)
	local ox=0
	for k,v in ipairs(val) do
		if v>0 do
			
			spr(111+k,x+ox,y-1)
			
			local tc=7
			if col do
				if v <= r.storage[k] do
					tc=11
				else
					tc=8
				end
			end
			to(v,x+ox+10,y,tc)
			ox+=11+#tostr(v)*4
		end
	end
end

function d_menu()
	local bx=16
	if _mtw() > 96 do
			if m.sb>1 do
				spr(
					131,
					10+cos(time()),
					m.y+8
				)
			end
			spr(
					132,
					110+cos(time()),
					m.y+8
				)
	end
	for k,mbtn in ipairs(menus[m.cm]) do
		w=#gk(mbtn,"name","")*4+4
	
		if k>=m.sb and bx+w<108 do
			bx+=d_mbtn(
				mbtn,
				bx+4,0,
				m.sb==k
			)+4
		end
	end
	local mbtn=_gsmbtn()
	local hint=gk(mbtn,"hint","")
	if hint != "" do
		rectfill(
			12,m.y+30,116,m.y+40,5
		)
		print(hint,14,m.y+32,7)
		local price=gk(mbtn,"price",-1)
		local costs=gk(mbtn,"costs",-1)
		if price >= 0 do
			local tc=8
			if gd.money >= price do
				tc=11
			end
			to(price .. "$",100,m.y+32,tc)
		elseif costs ~= -1 do
			local lvl=gk(mbtn,"lvl",1)
			local cost=costs[lvl+1]
			local tw=d_mat_list_tw(cost)
			d_mat_list(
			cost,116-tw,m.y+32,true)
		end
	end
end

-- get menu button
function _gsmbtn()
	return menus[m.cm][m.sb]
end



function _sell_all()
	for obj in all(p.inv) do
		local prc=_oi({id=obj},c.price)
		if prc>0 do
			gd.money+=prc
		else
			r.storage[obj]+=1
		end
		
	end
	p.inv={}
end

function u_menu()
	if m.open do
		m.y=max(m.y-4,80)
		if btnp(❎) do
			_mbtn_p()
		end
		if btnp(⬅️) do
			m.sb-=1
			if m.sb<1 do
				m.sb=#menus[m.cm]
			end
			sfx(sfxs.click)
		elseif btnp(➡️) do
			m.sb+=1
			if m.sb>#menus[m.cm] do
				m.sb=1
			end
			sfx(sfxs.click)
		end
	else
	 m.y=min(m.y+4,120)
	end
end

function set_menu(nm)
 m.cm=nm
 if nm == 1 do
 	m.sb=m.old_sb
 	m.old_sb=1
 else
		m.sb=1
	end
	sfx(sfxs.click2)
end

function _mbtn_p()
	if m.cm == 1 do
		if m.sb == 1 do
				_sell_all()
		else
				m.old_sb=m.sb
				set_menu(m.sb)
		end
	elseif m.cm==2 do
		local mbtn=menus[m.cm][m.sb]
		local name=gk(mbtn,"name","")
		local price=gk(mbtn,"price",-1)
		if price>=0 do
			if btnmax(mbtn) do
				sfx(sfxs.error)
				return
			end
			if gd.money>=price do
				gd.money-=price
				mbtn.lvl+=1
				if btnmax(mbtn) do
					mbtn.price=-1
				else
					mbtn.price=flr(
mbtn.base_price*2.2^(mbtn.lvl))
----------
				end
				if name=="diving suit" do
					p.max_prs+=1
				elseif name=="o2 mask" do
					p.moxy*=2
				elseif name=="backpack" do
					if btnmax(mbtn) do
						p.inv_s=9999
					elseif mbtn.max_lvl-1==mbtn.lvl do
						mbtn.hint="infinite inventory"
					else
						p.inv_s+=10
					end
				elseif name=="fins" do
					p.swimspeed+=1
				elseif name=="magnet" do
					p.pr+=2
				end
				sfx(sfxs.buy)
			else
				sfx(sfxs.error)
			end
		end
	elseif m.cm==3 do
		local mbtn=menus[m.cm][m.sb]
		if mbtn.disabled do
			sfx(sfxs.error)
			return
		end
		local name=gk(mbtn,"name","")
		local costs=gk(mbtn,"costs",-1)
		local cost=costs[mbtn.lvl+1]
		
		if btnmax(mbtn) do
			sfx(sfxs.error)
			return
		end
		
		-- check if p has engh rsc
		for k,v in ipairs(cost) do
			if r.storage[k]<v do
				sfx(sfxs.error)
				return
			end
		end
		
		-- remove rsc from storage
		for k,v in ipairs(cost) do
			r.storage[k]-=v
		end
		
		mbtn.lvl+=1
		if name=="expand" do
			r.s+=1
			menus[m.cm][2].disabled=mbtn.lvl<1
			menus[m.cm][3].disabled=mbtn.lvl<2
			menus[m.cm][4].disabled=mbtn.lvl<3
			
		elseif name=="radar" do
			gd.mf+=1
			r.b[name]+=1
		elseif name=="jetpack" do
			if p.jmpow==0 do
				p.jmpow=100
			else
				p.jmpow*=2
			end
			r.b[name]+=1
		elseif name=="gold statue" do
			r.b["statue"]+=1
		else
			r.b[name]+=1
		end
		sfx(sfxs.buy)
		
	end
end


-- s_id = sprite id
-- h = hovered
function d_mbtn(mbtn,x,s_id,h)
	local txt=gk(mbtn,"name","")
	local lvl=gk(mbtn,"lvl",-1)
	local max_lvl=gk(mbtn,"max_lvl",-2)
	local price=gk(mbtn,"price",-1)
	local icon=gk(mbtn,"icon",0)
	local d=gk(mbtn,"disabled",false)
	local w=#txt*4+4
	
	if lvl ~= -1 do
		w=max(w,32)
	end
	
	local y=m.y+4
	if h do
		y+=2
		rect(x-1,y-1,x+w+1,y+21,6)
	end
	if d do
		rectfill(x,y,x+w,y+20,5)
	elseif h do
		rectfill(x,y,x+w,y+20,10)
		rect(x-1,y-1,x+w+1,y+21,9)

	else
		rectfill(x,y,x+w,y+20,7)
		rect(x,y,x+w,y+20,6)
		rect(x,y,x+w,y+19,6)
	end
	if lvl >= 0 do
		local lvl_txt=lvl .. "/" .. max_lvl
		if btnmax(mbtn) do
			lvl_txt="max"
		end
		print(lvl_txt,
		x+w-1-#tostr(lvl_txt)*4,
		y+3,3)
	end
	spr(160+icon,x+1,y+1)
	if h do
		ta(txt,x+2,y+12,7)
	else
		print(txt,x+2,y+12,0)
	end
	return w
end

function btnmax(obj)
	return gk(obj,"lvl",-1) == gk(obj,"max_lvl",-2)
end
-->8
-- utils

function normalize(vx,vy)
 local m=sqrt(vx*vx+vy*vy)
 if m==0 then
  return 0,0
 end
 return vx/m, vy/m
end

-- text outline
function to(txt,x,y,c)
	for ox=-1,1 do
		for oy=-1,2 do
				print(txt,x+ox,y+oy,0)
		end
	end
	print(txt,x,y,c)
end

function ta(txt,x,y,c)
	local i=0
	for ch=1,#txt do
		local ty=y+flr(cos(time()+ch*0.125)*1)
		to(txt[ch],x+i*4,ty,c)
		i+=1
	end
end

-- get key
function gk(obj,key,def)
	if obj==nil or obj[key]==nil do
		return def
	end
	return obj[key]
end

function dist(x1,y1,x2,y2)
 local dx=x1-x2
 local dy=y1-y2
 return sqrt(dx*dx+dy*dy)
end
__gfx__
00000000005555000000000000111000cccccccccd00000000222200000000000000000000000000000000000000000000000000000000000000000000000000
0000000005aaaa500000000001111500ccccccccccd0000000288200000000000000000000000000000000000000000000000000000700000000000000000000
007007005aaaaaa50002200011dd1000ccccccdddcd0000000288200000000000000000000000000000000000007700000700070000000000000000000000000
000770005aa5a5a5002e72001dd11500ccccddcccddd000000288200000000000000000000000000000770000077770000070700070007000000000000000000
000770005aa5a5a50228e2201ddd1000cccdcccccccd000000288200000000000000000000000000000770000067760000000000000000000000000000000000
0070070059aaaa950292292011111000cccccccccccd000000222200000000000000000000000000000000000006600000070700000700000000000000000000
000000000599995002a99a2014414100ccccccccddcd000000288200000000000000000000000000000000000000000000700070000000000000000000000000
000000000055550002aaaa2040040400cccccccdccd0000000222200000000000000000000000000000000000000000000000000000000000000000000000000
0022220000555500000000008aaaa980cccccddcccd0000011999911119999110000000440000000000000000000000000000000000000000000000000000000
02ffff2005888850000000008aa9a800cccddcccccd0000019999111199991110000004ff4000000000000000000000000000000000000000000000000000000
0f2222f0588888850000000089989800ccdcccccccd000008888888888888888000004faaf400000000000000000000000000000000000000000000000000000
02299220588585850000000008808000cccccccddcd000008888888888888888000004aaaa400000000000000000000000000000000000000000000000000000
02944920588888850000000000000000cccccddccdd00000888888888888888844444aaaaaa44444000000000000000000000000000000000000000000000000
02444420528888250000000000000000ccccdccccd00000088888888888888884fffaaaaaaaafff4000000000000000000000000000000000000000000000000
00244200052222500000000000000000cccdcccccd00000088888888888888884aaaaaaaaaaaaaa4000000000000000000000000000000000000000000000000
00022000005555000000000000000000cccccccccd000000888888888888888804aaaaaaaaaaaa40000000000000000000000000000000000000000000000000
0011110000111100002222000002200000000022220000008888888888888888004aaaaaaaaaa400000000000000000000000000000000000000000000000000
015555100133331002aaaa20000220000000228dd82200008888888888888888004aaaaaaaaaa400000000000000000000000000000000000000000000000000
15555551133333312aa99aa2002882000002d88dd88d200088888888888888880049aaaaaaaa9400000000000000000000000000000000000000000000000000
1556655113333b312aa99aa200288200002d888dd888d20088888888888888880499aa9999aa9940000000000000000000000000000000000000000000000000
1556655113b3b3312aaaaaa202288220002d88dddd88d2001199991111999911049aa994499aa940000000000000000000000000000000000000000000000000
05555551133b33312aa99aa202222220002d88dddd88d20019999111199991114999994004999994000000000000000000000000000000000000000000000000
015555100133331002aaaa2022288222002d88dddd88d20000000000000000004999440000449994000000000000000000000000000000000000000000000000
001111000011110000222200222222220002d88dd88d200000000000000000004444000000004444000000000000000000000000000000000000000000000000
000000000000000000000000000000000002d88dd88d200000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000288dd882000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000028dd820000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000222200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000200200000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000002222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000002444420000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002222000000
00000000010000000002222022000000000222000000000000000000000000000000002222000000000000000000000000000000110000000000002999200000
000011101c10000000029992992000000002dd20022000000002220022200000000002449920000000000001110000000001100144100000000220229a920000
00001cc1ccc1000000002ff22ff2000000002dd22dd20000000288228882000000002244499200000001111ddd100000000141144441000000029299aaa92000
000001ccc5cc10000002ffffff5f20000002eeeddd5d200000002eeeee5820000002944444542000000133d333d1000000014444445410000002a9aaaa5a2000
000001dddddd100000029999999920000002666eeeee200000002888eeee2000000294444444200000001bbbbb5b100000012222222210000002ffffaaaa2000
00001dd1ddd10000000024422442000000002662266200000002882288820000000022444992000000001bbbbbbb100000012112222100000002f2ffffff2000
000011101d10000000024442442000000002662002200000000222002220000000000244992000000001331333110000000110012210000000022022fff20000
00000000010000000002222022000000000222000000000000000000000000000000002222000000000011011100000000000000110000000000002fff200000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000002222000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000001110000022200000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000
00000000000000001cc111102ee22220000000000000000000000000000000000000000100000000000220028200220000000000000000000000000000000000
000000000000000001ccc5c102eee5e2000000000000000000000000000000000000000110000000000282228202820000000000000000000000000000000000
000000000000000001666661026666620000000111100000011100000000000000000001c1000000000288eeee28200000055550550000000022000222200000
0000000000000000166111102662222000110115d551100001cc10000111110001100001cc11000044422eeeeee200000005666566500000002d202288820000
00000000000000001110000022200000015d1dddddddd11001ccc1111cccd1001cc1011ddccc11004994eeeeeeee20000000577557650000005d8288ee882000
0000000000000000000000000000000015dd55d55dd11dd1001cccccc8cd100001cc11dccccccc100492eeeeee8e220000057777775c5000005dd8eeee588200
0000200000011000000044000000000015dd55d55dd51dd1001cccccccd10000001cccccccc8ccc10492eeeeee878820000577cccccc5000005dddddeeee8200
00024200011661000004ff400022220016dddddddd6666610017777777dd1000001ddcccccccc771499477eee777220000005cc55cc50000005dd5ddddddd200
00242220156666100049f4f402aaaa200166166666677110017771111777d10001dd11cc7777771044422777777200000005ccd5dd500000005d5055ddd55000
0242244215666651049f9ff42aa77aa2001101167771100001771000011111001dd1001777711100000288777728200000055550550000000055000555500000
29444442155665514ff9f94029aaaa92000000011110000001110000000000001110000111100000000282228202820000000000000000000000000000000000
294444421d5555d14f4f9400029aa920000000000000000000000000000000000000000000000000000220028200220000000000000000000000000000000000
0222222001dddd1004ff400000299200000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000
00000000001111100044000000022000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5dddddddddddddddddddddd500000600006000001dddd11dd11dd11dd11dddd10000000000000000000000000000000000000000000000000000000000000000
d1111111111111111111111d00006600006600001dddd11dd11dd11dd11dddd10000000000000000000000000000000000000000000000000000000000000000
d1111111111111111111111d00066600006660001ddd11dd11dd11dd11ddddd10000000000000000000000000000000000000000000000000000000000000000
d1111111111111111111111d006666000066660001dd11dd11dd11dd11dddd100000000000000000000000000000000000000000000000000000000000000000
d1111111111111111111111d00666600006666000011111111111111111111000000000000000000000000111000000000000000000000000000000000000000
d1111111111111111111111d00066600006660000000000000000000000000000000000000000000111001cc1100000000000000000000000000000000000000
d1111111111111111111111d000066000066000000000000000000000000000000000000000000001dc11ccccc11000000000000000000000000000000000000
d1111111111111111111111d000006000060000000000000000000000000000000000000000000001ddcccccc5cc111000000000000000000000000000000000
d1111111111111111111111d00000000000000001ddddddddddddddd00111100002220000008800001dddcccccccccc100000000000000000000000000000000
d1111111111111111111111d00000000000000001ddddddddddddddd01cccc10002e20000000880057ddddc77777711000000000000000000000000000000000
d1111111111111111111111d00000000000000001ddddddddddddddd1c1111c1002e200000088800577777777777500000000000000000000000000000000000
d1111111111111111111111d00000000000000001ddddddddddddddd1c1771c1222e222000889880555555577555000000000000000000000000000000000000
d1111111111111111111111d00000000000000001ddddddddddddddd1c1071c12e2e2e200899a980000000575000000000000000000000000000000000000000
d1111111111111111111111d00000000000000001ddddddddddddddd1c1111c102eee200089aa980000000550000000000000000000000000000000000000000
d1111111111111111111111d0000000000000000111ddddddddddddd01cccc10002e200000899800000000000000000000000000000000000000000000000000
d1111111111111111111111d00000000000000000011111111111111001111000002000000088000000000000000000000000000000000000000000000000000
00000000000110000009900088ff88ff004000000cc00cc02420000000001100000000000110011000111000bb0bb0bb00111100000000000000000000000000
00000000001331000009900088ff88ff04946000011dd11024200000000999400001111018811cc101111500b000000b0133bb10000000000000000000000000
0000000001bbbb100009900088ff88ff04997600111dd1112411011000045904001111d118811cc111dd100000333300133bbbb1000000000000000000000000
0000000001b331000999999020200202049477601011110121c61c6109944904001dd1dc166116611dd11500b000330b1353bb31000000000000000000000000
0000000001bbbb100099990022000022049976005011110521c61c619999440401cddc1c166116611ddd10003003030313533531000000000000000000000000
0000000000133b1000099000400000040494600000d55d0021cc1cc19999940401cddc1c15511551111110000030030013355331000000000000000000000000
0000000001bbbb100900009040000004449444440011110002111110955944041ccddcc115566551144141003000000301333310000000000000000000000000
00000000001331000999999044444044044444400050050000011100099444401cdccdc101555510400404003303303300111100000000000000000000000000
0000000000ccc0000008800000dddd00025225200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000c111c00008888000d0dd0d0285885820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c11711c000888800d0c00c0d288888820000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d11111d000088000ddd00ddd577777750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000d11711d00000000010dddd01571171750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000000d171d000088880010c00c01571171750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000ddd0000888888001011010577777750000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000888888000111100055555500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00555000000000000055000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0d666d000000000005aa555555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01ddd1066660000005995aaaaa500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00111267777600000055aaaaaaa50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0024467777776000005aa5aaa5aa5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0024467777776000005aa5aaa5aa5000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0024467777776000005aaaaaaaaa5500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0024227666676000005aa55555a5aa50000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00242760000660000059aa555aa59950000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002426000000000000059aaaaa955500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00242000000000000000599999500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00242000000000000222255555222220000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00242000000000000299999999999920000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
002420000000000002aaaaaaaaaaaa20000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
02242200000000002999999999999992000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
20242020000000002aaaaaaaaaaaaaa2000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000cccccccc0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000c555511c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000c5bbbb1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000200200000000000c5bbbb1c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000222220000000000cc533331c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000424420000000000c6666611c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000222220000000000c6666111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000444440000000000c5551111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000040040000000000c5551111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000040040000000000c5551111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000244442000000000c5551111c0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc77777cc77c77c77c77ccc77777cccccccc777cccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc770077c77c77c77c77ccc770077cccccc77777ccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc77cc77c77c77c77c77ccc77cc77ccccc7700077cccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc77777cc77c77c77c77ccc77cc77ccccc77ccc77cccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc770077c77c77c77c77ccc77cc77ccccc7777777cccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc777776c77777c77c7777c777776ccccc7766677cccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc666660c66666c66c6666c666660ccccc6600066cccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc00000cc00000c00c0000c00000cccccc00ccc00cccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccaaaaaaacaaaaacaaaaaacaaaaaccccaaaaccccaaaacaaccaaccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc9999aa9caa999c99aa99caa99aaccaa99aaccaa999caacaa9ccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccc0000aa0caa000c00aa00caa00aacaa9009aacaa000caaaa90ccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccdddddcaaccaaaaccccaacccaaccaacaa0cc0aacaaccccaaaa0cccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccdddddddaadcaa99ccddaadddaaaaa9daaccccaadaaccccaaaacddddcccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccddddaaadaaddaa00ddddaaddd999990daaaaaaaadaaddddaa9aadddddccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccddddd9aaaa9ddaaaaadddaaddd99000ddaa9999aad99999daa09aaddddccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccddddd099990dd99999ddd99ddd99ddddd99000099d09999d99d099ddccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccdddddd0000ddd00000ddc00ccc00ccccc00ccdd00dd0000d00dd00ccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccdddddddddddddccccccccccccccccccccccccccdddddddddcccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccddddddccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777cccccccc777
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777cccccccccccccccccc7777777777777ccccc7777
ccccccccccccccccccccccccccccccccccc77777777777777ccccccccccccccccccccccccccccc7777777777777ccccccccccccc77777777777777777ccc7777
ccccccccccccccccccccccccccccccc777777777777777777777ccccccccccccccccccccccccc77777777777777777ccccccccc7777777777777777777777777
ccccccccccccccccccccccccccccc7777777777777777777777777ccccccccc777777ccccccc77777777777777777777cccccc77777777777777777777777777
7777777777cccccccccccccccccc777777777777777777777777777ccccc7777777777ccccc77777777777777777777777ccc777777777777777777777777777
77777777777777ccccccccccccc777777777777777777777777777777cc777777777777cc7777777777777777777777777777777777777777777777777777777
7777777777777777777777ccc7777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777722777766666777777777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777777222277767766666677777777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777772222227767777776666666777777777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777777777777772222226667777777777776666667777777777777777777777777777777777777777
77777777777777777777777777777777777777777777777777666677777772222222677777777777777777766777777777777777777777777777777777777777
77766666777777777777777777777777777766666666777766666667777772222222677777777777777777666677777777777777777777777777777777777777
77666666677777777777777777777777766666666666666666666666777762222226677777777777777666677666666666777777777777777777777777777777
76666666667777777777777777777776666666666666666666666666677662222226677777777777766677766666666666666777777766667777777777777777
66666666666777666666666777777766666666666666666666666666666662222266777777777766667777666666666666666677777666666666677777777777
66666666666776666666666677777666666666666666666666666666666662222266777777666666666776666666666666666667776666666666666677777777
66666666666766666666666667776666666666666666666666666666666662222226776666666666666666666666666666666666766666666666666666777776
66666666666666666666666666766666666666666666666666666666666662222226666666666666666666666666666666666666666666666666666666667766
66666666666666666666666666666666666666666666666666666666666662222266666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666222266666666666666666666666666666666666666666666666666666666666666
66666666666666666666666666666666666666666666666666666666666666222266666666611111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111111222211122111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111155555552124422111cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5aaaaa552444442cccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc5aaaaaa5544444422cccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc599aaa9554fffff442ccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccc777777777777777777cccccccccccc22222ccc2559999955f44455555555cccccccccccccc77777777777777cccccccccccccccccccc
cccc7777777777777777777777777777777777777777777cc2444442c2445599995224555aaaaaa55777777777777777777777777777777777777ccccccccccc
77777777777777777777777777777777777777777222222c2444444422445555555445555aaaaaaa5577777777777777cccccccccccccccccccccccccccccccc
77777777777777777777777ccccccccccccccccc244444424444444ff42f4555554455555999aaa95555cccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccc24444444424444ff44f424222224555995559999955555ccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccc222222cc244444fffff244f4444444222222555a9119555555599555ccccccccccccccccccccccccccccccc77777777777
ccccccccccccccccccccccccccccc24444442c24444f44444f2f4444444442222455aa5119999911999a5522ccccccccccccccccccccccccc777777777777777
cccccccccccccccccccccccccccc24444444422444f4444444424444444442222555aa511999911199aa5554227777777777777777ccccccccccccc777777777
ccccccccccccc77777777777777724444fffff424f4444444444244444444222255aaa55aaaaa555aaaaa554442777777777777777cccccccccccccccccccccc
ccccccccccc777777777777777722444f44444ff2f4444444444424444442222255aaa55aaaaa55aaaaaa55444422ccccccccccccccccccccccccccccccccccc
7777777777777777777777777772244f44444444424444444444442444442222255aaa55aaaaa55aaaaaa55444fff2cccccccccccccccccccccccccccccccccc
777777777777777777777777777224f444444444442444444444444244422222255aaaaaaaaaaaaaaaaaa5544f444f22cccccccccccccccccccccccccccccccc
ccccccccc777777777777777777224f444444444442444444444444424422222255aaaaaaaaaaaaaaaaaa554f44444442ccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccc222f44444444444424444444444444222222225599aaaaaaaaaaaaaa9955f44444444422ccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccc2224f44444444444424444444444444244444455599aaaaaaaaaaaa995554444444444442cccccccccccccccccccccccccccc
ccccccccccccccccccccccccccc2222f444444444444424444444444444244444455999aaaaaaaaa9999552444444444442222cccccccccccccccccccccccccc
ccccccccccccccccccccccccccc2222244444444444444244444444444442444445559999aaaaa99999555422444444422222222cccccccccccccccccccccccc
ccccccccccccccccccccccccccc722222444444444444442444444444444422444455599999999999955544442444442222244222ccccccccccccccccccccccc
cccccccccccccccccccccccccccc722224444444444444442444444444444442444455559999999955554444442444222244444422cccccccccccccccccccccc
cccccccccccccccccccccccccccc722222444444444444444244444444444444244444555555555555544444444224222444444442cccccccccccccccccccccc
cccccccccccccccccccccccccccc7722222444444444444444244444444444444244f44455555555544444444222222244422224422ccccccccccccccccccccc
ccccccccccccccccccccccccccccc77222224444444444444442444444444fffff2f444444444444244444442222222244224424422ccccccccccccccccccccc
ccccccccccccccccccccccccccccc7772222444444444444444244444444f44444424444444444444244444222444222442442244227cccccccccccccccccccc
cccccccccccccccccccccccccccccc77222224444444444444442444444f444444442444444444422224442224444422442222444227cccccccccccccccccccc
ccccccccccccccccccccccccccccccc77222224444444fffffff424444f4444444444244444442222222222244224442444224442277cccccccccccccccccccc
cccccccccccccccccccccccccccccccc772222444444f4444444ff244f44444444444424444422244442222442222442244444422277cccccccccccccccccccc
ccccccccccccccccccccccccccccccccc7722224444f444444444442f444444444444442444222444444222442444242244444222777cccccccccccccccccccc
ccccccccccccccccccccccccccccccccc772222244f4444444444444244444444442222224422442222442244244424222222222777ccccccccccccccccccccc
cccccccccccccccccccccccccccccccccc7722222f4444444444444442444444422222222222442222224422442224422222227777cccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccc772222f444444444444444424444422222222222244244442442244224422277777777ccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccc72222944444444444222222244422224444422224422442244222444422277777777cccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccc7722292444444442222222224442224444444222244222224422222222277777ccccccccccc111c11ccccccccccc
ccccccccccccccccccccccccccccccccccccc772292444444422222222222422244422244422244422244227722222777ccccccccccccc1ccc11c11ccccccccc
ccccccccccccccccccccccccccccccccccccc77729224444422224444422222224422222442222444444222777777777cccccccc111c11cccccc5c1ccccccccc
cccccccccccccccccccccccccccccccccccccc77729224442222444444422222242244422422222444422277777777cccccccccc1cc1c11cccccdd1ccccccccc
cccccccccccccccccccccccccccccccccccccc777722224422244422224422222422444224222222222227777ccccccccccccccc1cccccccccdd111ccccccccc
ccccccccccccccccccccccccccccccccccccccc7772222422244422222244222244224224422277222277777cccccccccccccccc1cccddcddddd1ccccccccccc
cccccccccccccccccccccccccccccccccccccccc77722222224422444224422222442224422277777777777ccccccccccccccccc1c11ddd1dd11cccccccccccc
ccccccccccccccccccccccccccccccccccccccccc77722222242244444244222222444442222777777777cccccccccccccccccccc11dddd11d1ccccccccccccc
cccccccccccccccccccccccccccccccccccccccccc777222244224444424422222224442222777ccccccccccccccccccccccccccc1dddd11c11ccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccc7772224442444422442227222222222777ccccccccccccccccccccccccccccc1dd1cccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccc77722244224422442227777222227777cccccccccccccccccccccccccccccc1111cccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccc77222244222244222277777777777cccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccc77722244444422227777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccc777222444422227777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccc7772222222227777cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccc77772222277777ccccccccccccccccccccccccccccccc7cc7cccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccc77777777777ccccccccccccccccccccccccccccccccc7cc7cccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccc777ccccccccccccccccccccccccccccccccccccc77c7cccccccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7cc77c7ccccc7cccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77c77c7cccc7ccccccccccccccccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7c777c7ccc7ccccccdddddddccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77c7c7c77cccccdddddddddddccccccccccc
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc77cc7777777cccccdddddddddddddcccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc777777777777777cccdddddddddddccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc7777777777777cccdddddddccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

__sfx__
000e0020186251800518625180051862518005186251862518625180051862518005186251800518625186251862518625186251800518625180051862518005186251800518625180051862518005186251a705
951c0020103141031010310103101c3111031010310103150e3140e3100e3100e3101a3130e3100e3100e3150e3140e3100e3100e31511314113101131011315103141031010310103150c3140c3100c3100c315
c01200201005500000040541005500000040551005500000100550000010054040550000010054040550000010055000001005404055000001005404055000001005500000040541005500000100550405500000
651200201c7211c7251c7251c7251c7251c7251c7251c7251f7211f7251f7251f7251f7251f7251f7251f72523721237252372523725177212372523725237251a7211a7251a7251a7250e7211a7251a7251a725
011200200c0530060000000006003c6153c60000000000000c0530c60000000000003c6150c50000000000000c0530c60000000000003c6150c50000000000000c0530c6003c615000003c615186150c61500615
051000200c05300600000003c6003c6153c6003c600000000c0530c60000000000003c600186000c600006000c0530c60000000000003c6150c50000000000000c0530c6003c615000003c615186150c61500615
311c002018032180021f0321800218032180021f032180021803200000210321800218032180022103218002180321800223032180021803218002230321800218032180021c0322100218032150021c03215002
013000200c0220c0250c0250c0210c0250c0250c02518024100221002510025100211002510025100251c024130221302513025130211302513025130251f0240e0220e0250e0251a02409022090210902515024
110e0020187051c7351870521735187051c7351870521735007051c7351870524735187051c7351870524735187051c7351870526735187051c7351870526735187051c735217051d735157051c735157051d735
011800200c0530060024615006003c6153c60000000000000c0530c6000c053000003c6150c50024600000000c0530c60000000000003c6150c5000c053000000c0530c6003c615000003c615186150c61500615
011400000c0530060000000006003c6153c60000000000000c0530c60000000000003c6150c50000000000000c0530c60000000000003c6150c50000000000000c0530c6003c615000003c615186150c61500615
01120020187500070000700007000c753007000c753007001f7500070000700007000c755007000c7000070021750007000070000700157530c70015753007001d75000700007000070015755007000070000700
4d1200201c75000700007002175000700217501c750007002375000700007001f7502175000700237500070024750007000070021750007002675028750007002175000700007001d7501c750007001a75000700
031200201f730071120711107112071110711207111071151a730021120211102112021110211202111021151c730041120411104112041110411204111041151873000112001110011200111001120011100115
4d1200201c7501c700007002175000700217501c750007002375023700007001f70021700007002370000700247502470000700217500070026750287500070021750217001d7001c700007001a7000070000700
991800203c0553c0453c0353c025300123c0053c0003c0003c0553c0453c0353c025340120000000000000003c0553c0453c0353c025370120000000000000003c0553c0453c0353c02532012000000000000000
01180020180500000000000180503c71500000000003c715180500000000000180503c715000000000000000180500000000000180503c71500000000003c715180500000000000180503c7153c7153c7153c715
141000201875500705217550070518755007052175500705187550070521755007051875500705217550070518755007052375500705187550070523755007051875500705237550070518755007052375500705
30100020047520c702157520c702047520c702157520c702047520c7021575200702047520c702157520c702047520c7020e7520c702047520c7020e7520c702047520c7020e7520c702047520c7020e7520c702
c02000200c1340c1200c1100c1340c1200c1100c1340c120151101513415120151101513415120151101513417120171101713417120171101713417120171101113411120111101113411120111101113411120
011000200c0530060024615006003c6153c60000000000000c0530c6000c053000003c6150c50024600000000c0530c60000000000003c6150c5000c053000000c0530c6003c615000003c615186150c61500615
001000200c0631862524625186253c6250c0630c0630c0630c063186250c0630c0633c6250c0630c0630c0630c063186250c0630c0633c6250c0630c0630c0630c0630c0633c625186253c625186250c62500625
0110002024755247052d7552470524755247052d7552470524755247052d7552470524755247052d7552470524755247052f7552470524755247052f7552470524755247052f7552470524755247052f75524705
d54000201c0201c0221c0201c0221c0201c0221c0201c0221f0201f0221f0201f0221f0201f0221f0201f02223020230222302023022230202302223020230221d0201d0221d0201d0221f0201f0221f0201f022
5d1000201c3121c315003001c310003001c31000300003001c3121c315003001c310003001c31000300003001f3121f315003001f310003001f31000300003002131221315003002131000300213100030000300
411000201002410021100211002110024100251002110025100241002110021100211002110025100211002513024130211302113021130211302513021130251502415021150211502115021150251502115025
d12400201872418722187201872218720187221872018722137241372213720137221372013722137201372215724157221572015722157201572215720157221172411722117201172213720137221372015722
15100020101650c105101650c105101650c105101650c105101650c105101650c105101650c105101650c105111650c105111650c105111650c105111650c105131650c105131650c105131650c1051116500105
052000201d775000051d7751d7751c775000051d7751f77521775000051d7751d7751c7750000500005000051c775000051c775000051a7750000518775000051d775000051c775000051d775000051c77500000
112000200406404060040650406004065040600406504065040640406004065040600406504060040650406505064050600506505060050650506005065050650706407060070650706007065070600706507065
03080000280720000226072000022407200002230720000221072000021f072000021d072000021c072000021a07200002180720400204002180020400204002280751c000280751003504025000000000000000
01020000185241a5201c5171d5101f515005002450000500185001a5001c5001d500215000050021500005002d500005002d500005002d500245002d500005002950000500295002450029500005002950000500
01010000105141052110522105211f5221f5211f5211f525005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500005000050000500
05030000114241142011420004000c4200c4200c42500400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400004000040000400
17100008180540c0450000000000180540c04500000000001c00010000000000000021000150000000000000180000c0000000000000180000c0000000000000180000c0000000000000180000c0000000000000
01030000187541c7411f751217410000000000000002475126741287552a7000c7000070000700007000c7000070000700007000c7000070000700007000c700007000c7000c7000c70000700007000000000000
4910002000610006100061001610016100161002610026100261003610036100361004610046100461005610056100c6100e6101161012610126101461016610126101161010610106100f610096100461000610
8f0200001065010620106100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
8f0300003465428640286401c2301c120100151060000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
910300001835430640183513063730640183550030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300003000030000300
011000001c71500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
490400000065000650006000160001600016000260002600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01030000180001800018000180001a0001a0001a0001a0001c0001c0001c0001c0001d0001d0001d0001d0001f0001f0001f0001f000210002100021000210000e0000e0000e0000e00010000100001000010000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
411800200c5550e555105550c5550e555105550c5550e5550c5550e555115550c5550e555115550c5550e5550c55510555135550c55510555135550c555105550c55510555135550c55510555155550c55510555
41180020245750050024575295750050000500295752857524575005002457521575005000050000500185751f57500500005001857500500185751857518575005002b5001f50021575005001d5751c57500500
891800200c7450c7400c7400c7400c7400c7420c7400c745137441374013740137401374013742137401374515744157401574015740157401574215740157451174411740117401174011740117421174011744
d31000002467128642246712864224671286422467128642286722464128672246412867224641286722464128672246712867224671286722467128672246712867224671286722467128672246712867200000
d118002000621006210062101621016210162102621026210262103621036210362104621046210462105621056210c6210e6211162112621126211462116621126211162110621106210f621096210462100621
d1180020245750050024575295750050000500295752857524575005002457521575005000050000500185751f57500500005001857500500185751857518575005002b5000000015575005001c5751d57500000
001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000001895000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__music__
01 03454304
00 03424304
00 03024444
00 02034344
00 02034304
00 02034304
00 02424304
02 02424304
01 40010648
00 40010608
00 00010608
02 00010608
01 1b5c454a
00 1b1c5d4a
02 1b1c1d4a
03 225c5d4a
01 0b4e1a24
00 0b0e1a64
00 4b0c0d1a
00 0b0e1a64
00 0b0c4d1a
02 0b0e4d24
02 4b4e4d4e
02 4b4f4d4e
01 11524354
00 11124354
00 11121453
00 11121453
00 11124314
00 11124314
00 11124315
00 11124315
00 11124315
02 16511215
03 24424344
01 10094944
00 10074944
02 10090f07
00 50494f47
00 41424344
01 57584354
00 57584354
00 59585754
00 59585754
00 57585955
00 57585955
00 57585955
00 57585955
01 17184354
00 19581714
00 19181714
00 17185915
00 17181915
02 17181955
02 57585955
00 41424344
03 38797a3c
01 38793a3c
00 38793a3c
00 38393a3c
00 38393a3c
00 38393a3c
02 38393a3c

