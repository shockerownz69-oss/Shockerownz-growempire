extends Control

const RED = Color("#d30b16")
const DARK = Color("#090909")
const PANEL = Color("#171717")
const WHITE = Color("#ffffff")
const MUTED = Color("#b7b7b7")
const GREEN = Color("#4ee17a")
const SAVE_PATH = "user://grow_empire_save.json"

var cash := 500
var xp := 0
var level := 1
var reputation := 0
var day := 1
var selected_genetic := "GG4 S1"
var plants: Array = []
var keepers: Array = []
var owned_upgrades := {"LED Upgrade": false, "Environment Controller": false}
var inventory: Array = []
var cured_inventory: Array = []
var mission_harvests := 0
var facility_level := 1
var mothers: Array = []
var crosses: Array = []
var contracts_completed := 0
var sound_on := true
var intro_seen := false
var achievements: Array = []
var room_two_unlocked := false
var rng := RandomNumberGenerator.new()

var genetics = {
	"GG4 S1": {"cost":40, "days":8, "base":230, "unlock":1, "traits":"Gas • Resin • Vigor"},
	"Slurricane #7": {"cost":75, "days":10, "base":390, "unlock":2, "traits":"Grape • Frost • Color"},
	"RKS S1": {"cost":120, "days":12, "base":620, "unlock":3, "traits":"Skunk • Funk • Preservation"},
	"Queen's Revenge S1": {"cost":180, "days":14, "base":950, "unlock":4, "traits":"Exotic • Resin • Keeper"}
}

var content: VBoxContainer
var stats_label: Label
var log_label: Label
var light_slider: HSlider
var rh_slider: HSlider
var feed_slider: HSlider

func _ready():
	rng.randomize()
	load_game()
	build_ui()
	show_title()

func make_label(text:String, size:=18, color:=WHITE) -> Label:
	var l=Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return l

func make_button(text:String, callback:Callable) -> Button:
	var b=Button.new()
	b.text=text
	b.custom_minimum_size=Vector2(0,52)
	b.add_theme_font_size_override("font_size",17)
	var sb=StyleBoxFlat.new()
	sb.bg_color=RED
	sb.corner_radius_top_left=10; sb.corner_radius_top_right=10
	sb.corner_radius_bottom_left=10; sb.corner_radius_bottom_right=10
	sb.border_width_left=1; sb.border_width_right=1; sb.border_width_top=1; sb.border_width_bottom=1
	sb.border_color=Color("#ff5961")
	b.add_theme_stylebox_override("normal",sb)
	b.pressed.connect(callback)
	return b

func panel() -> PanelContainer:
	var p=PanelContainer.new()
	var sb=StyleBoxFlat.new()
	sb.bg_color=PANEL
	sb.corner_radius_top_left=14; sb.corner_radius_top_right=14
	sb.corner_radius_bottom_left=14; sb.corner_radius_bottom_right=14
	sb.border_width_top=2; sb.border_color=RED
	sb.content_margin_left=14; sb.content_margin_right=14
	sb.content_margin_top=14; sb.content_margin_bottom=14
	p.add_theme_stylebox_override("panel",sb)
	return p

func build_ui():
	var bg=ColorRect.new()
	bg.color=DARK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scroll=ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var outer=VBoxContainer.new()
	outer.custom_minimum_size=Vector2(680,0)
	outer.add_theme_constant_override("separation",12)
	scroll.add_child(outer)

	var head=panel(); outer.add_child(head)
	var hv=VBoxContainer.new(); head.add_child(hv)
	var brand=make_label("SHOCKER OWNZ",18,RED); brand.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hv.add_child(brand)
	var title=make_label("GROW EMPIRE",38,WHITE); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hv.add_child(title)
	var motto=make_label("PROJECT 0 • GENETICS WITHOUT COMPROMISE",13,MUTED); motto.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hv.add_child(motto)
	stats_label=make_label("",17,WHITE); stats_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; hv.add_child(stats_label)

	var nav=HBoxContainer.new(); nav.add_theme_constant_override("separation",6); outer.add_child(nav)
	for item in [["GROW",show_grow],["GENETICS",show_genetics],["BREED",show_breeding],["CURE",show_cure],["PROJECT 0",show_vault],["MARKET",show_market],["SHOP",show_shop],["MISSIONS",show_missions]]:
		var b=make_button(item[0],item[1]); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; nav.add_child(b)

	content=VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	outer.add_child(content)
	refresh_stats()

func show_title():
	clear_content()
	var hero=panel(); content.add_child(hero)
	var v=VBoxContainer.new(); v.add_theme_constant_override("separation",12); hero.add_child(v)
	var brand=make_label("SHOCKER OWNZ",22,RED); brand.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; v.add_child(brand)
	var title=make_label("GROW EMPIRE",44,WHITE); title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; v.add_child(title)
	var sub=make_label("PROJECT 0 • PRESERVE THE GENETICS",15,MUTED); sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER; v.add_child(sub)
	var art=TextureRect.new()
	var tex=load("res://assets/shocker_ownz_reference.png")
	if tex:
		art.texture=tex; art.expand_mode=TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size=Vector2(0,280); v.add_child(art)
	var start=make_button("ENTER THE GROW",func(): intro_seen=true; save_game(); show_grow()); v.add_child(start)
	v.add_child(make_button("ACHIEVEMENTS",show_achievements))
	v.add_child(make_label("Grow • Hunt • Preserve • Breed • Build",16,MUTED))

func clear_content():
	for c in content.get_children(): c.queue_free()

func refresh_stats():
	stats_label.text="CASH  $%d     LEVEL  %d     XP  %d/%d     REP  %d" % [cash,level,xp,level*100,reputation]

func add_log(t:String):
	if is_instance_valid(log_label): log_label.text="Day %d — %s" % [day,t]

func show_grow():
	clear_content()
	var room=panel(); content.add_child(room)
	var v=VBoxContainer.new(); v.add_theme_constant_override("separation",10); room.add_child(v)
	v.add_child(make_label("SHOCKER OWNZ • ROOM 01 • DAY %d" % day,24,RED))
	if room_two_unlocked:
		v.add_child(make_label("ROOM 02 UNLOCKED • Expansion ready for the next build.",14,GREEN))
	v.add_child(make_label("Grow Like You Own The Show.",14,MUTED))
	var grid=GridContainer.new(); grid.columns=2; grid.add_theme_constant_override("h_separation",8); grid.add_theme_constant_override("v_separation",8); v.add_child(grid)
	for i in range(4):
		var site=panel(); site.custom_minimum_size=Vector2(320,185); grid.add_child(site)
		var sv=VBoxContainer.new(); site.add_child(sv)
		if i < plants.size():
			var p=plants[i]
			sv.add_child(make_label(p.name,19))
			var stage="SEEDLING"
			var icon="🌱"
			if p.age>1: stage="VEG"; icon="🌿"
			if p.age>p.days*0.45: stage="FLOWER"; icon="🌳"
			if p.age>=p.days: stage="HARVEST READY"; icon="✨"
			sv.add_child(make_label("%s  %s" % [icon,stage],32,GREEN))
			sv.add_child(make_label("Day %d / %d     Quality Q%d\nWater %d%% • Phenotype %s%s" % [p.age,p.days,quality(p),p.water,p.pheno," • ⚠ "+p.problem if p.get("problem","")!="" else ""],14,MUTED))
			if p.get("problem","")!="":
				sv.add_child(make_button("DIAGNOSE / TREAT",func(): treat_plant(i)))
			if p.water < 45:
				sv.add_child(make_button("WATER",func(): water_plant(i)))
			if p.age>=2 and p.age<p.days*0.45 and not p.get("trained",false):
				sv.add_child(make_button("TRAIN PLANT",func(): train_plant(i)))
			if p.age >= maxi(2,roundi(p.days*0.35)) and not mothers.any(func(m): return m.name==p.name and m.pheno==p.pheno):
				sv.add_child(make_button("SAVE AS MOTHER",func(): save_mother(i)))
			if p.age >= p.days:
				sv.add_child(make_button("HARVEST",func(): harvest(i)))
		else:
			sv.add_child(make_label("EMPTY GROW SITE",16,MUTED))
			sv.add_child(make_label("+",48,WHITE))
	v.add_child(make_button("ADVANCE 1 DAY",advance_day))

	var controls=panel(); content.add_child(controls)
	var cv=VBoxContainer.new(); controls.add_child(cv); cv.add_child(make_label("ROOM CONTROLS",20))
	light_slider=slider_row(cv,"Light",25,100,55)
	rh_slider=slider_row(cv,"Humidity",35,80,65)
	feed_slider=slider_row(cv,"Feed EC ×10",5,24,12)

	var choose=panel(); content.add_child(choose)
	var ch=VBoxContainer.new(); choose.add_child(ch); ch.add_child(make_label("PLANT GENETICS",20))
	for name in genetics:
		var g=genetics[name]
		var locked=level < g.unlock
		var b=make_button("%s  •  $%d%s" % [name,g.cost,"  [LV %d]"%g.unlock if locked else ""],func(n=name): plant(n))
		b.disabled=locked; ch.add_child(b)

	var lp=panel(); content.add_child(lp)
	var lv=VBoxContainer.new(); lp.add_child(lv); lv.add_child(make_label("GROW LOG",18))
	log_label=make_label("The room is running. Build the empire.",15,MUTED); lv.add_child(log_label)

func slider_row(parent:VBoxContainer,label:String,minv:float,maxv:float,val:float)->HSlider:
	parent.add_child(make_label(label,14,MUTED))
	var s=HSlider.new(); s.min_value=minv; s.max_value=maxv; s.value=val; s.step=1; s.custom_minimum_size=Vector2(0,42); parent.add_child(s)
	return s

func quality(p:Dictionary)->int:
	var l=light_slider.value if is_instance_valid(light_slider) else 70.0
	var h=rh_slider.value if is_instance_valid(rh_slider) else 57.0
	var f=(feed_slider.value/10.0) if is_instance_valid(feed_slider) else 1.5
	var flower=p.age > p.days*0.45
	var q=100.0-abs(l-(82 if flower else 55))*0.45-abs(h-(50 if flower else 65))*0.7-abs(f-(1.8 if flower else 1.2))*14
	q-=maxi(0,45-int(p.get("water",100)))*0.6
	if p.get("trained",false): q+=4
	if p.get("problem","")!="": q-=8
	q*=float(p.get("vigor",100))/100.0
	if owned_upgrades["LED Upgrade"]: q+=5
	if owned_upgrades["Environment Controller"]: q+=5
	return clampi(roundi(q),35,100)

func plant(name:String):
	var g=genetics[name]
	if plants.size()>=4: add_log("All four sites are occupied."); return
	if cash<g.cost: add_log("Not enough cash."); return
	cash-=g.cost
	var phenos=["A","B","C","D"]
	var pheno=phenos[rng.randi_range(0,phenos.size()-1)]
	var vigor=rng.randi_range(88,112)
	plants.append({"name":name,"age":0,"days":g.days,"base":g.base,"traits":g.traits,"water":100,"pheno":pheno,"vigor":vigor,"trained":false,"problem":""})
	refresh_stats(); save_game(); show_grow()

func advance_day():
	day+=1
	for p in plants:
		p.age=min(p.age+1,p.days)
		p.water=maxi(0,int(p.get("water",100))-rng.randi_range(13,23))
		if p.get("problem","")=="" and rng.randf()<0.08:
			var probs=["Light Stress","Nutrient Imbalance","Pests"]
			p.problem=probs[rng.randi_range(0,probs.size()-1)]
	save_game(); show_grow()

func harvest(i:int):
	if i<0 or i>=plants.size(): return
	var p=plants[i]; var q=quality(p)
	var wet_grams=roundi((18.0+p.base/28.0)*(float(p.vigor)/100.0))
	inventory.append({"name":p.name,"q":q,"grams":wet_grams,"days":0,"pheno":p.pheno})
	xp+=roundi(30+q*0.55); reputation+=maxi(1,roundi(q/12.0)); mission_harvests+=1; unlock_achievement("First Harvest")
	if q>=90 and not keepers.any(func(k): return k.name==p.name and k.pheno==p.pheno):
		keepers.append({"name":p.name,"q":q,"traits":p.traits,"pheno":p.pheno}); unlock_achievement("Keeper Hunter")
	plants.remove_at(i)
	while xp>=level*100:
		xp-=level*100; level+=1
	save_game(); refresh_stats(); show_grow()

func show_genetics():
	clear_content()
	var p=panel(); content.add_child(p); var v=VBoxContainer.new(); p.add_child(v)
	v.add_child(make_label("GENETICS LIBRARY",26))
	for name in genetics:
		var g=genetics[name]
		v.add_child(make_label("%s  •  LV %d\n%s\nSeed: $%d • Flower: %d days" % [name,g.unlock,g.traits,g.cost,g.days],17,WHITE))

func train_plant(i:int):
	if i<0 or i>=plants.size(): return
	plants[i].trained=true
	reputation+=1
	save_game(); show_grow()

func treat_plant(i:int):
	if i<0 or i>=plants.size(): return
	if cash<25: return
	cash-=25
	plants[i].problem=""
	save_game(); refresh_stats(); show_grow()

func unlock_achievement(id:String):
	if id in achievements: return
	achievements.append(id)

func show_achievements():
	clear_content()
	var p=panel(); content.add_child(p); var v=VBoxContainer.new(); p.add_child(v)
	v.add_child(make_label("ACHIEVEMENTS",26,RED))
	var defs=[
		["First Harvest","Bring your first plant to harvest."],
		["Keeper Hunter","Preserve a Q90+ phenotype."],
		["Breeder","Create your first cross."],
		["Contract Killer","Complete a dispensary contract."],
		["Empire Builder","Reach facility level 2."]
	]
	for a in defs:
		var done=a[0] in achievements
		v.add_child(make_label(("✓ " if done else "○ ")+a[0]+"\\n"+a[1],17,WHITE if done else MUTED))
	v.add_child(make_button("BACK TO GROW",show_grow))

func water_plant(i:int):
	if i<0 or i>=plants.size(): return
	plants[i].water=100
	save_game(); show_grow()

func save_mother(i:int):
	if i<0 or i>=plants.size(): return
	var p=plants[i]
	if mothers.size()>=6: return
	mothers.append({"name":p.name,"pheno":p.pheno,"q":quality(p),"traits":p.traits,"vigor":p.vigor})
	save_game(); show_grow()

func show_breeding():
	clear_content()
	var p=panel(); content.add_child(p); var v=VBoxContainer.new(); p.add_child(v)
	v.add_child(make_label("BREEDING LAB",26,RED))
	v.add_child(make_label("Save plants as mothers, make clones, or combine two preserved selections.",15,MUTED))
	if mothers.is_empty():
		v.add_child(make_label("No mothers yet. Save a plant from the grow room first.",18))
	for i in range(mothers.size()):
		var m=mothers[i]
		v.add_child(make_button("CLONE • %s Pheno %s • Q%d" % [m.name,m.pheno,m.q],func(idx=i): clone_mother(idx)))
	if mothers.size()>=2:
		v.add_child(make_button("MAKE CROSS: %s × %s" % [mothers[0].name,mothers[1].name],make_cross))
	if not crosses.is_empty():
		v.add_child(make_label("CREATED GENETICS",18,WHITE))
		for c in crosses:
			v.add_child(make_label("%s\\n%s • Stability %d%%" % [c.name,c.traits,c.stability],16,MUTED))

func clone_mother(i:int):
	if i<0 or i>=mothers.size() or plants.size()>=4: return
	var m=mothers[i]
	var base=300
	if genetics.has(m.name): base=genetics[m.name].base
	plants.append({"name":m.name+" Clone","age":0,"days":9,"base":base,"traits":m.traits,"water":100,"pheno":m.pheno,"vigor":m.vigor})
	save_game(); show_grow()

func make_cross():
	if mothers.size()<2: return
	var a=mothers[0]; var b=mothers[1]
	var cname="%s × %s" % [a.name,b.name]
	if crosses.any(func(c): return c.name==cname): return
	crosses.append({"name":cname,"traits":a.traits+" • "+b.traits,"stability":rng.randi_range(55,82)})
	reputation+=15; xp+=75; unlock_achievement("Breeder")
	save_game(); refresh_stats(); show_breeding()

func show_market():
	clear_content()
	var p=panel(); content.add_child(p); var v=VBoxContainer.new(); p.add_child(v)
	v.add_child(make_label("DISPENSARY CONTRACTS",26))
	v.add_child(make_label("Deliver cured flower that meets the buyer's grade.",15,MUTED))
	var eligible=-1
	for i in range(cured_inventory.size()):
		if cured_inventory[i].q>=80 and cured_inventory[i].grams>=20:
			eligible=i; break
	if eligible>=0:
		var c=cured_inventory[eligible]
		v.add_child(make_label("CONTRACT: Premium Shelf\\nNeed: 20g+ at Q80+\\nBonus payout: 35%",17,WHITE))
		v.add_child(make_button("FULFILL WITH %s • Q%d • %dg" % [c.name,c.q,c.grams],func(idx=eligible): fulfill_contract(idx)))
	else:
		v.add_child(make_label("Premium Shelf — requires 20g+ cured flower at Q80+.",17,MUTED))
	v.add_child(make_label("Contracts completed: %d" % contracts_completed,16,WHITE))

func fulfill_contract(i:int):
	if i<0 or i>=cured_inventory.size(): return
	var c=cured_inventory[i]
	if c.q<80 or c.grams<20: return
	cash+=roundi(sale_value(c)*1.35); reputation+=12; xp+=60; contracts_completed+=1
	cured_inventory.remove_at(i)
	unlock_achievement("Contract Killer")
	save_game(); refresh_stats(); show_market()

func show_cure():
	clear_content()
	var p=panel(); content.add_child(p); var v=VBoxContainer.new(); p.add_child(v)
	v.add_child(make_label("DRY & CURE ROOM",26))
	v.add_child(make_label("Harvests finish here before they can be sold.",16,MUTED))
	if inventory.is_empty() and cured_inventory.is_empty():
		v.add_child(make_label("No harvested flower yet.",18))
	for i in range(inventory.size()):
		var b=make_button("%s • Pheno %s • Q%d • %dg • Cure Day %d/3" % [inventory[i].name,inventory[i].pheno,inventory[i].q,inventory[i].grams,inventory[i].days],func(idx=i): cure_day(idx))
		v.add_child(b)
	for i in range(cured_inventory.size()):
		var c=cured_inventory[i]
		v.add_child(make_button("SELL %s • Q%d • %dg • $%d" % [c.name,c.q,c.grams,sale_value(c)],func(idx=i): sell_cured(idx)))

func cure_day(i:int):
	if i<0 or i>=inventory.size(): return
	inventory[i].days+=1
	if inventory[i].days>=3:
		cured_inventory.append(inventory[i])
		inventory.remove_at(i)
	save_game(); show_cure()

func sale_value(c:Dictionary)->int:
	return roundi(c.grams*(4.0+c.q/18.0))

func sell_cured(i:int):
	if i<0 or i>=cured_inventory.size(): return
	var c=cured_inventory[i]
	cash+=sale_value(c)
	cured_inventory.remove_at(i)
	save_game(); refresh_stats(); show_cure()

func show_missions():
	clear_content()
	var p=panel(); content.add_child(p); var v=VBoxContainer.new(); p.add_child(v)
	v.add_child(make_label("PROJECT 0 MISSIONS",26))
	v.add_child(make_label("Harvest 3 plants",18))
	v.add_child(make_label("%d / 3" % mini(mission_harvests,3),16,MUTED))
	if mission_harvests>=3 and facility_level==1:
		v.add_child(make_button("CLAIM: +$1,000 & ROOM LEVEL 2",claim_mission))
	else:
		v.add_child(make_label("Reward: $1,000 + facility expansion",15,MUTED))

func claim_mission():
	if mission_harvests<3 or facility_level>1: return
	cash+=1000; facility_level=2; room_two_unlocked=true; reputation+=10; unlock_achievement("Empire Builder")
	save_game(); refresh_stats(); show_missions()

func show_vault():
	clear_content()
	var p=panel(); content.add_child(p); var v=VBoxContainer.new(); p.add_child(v)
	v.add_child(make_label("PROJECT 0 VAULT",26,RED))
	v.add_child(make_label("Preserve exceptional Q90+ phenotypes.",16,MUTED))
	if keepers.is_empty(): v.add_child(make_label("No keeper cuts yet.",18,WHITE))
	for k in keepers: v.add_child(make_label("PROJECT 0 VERIFIED • %s • PHENO %s • Q%d\n%s" % [k.name,k.get("pheno","A"),k.q,k.traits],18,WHITE))

func show_shop():
	clear_content()
	var p=panel(); content.add_child(p); var v=VBoxContainer.new(); p.add_child(v)
	v.add_child(make_label("EQUIPMENT SHOP",26))
	for item in [["LED Upgrade",750],["Environment Controller",1250]]:
		var owned=owned_upgrades[item[0]]
		var b=make_button("%s — %s" % [item[0],"OWNED" if owned else "$%d"%item[1]],func(n=item[0],c=item[1]): buy_upgrade(n,c))
		b.disabled=owned; v.add_child(b)

func buy_upgrade(n:String,c:int):
	if cash<c: return
	cash-=c; owned_upgrades[n]=true; save_game(); refresh_stats(); show_shop()

func save_game():
	var data={"cash":cash,"xp":xp,"level":level,"reputation":reputation,"day":day,"plants":plants,"keepers":keepers,"upgrades":owned_upgrades,"inventory":inventory,"cured_inventory":cured_inventory,"mission_harvests":mission_harvests,"facility_level":facility_level,"mothers":mothers,"crosses":crosses,"contracts_completed":contracts_completed,"intro_seen":intro_seen,"achievements":achievements,"room_two_unlocked":room_two_unlocked}
	var f=FileAccess.open(SAVE_PATH,FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(data))

func load_game():
	if not FileAccess.file_exists(SAVE_PATH): return
	var f=FileAccess.open(SAVE_PATH,FileAccess.READ)
	if not f: return
	var d=JSON.parse_string(f.get_as_text())
	if typeof(d)!=TYPE_DICTIONARY: return
	cash=int(d.get("cash",500)); xp=int(d.get("xp",0)); level=int(d.get("level",1)); reputation=int(d.get("reputation",0)); day=int(d.get("day",1))
	plants=d.get("plants",[]); keepers=d.get("keepers",[]); owned_upgrades=d.get("upgrades",owned_upgrades)
	inventory=d.get("inventory",[]); cured_inventory=d.get("cured_inventory",[])
	mission_harvests=int(d.get("mission_harvests",0)); facility_level=int(d.get("facility_level",1))
	mothers=d.get("mothers",[]); crosses=d.get("crosses",[]); contracts_completed=int(d.get("contracts_completed",0))
	intro_seen=bool(d.get("intro_seen",false)); achievements=d.get("achievements",[]); room_two_unlocked=bool(d.get("room_two_unlocked",false))
	for p in plants:
		if not p.has("water"): p.water=100
		if not p.has("pheno"): p.pheno="A"
		if not p.has("vigor"): p.vigor=100
		if not p.has("trained"): p.trained=false
		if not p.has("problem"): p.problem=""
