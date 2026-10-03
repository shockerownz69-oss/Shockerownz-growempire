extends Control

const RED=Color("#d30b16")
const DARK=Color("#080808")
const PANEL=Color("#171717")
const WHITE=Color("#ffffff")
const MUTED=Color("#b7b7b7")
const GREEN=Color("#4ee17a")
const GOLD=Color("#e7b94a")
const PURPLE=Color("#b46cff")
const SAVE_PATH="user://grow_empire_save.json"
const TYCOON_SAVE_PATH="user://grow_empire_tycoon.json"

var cash:=500
var xp:=0
var level:=1
var reputation:=0
var day:=1
var plants:Array=[]
var keepers:Array=[]
var mothers:Array=[]
var crosses:Array=[]
var seed_inventory:Array=[]
var inventory:Array=[]
var cured_inventory:Array=[]
var achievements:Array=[]
var mission_claimed:Array=[]
var side_claimed:Array=[]
var weekly_claimed:Array=[]
var research_owned:Array=[]
var employees:Array=[]
var event_log:Array=[]
var trait_codex:Array=[]
var genetic_records:Dictionary={}
var mission_harvests:=0
var contracts_completed:=0
var facility_level:=1
var room_two_unlocked:=false
var total_revenue:=0
var total_expenses:=0
var cups_won:=0
var last_bill_day:=1
var weekly_start_day:=1
var weekly_harvest_start:=0
var weekly_rep_start:=0
var phenotype_counter:=0

var owned_upgrades={
	"LED Upgrade":false,
	"Environment Controller":false
}

var rng:=RandomNumberGenerator.new()

var content:VBoxContainer
var stats_label:Label
var light_slider:HSlider
var rh_slider:HSlider
var feed_slider:HSlider


var genetics={
	"GG4 S1":{
		"cost":40,
		"days":8,
		"base":230,
		"unlock":1,
		"traits":["Gas","Resin","Vigor"],
		"bias":{"resin":8,"vigor":8}
	},
	"Slurricane #7":{
		"cost":75,
		"days":10,
		"base":390,
		"unlock":2,
		"traits":["Grape","Frost","Color"],
		"bias":{"resin":10,"color":12}
	},
	"RKS S1":{
		"cost":120,
		"days":12,
		"base":620,
		"unlock":3,
		"traits":["Skunk","Funk","Preservation"],
		"bias":{"aroma":15,"stability":8}
	},
	"Queen's Revenge S1":{
		"cost":180,
		"days":14,
		"base":950,
		"unlock":4,
		"traits":["Exotic","Resin","Keeper"],
		"bias":{"resin":14,"potential":12}
	}
}


const FACILITIES=[
	{
		"name":"Closet Start",
		"cost":0,
		"slots":4,
		"overhead":35,
		"unlock":1
	},
	{
		"name":"Pro Tent",
		"cost":2500,
		"slots":6,
		"overhead":75,
		"unlock":2
	},
	{
		"name":"Basement Lab",
		"cost":7500,
		"slots":8,
		"overhead":150,
		"unlock":3
	},
	{
		"name":"Garage Facility",
		"cost":18000,
		"slots":10,
		"overhead":300,
		"unlock":4
	},
	{
		"name":"Warehouse",
		"cost":50000,
		"slots":12,
		"overhead":650,
		"unlock":5
	},
	{
		"name":"Project 0 Compound",
		"cost":125000,
		"slots":16,
		"overhead":1200,
		"unlock":6
	}
]


const STAFF=[
	{
		"role":"Grow Tech",
		"hire":600,
		"pay":55
	},
	{
		"role":"Breeding Tech",
		"hire":1200,
		"pay":90
	},
	{
		"role":"Sales Rep",
		"hire":1600,
		"pay":110
	},
	{
		"role":"Facility Manager",
		"hire":3000,
		"pay":180
	},
	{
		"role":"Genetics Researcher",
		"hire":5000,
		"pay":260
	}
]


const RESEARCH=[
	{
		"id":"r1",
		"name":"Efficient Lighting",
		"cost":1000
	},
	{
		"id":"r2",
		"name":"Climate Automation",
		"cost":2500
	},
	{
		"id":"r3",
		"name":"Genetic Analytics",
		"cost":5000
	},
	{
		"id":"r4",
		"name":"Contract Network",
		"cost":7500
	},
	{
		"id":"r5",
		"name":"Project 0 Lab",
		"cost":15000
	}
]


const TRAITS=[
	"Heavy Resin",
	"Loud Aroma",
	"Deep Color",
	"Fast Finish",
	"High Vigor",
	"Heavy Yield",
	"Stress Tough",
	"Stable Line",
	"Rare Terpene",
	"Collector Cut",
	"Mutation Carrier",
	"Elite Structure"
]


const MUTATIONS=[
	"Black Leaf",
	"Double Resin",
	"Freak Structure",
	"Ultra Funk",
	"Golden Trichomes",
	"Vigor Surge"
]


func _ready():
	rng.randomize()

	load_game()
	tycoon_load()

	build_ui()
	show_title()

	call_deferred("safe_migrate_genetics")


func make_label(
	text:String,
	size:=18,
	color:=WHITE
)->Label:

	var l=Label.new()
	l.text=text
	l.add_theme_font_size_override(
		"font_size",
		size
	)
	l.add_theme_color_override(
		"font_color",
		color
	)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	return l


func make_button(
	text:String,
	callback:Callable
)->Button:

	var b=Button.new()
	b.text=text
	b.custom_minimum_size=Vector2(0,52)
	b.add_theme_font_size_override(
		"font_size",
		16
	)

	var s=StyleBoxFlat.new()
	s.bg_color=RED

	s.corner_radius_top_left=10
	s.corner_radius_top_right=10
	s.corner_radius_bottom_left=10
	s.corner_radius_bottom_right=10

	s.border_width_left=1
	s.border_width_right=1
	s.border_width_top=1
	s.border_width_bottom=1

	s.border_color=Color("#ff5961")

	b.add_theme_stylebox_override(
		"normal",
		s
	)

	b.pressed.connect(callback)
	return b


func panel()->PanelContainer:
	var p=PanelContainer.new()
	var s=StyleBoxFlat.new()

	s.bg_color=PANEL

	s.corner_radius_top_left=14
	s.corner_radius_top_right=14
	s.corner_radius_bottom_left=14
	s.corner_radius_bottom_right=14

	s.border_width_top=2
	s.border_color=RED

	s.content_margin_left=14
	s.content_margin_right=14
	s.content_margin_top=14
	s.content_margin_bottom=14

	p.add_theme_stylebox_override(
		"panel",
		s
	)

	return p


func build_ui():
	var bg=ColorRect.new()
	bg.color=DARK
	bg.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	add_child(bg)

	var scroll=ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var outer=VBoxContainer.new()
	outer.custom_minimum_size=Vector2(680,0)
	outer.add_theme_constant_override(
		"separation",
		10
	)
	scroll.add_child(outer)

	var head=panel()
	outer.add_child(head)

	var hv=VBoxContainer.new()
	head.add_child(hv)

	var brand=make_label(
		"SHOCKER OWNZ",
		18,
		RED
	)
	brand.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(brand)

	var title=make_label(
		"GROW EMPIRE",
		36
	)
	title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(title)

	var motto=make_label(
		"PROJECT 0 • GENETICS WITHOUT COMPROMISE",
		13,
		MUTED
	)
	motto.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(motto)

	stats_label=make_label("",16)
	stats_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(stats_label)

	var nav=GridContainer.new()
	nav.columns=4
	outer.add_child(nav)

	var nav_items=[
		["EMPIRE",show_empire],
		["GROW",show_grow],
		["GENETICS",show_genetics],
		["BREED",show_breeding],
		["CURE",show_cure],
		["PROJECT 0",show_vault],
		["MARKET",show_market],
		["MISSIONS",show_missions]
	]

	for item in nav_items:
		var b=make_button(
			item[0],
			item[1]
		)
		b.custom_minimum_size=Vector2(165,48)
		nav.add_child(b)

	content=VBoxContainer.new()
	content.add_theme_constant_override(
		"separation",
		10
	)
	outer.add_child(content)

	refresh_stats()


func clear_content():
	for c in content.get_children():
		c.queue_free()


func refresh_stats():
	stats_label.text="$%d   LV %d   XP %d/%d   REP %d   DAY %d"%[
		cash,
		level,
		xp,
		level*100,
		reputation,
		day
	]


func show_title():
	clear_content()

	var p=panel()
	content.add_child(p)

	var v=VBoxContainer.new()
	p.add_child(v)

	var t=make_label(
		"⚠ SHOCKER OWNZ ⚠",
		24,
		RED
	)
	t.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var g=make_label(
		"GROW EMPIRE • ALPHA 0.12",
		40
	)
	g.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(g)

	var tex=load(
		"res://shocker_ownz_reference.jpg"
	)

	if tex:
		var art=TextureRect.new()
		art.texture=tex
		art.expand_mode=TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size=Vector2(0,300)
		v.add_child(art)

	var sub=make_label(
		"PROJECT 0 • PRESERVE THE GENETICS",
		16,
		GOLD
	)
	sub.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	v.add_child(
		make_button(
			"ENTER THE EMPIRE",
			show_empire
		)
	)

	v.add_child(
		make_button(
			"GENETICS LAB",
			show_genetics
		)
	)

	v.add_child(
		make_button(
			"PROJECT 0 VAULT",
			show_vault
		)
	)


func facility_data()->Dictionary:
	return FACILITIES[
		clampi(
			facility_level-1,
			0,
			FACILITIES.size()-1
		)
	]


func grow_capacity()->int:
	return int(
		facility_data()["slots"]
	)


func employee_payroll()->int:
	var n:=0

	for e in employees:
		n+=int(
			e.get("pay",0)
		)

	return n


func has_employee(role:String)->bool:
	for e in employees:
		if e["role"]==role:
			return true

	return false


func business_value()->int:
	return maxi(
		0,
		cash+
		total_revenue+
		keepers.size()*900+
		mothers.size()*500+
		crosses.size()*1200+
		cups_won*5000+
		facility_level*2500+
		employees.size()*1000+
		research_owned.size()*1500+
		seed_inventory.size()*250
	)


func show_empire():
	clear_content()

	content.add_child(
		make_label(
			"EMPIRE HQ",
			30,
			RED
		)
	)

	var f=facility_data()

	content.add_child(
		make_label(
			"%s\nGrow Sites %d • Crew %d • Payroll $%d\nEmpire Value $%d\nCups %d • Genetics Recorded %d"%[
				f["name"],
				grow_capacity(),
				employees.size(),
				employee_payroll(),
				business_value(),
				cups_won,
				genetic_records.size()
			],
			17,
			GOLD
		)
	)

	var grid=GridContainer.new()
	grid.columns=2
	content.add_child(grid)

	var buttons=[
		["FACILITIES",show_facilities],
		["EMPLOYEES",show_employees],
		["SIDE MISSIONS",show_side_missions],
		["WEEKLY",show_weekly],
		["RESEARCH",show_research],
		["COMPETE",show_competitions],
		["FINANCES",show_finances],
		["EQUIPMENT",show_shop]
	]

	for x in buttons:
		grid.add_child(
			make_button(
				x[0],
				x[1]
			)
		)

	if not event_log.is_empty():
		content.add_child(
			make_label(
				"EMPIRE NEWS",
				20,
				RED
			)
		)

		for i in range(
			maxi(
				0,
				event_log.size()-4
			),
			event_log.size()
		):
			content.add_child(
				make_label(
					"• "+str(event_log[i]),
					14,
					MUTED
				)
			)


func show_facilities():
	clear_content()

	content.add_child(
		make_label(
			"FACILITY EXPANSION",
			29,
			RED
		)
	)

	for i in range(FACILITIES.size()):
		var f=FACILITIES[i]
		var status="LOCKED"

		if i<facility_level:
			status="OWNED"

		elif i==facility_level:
			status="NEXT"

		content.add_child(
			make_label(
				"%s • %s\n%d sites • $%d overhead • LV %d"%[
					f["name"],
					status,
					f["slots"],
					f["overhead"],
					f["unlock"]
				],
				17,
				GREEN if i<facility_level else WHITE
			)
		)

		if i==facility_level:
			var b=make_button(
				"EXPAND • $%d"%f["cost"],
				func(idx=i):
					buy_facility(idx)
			)

			b.disabled=level<int(f["unlock"])
			content.add_child(b)

	content.add_child(
		make_button(
			"BACK TO EMPIRE",
			show_empire
		)
	)


func buy_facility(i:int):
	if i!=facility_level:
		return

	if i>=FACILITIES.size():
		return

	var f=FACILITIES[i]

	if level<int(f["unlock"]):
		return

	if cash<int(f["cost"]):
		return

	cash-=int(f["cost"])
	total_expenses+=int(f["cost"])
	facility_level+=1

	room_two_unlocked=facility_level>=2

	unlock_achievement(
		"Empire Builder"
	)

	save_all()
	refresh_stats()
	show_facilities()


func show_employees():
	clear_content()

	content.add_child(
		make_label(
			"EMPIRE STAFF",
			29,
			RED
		)
	)

	content.add_child(
		make_label(
			"Crew %d • Payroll $%d"%[
				employees.size(),
				employee_payroll()
			],
			16,
			GOLD
		)
	)

	for s in STAFF:
		content.add_child(
			make_button(
				"%s • Hire $%d • Pay $%d"%[
					s["role"],
					s["hire"],
					s["pay"]
				],
				func(role=s["role"]):
					hire_employee(role)
			)
		)

	for e in employees:
		content.add_child(
			make_label(
				"• %s • Skill %d"%[
					e["role"],
					e["skill"]
				],
				14,
				MUTED
			)
		)

	content.add_child(
		make_button(
			"BACK TO EMPIRE",
			show_empire
		)
	)


func hire_employee(role:String):
	for s in STAFF:
		if s["role"]==role:
			if cash<int(s["hire"]):
				return

			cash-=int(s["hire"])
			total_expenses+=int(s["hire"])

			employees.append({
				"role":role,
				"pay":int(s["pay"]),
				"skill":rng.randi_range(55,90)
			})

			save_all()
			refresh_stats()
			show_employees()
			return


func roll_stat(
	base:=65,
	bias:=0
)->int:

	return clampi(
		base+
		rng.randi_range(-18,18)+
		bias,
		25,
		100
	)


func new_genome(
	name:String,
	parent_a:Dictionary={},
	parent_b:Dictionary={}
)->Dictionary:

	phenotype_counter+=1

	var bias=genetics.get(
		name,
		{}
	).get(
		"bias",
		{}
	)

	var g={}

	if parent_a.is_empty():
		g={
			"vigor":roll_stat(
				67,
				int(bias.get("vigor",0))
			),
			"yield":roll_stat(),
			"resin":roll_stat(
				65,
				int(bias.get("resin",0))
			),
			"aroma":roll_stat(
				65,
				int(bias.get("aroma",0))
			),
			"color":roll_stat(
				60,
				int(bias.get("color",0))
			),
			"stability":roll_stat(
				68,
				int(bias.get("stability",0))
			),
			"stress":roll_stat(),
			"potential":roll_stat(
				65,
				int(bias.get("potential",0))
			)
		}

	else:
		for k in [
			"vigor",
			"yield",
			"resin",
			"aroma",
			"color",
			"stability",
			"stress",
			"potential"
		]:
			g[k]=clampi(
				roundi(
					(
						int(parent_a.get(k,65))+
						int(parent_b.get(k,65))
					)/2.0
				)+
				rng.randi_range(-10,10),
				25,
				100
			)

	var mutation=""
	var chance=0.025

	if "r5" in research_owned:
		chance+=0.01

	if rng.randf()<chance:
		mutation=MUTATIONS[
			rng.randi_range(
				0,
				MUTATIONS.size()-1
			)
		]

	var traits:Array=[]

	for t in TRAITS:
		if rng.randf()<0.12:
			traits.append(t)

	if mutation!="":
		traits.append(mutation)

	return {
		"id":"P0-%05d"%phenotype_counter,
		"stats":g,
		"hidden_traits":traits,
		"discovered_traits":[],
		"mutation":mutation
	}


func genetic_score(p:Dictionary)->int:
	var s=p.get(
		"genome",
		{}
	).get(
		"stats",
		{}
	)

	if s.is_empty():
		return quality(p)

	var total=0

	for k in [
		"vigor",
		"yield",
		"resin",
		"aroma",
		"color",
		"stability",
		"stress",
		"potential"
	]:
		total+=int(
			s.get(k,60)
		)

	var score=roundi(
		total/8.0
	)

	if p.get(
		"genome",
		{}
	).get(
		"mutation",
		""
	)!="":
		score+=4

	return clampi(
		score,
		1,
		100
	)


func rarity_from_score(score:int)->String:
	if score>=94:
		return "PROJECT 0 VERIFIED"

	if score>=88:
		return "LEGENDARY"

	if score>=80:
		return "ELITE"

	if score>=70:
		return "SELECT"

	return "COMMON"


func rarity_color(r:String)->Color:
	match r:
		"PROJECT 0 VERIFIED":
			return RED

		"LEGENDARY":
			return GOLD

		"ELITE":
			return PURPLE

		"SELECT":
			return GREEN

	return MUTED


func discover_traits(
	p:Dictionary,
	amount:=1
):
	var genome=p.get(
		"genome",
		{}
	)

	var hidden:Array=genome.get(
		"hidden_traits",
		[]
	)

	var found:Array=genome.get(
		"discovered_traits",
		[]
	)

	var candidates:Array=[]

	for t in hidden:
		if t not in found:
			candidates.append(t)

	for n in range(amount):
		if candidates.is_empty():
			break

		var t=candidates[
			rng.randi_range(
				0,
				candidates.size()-1
			)
		]

		found.append(t)
		candidates.erase(t)

		if t not in trait_codex:
			trait_codex.append(t)

	genome["discovered_traits"]=found
	p["genome"]=genome


func migrate_genetics():
	for p in plants:
		if not p.has("genome"):
			p["genome"]=new_genome(
				str(
					p.get(
						"name",
						"Unknown"
					)
				)
			)

	for m in mothers:
		if not m.has("genome"):
			m["genome"]=new_genome(
				str(
					m.get(
						"name",
						"Unknown"
					)
				)
			)

	for k in keepers:
		if not k.has("genome"):
			k["genome"]=new_genome(
				str(
					k.get(
						"name",
						"Unknown"
					)
				)
			)

	for c in crosses:
		if not c.has("generation"):
			c["generation"]="F1"

	save_all()


func record_genetic(p:Dictionary):
	var genome=p.get(
		"genome",
		{}
	)

	var id=str(
		genome.get(
			"id",
			"UNKNOWN"
		)
	)

	genetic_records[id]={
		"name":p.get(
			"name",
			"Unknown"
		),
		"pheno":p.get(
			"pheno",
			"A"
		),
		"score":genetic_score(p),
		"rarity":rarity_from_score(
			genetic_score(p)
		),
		"traits":genome.get(
			"discovered_traits",
			[]
		),
		"mutation":genome.get(
			"mutation",
			""
		),
		"parents":p.get(
			"parents",
			[]
		),
		"generation":p.get(
			"generation",
			"Seed"
		)
	}


func show_genetics():
	clear_content()

	content.add_child(
		make_label(
			"GENETICS LAB • ALPHA 0.12",
			29,
			RED
		)
	)

	content.add_child(
		make_label(
			"Phenohunt • Analyze • Preserve • Breed",
			15,
			GOLD
		)
	)

	for i in range(plants.size()):
		var p=plants[i]
		var score=genetic_score(p)
		var r=rarity_from_score(score)
		var genome=p["genome"]
		var stats=genome["stats"]

		var card=panel()
		content.add_child(card)

		var v=VBoxContainer.new()
		card.add_child(v)

		v.add_child(
			make_label(
				"%s • %s • %s"%[
					p["name"],
					genome["id"],
					r
				],
				18,
				rarity_color(r)
			)
		)

		v.add_child(
			make_label(
				"GENETIC SCORE %d\nVIG %d • YLD %d • RES %d • ARM %d\nCLR %d • STB %d • STR %d • POT %d"%[
					score,
					stats["vigor"],
					stats["yield"],
					stats["resin"],
					stats["aroma"],
					stats["color"],
					stats["stability"],
					stats["stress"],
					stats["potential"]
				],
				14
			)
		)

		var found:Array=genome.get(
			"discovered_traits",
			[]
		)

		var trait_text="None yet"

		if not found.is_empty():
			trait_text=", ".join(found)

		v.add_child(
			make_label(
				"Discovered: "+trait_text,
				13,
				MUTED
			)
		)

		if genome.get("mutation","")!="":
			v.add_child(
				make_label(
					"MUTATION DETECTED • "+
					str(genome["mutation"]),
					14,
					GOLD
				)
			)

		v.add_child(
			make_button(
				"GENETIC ANALYSIS",
				func(idx=i):
					analyze_plant(idx)
			)
		)

	content.add_child(
		make_button(
			"TRAIT CODEX",
			show_trait_codex
		)
	)

	content.add_child(
		make_button(
			"FAMILY TREE",
			show_family_tree
		)
	)


func analyze_plant(i:int):
	if i<0 or i>=plants.size():
		return

	var amount=1

	if "r3" in research_owned:
		amount+=1

	if has_employee(
		"Genetics Researcher"
	):
		amount+=1

	discover_traits(
		plants[i],
		amount
	)

	record_genetic(
		plants[i]
	)

	save_all()
	show_genetics()


func show_trait_codex():
	clear_content()

	content.add_child(
		make_label(
			"PROJECT 0 • TRAIT CODEX",
			29,
			RED
		)
	)

	content.add_child(
		make_label(
			"%d / %d SPECIAL TRAITS DISCOVERED"%[
				trait_codex.size(),
				TRAITS.size()+
				MUTATIONS.size()
			],
			16,
			GOLD
		)
	)

	for t in trait_codex:
		content.add_child(
			make_label(
				"✓ "+str(t),
				16,
				GREEN
			)
		)

	content.add_child(
		make_button(
			"BACK TO GENETICS",
			show_genetics
		)
	)


func show_family_tree():
	clear_content()

	content.add_child(
		make_label(
			"GENETIC FAMILY TREE",
			29,
			RED
		)
	)

	if crosses.is_empty():
		content.add_child(
			make_label(
				"No crosses recorded yet.",
				16,
				MUTED
			)
		)

	for c in crosses:
		content.add_child(
			make_label(
				"%s • %s\nParents: %s\nStability %d%% • Seeds %d"%[
					c["name"],
					c.get(
						"generation",
						"F1"
					),
					" × ".join(
						c.get(
							"parents",
							[]
						)
					),
					c.get(
						"stability",
						60
					),
					c.get(
						"seeds",
						0
					)
				],
				16
			)
		)

	content.add_child(
		make_button(
			"BACK TO BREEDING",
			show_breeding
		)
	)


func stage_info(p:Dictionary)->Array:
	if p["age"]>=p["days"]:
		return [
			"✦",
			"HARVEST READY",
			GOLD
		]

	if p["age"]>p["days"]*0.45:
		return [
			"♣",
			"FLOWER",
			Color("#8eea75")
		]

	if p["age"]>1:
		return [
			"♠",
			"VEG",
			GREEN
		]

	return [
		"◆",
		"SEEDLING",
		Color("#a9e6b8")
	]


func show_grow():
	clear_content()

	content.add_child(
		make_label(
			"%s • %d/%d SITES"%[
				facility_data()["name"],
				plants.size(),
				grow_capacity()
			],
			25,
			RED
		)
	)

	var grid=GridContainer.new()
	grid.columns=2
	content.add_child(grid)

	for i in range(
		grow_capacity()
	):
		var site=panel()
		site.custom_minimum_size=Vector2(
			330,
			210
		)
		grid.add_child(site)

		var v=VBoxContainer.new()
		site.add_child(v)

		if i<plants.size():
			var p=plants[i]
			var st=stage_info(p)
			var score=genetic_score(p)
			var rarity=rarity_from_score(
				score
			)

			v.add_child(
				make_label(
					str(st[0])+
					" "+
					str(st[1]),
					23,
					st[2]
				)
			)

			v.add_child(
				make_label(
					"%s • %s"%[
						p["name"],
						rarity
					],
					15,
					rarity_color(
						rarity
					)
				)
			)

			var bar=ProgressBar.new()
			bar.max_value=p["days"]
			bar.value=p["age"]
			v.add_child(bar)

			v.add_child(
				make_label(
					"DAY %d/%d • G%d • Q%d • WATER %d%%"%[
						p["age"],
						p["days"],
						score,
						quality(p),
						p["water"]
					],
					13,
					MUTED
				)
			)

			if p.get(
				"problem",
				""
			)!="":
				v.add_child(
					make_button(
						"TREAT "+
						str(
							p["problem"]
						),
						func(idx=i):
							treat_plant(idx)
					)
				)

			if int(
				p["water"]
			)<45:
				v.add_child(
					make_button(
						"WATER",
						func(idx=i):
							water_plant(idx)
					)
				)

			if int(
				p["age"]
			)>=2 and not p.get(
				"trained",
				false
			):
				v.add_child(
					make_button(
						"TRAIN",
						func(idx=i):
							train_plant(idx)
					)
				)

			if int(
				p["age"]
			)>=2:
				v.add_child(
					make_button(
						"SAVE MOTHER",
						func(idx=i):
							save_mother(idx)
					)
				)

			if int(
				p["age"]
			)>=int(
				p["days"]
			):
				v.add_child(
					make_button(
						"HARVEST",
						func(idx=i):
							harvest(idx)
					)
				)

		else:
			v.add_child(
				make_label(
					"＋\nEMPTY GROW SITE",
					22,
					MUTED
				)
			)

	content.add_child(
		make_button(
			"ADVANCE 1 DAY",
			advance_day
		)
	)

	var controls=panel()
	content.add_child(controls)

	var cv=VBoxContainer.new()
	controls.add_child(cv)

	cv.add_child(
		make_label(
			"ENVIRONMENT CONTROL",
			20,
			RED
		)
	)

	light_slider=slider_row(
		cv,
		"LIGHT",
		25,
		100,
		55
	)

	rh_slider=slider_row(
		cv,
		"HUMIDITY",
		35,
		80,
		65
	)

	feed_slider=slider_row(
		cv,
		"FEED",
		5,
		24,
		12
	)

	content.add_child(
		make_label(
			"GENETIC VAULT • SEEDS",
			20,
			GOLD
		)
	)

	for name in genetics:
		var g=genetics[name]

		var b=make_button(
			"%s • $%d"%[
				name,
				g["cost"]
			],
			func(n=name):
				plant(n)
		)

		b.disabled=level<int(
			g["unlock"]
		)

		content.add_child(b)

	if not seed_inventory.is_empty():
		content.add_child(
			make_label(
				"BREEDER SEEDS",
				20,
				GOLD
			)
		)

		for i in range(
			seed_inventory.size()
		):
			var s=seed_inventory[i]

			content.add_child(
				make_button(
					"%s • %s • %d seeds"%[
						s["name"],
						s["generation"],
						s["count"]
					],
					func(idx=i):
						plant_bred_seed(idx)
				)
			)


func slider_row(
	parent:VBoxContainer,
	label:String,
	minv:float,
	maxv:float,
	val:float
)->HSlider:

	parent.add_child(
		make_label(
			label,
			13,
			MUTED
		)
	)

	var s=HSlider.new()
	s.min_value=minv
	s.max_value=maxv
	s.value=val
	s.step=1
	s.custom_minimum_size=Vector2(
		0,
		36
	)

	parent.add_child(s)
	return s


func quality(p:Dictionary)->int:
	var l=55.0
	var h=65.0
	var f=1.2

	if is_instance_valid(
		light_slider
	):
		l=light_slider.value

	if is_instance_valid(
		rh_slider
	):
		h=rh_slider.value

	if is_instance_valid(
		feed_slider
	):
		f=feed_slider.value/10.0

	var flower=p["age"]>p["days"]*0.45
	var q=100.0

	q-=abs(
		l-
		(82 if flower else 55)
	)*0.45

	q-=abs(
		h-
		(50 if flower else 65)
	)*0.7

	q-=abs(
		f-
		(1.8 if flower else 1.2)
	)*14

	q-=maxi(
		0,
		45-int(
			p.get(
				"water",
				100
			)
		)
	)*0.6

	if p.get(
		"trained",
		false
	):
		q+=4

	if p.get(
		"problem",
		""
	)!="":
		q-=8

	q*=float(
		p.get(
			"vigor",
			100
		)
	)/100.0

	if owned_upgrades[
		"LED Upgrade"
	]:
		q+=5

	if owned_upgrades[
		"Environment Controller"
	]:
		q+=5

	if "r2" in research_owned:
		q+=3

	if has_employee(
		"Grow Tech"
	):
		q+=2

	return clampi(
		roundi(q),
		35,
		100
	)


func create_plant(
	name:String,
	days:int,
	base:int,
	traits,
	genome:Dictionary={},
	parents:Array=[],
	generation:="Seed"
)->Dictionary:

	if genome.is_empty():
		genome=new_genome(name)

	return {
		"name":name,
		"age":0,
		"days":days,
		"base":base,
		"traits":traits,
		"water":100,
		"pheno":[
			"A",
			"B",
			"C",
			"D"
		][
			rng.randi_range(
				0,
				3
			)
		],
		"vigor":int(
			genome["stats"]["vigor"]
		),
		"trained":false,
		"problem":"",
		"genome":genome,
		"parents":parents,
		"generation":generation
	}


func plant(name:String):
	if plants.size()>=grow_capacity():
		return

	var g=genetics[name]

	if cash<int(g["cost"]):
		return

	cash-=int(g["cost"])
	total_expenses+=int(g["cost"])

	plants.append(
		create_plant(
			name,
			int(g["days"]),
			int(g["base"]),
			g["traits"]
		)
	)

	save_all()
	refresh_stats()
	show_grow()


func plant_bred_seed(i:int):
	if i<0 or i>=seed_inventory.size():
		return

	if plants.size()>=grow_capacity():
		return

	var s=seed_inventory[i]

	var genome=new_genome(
		str(s["name"]),
		s["parent_a"],
		s["parent_b"]
	)

	plants.append(
		create_plant(
			str(s["name"]),
			int(s["days"]),
			int(s["base"]),
			s["traits"],
			genome,
			s["parents"],
			str(s["generation"])
		)
	)

	s["count"]-=1

	if int(s["count"])<=0:
		seed_inventory.remove_at(i)

	save_all()
	show_grow()


func advance_day():
	day+=1

	for p in plants:
		p["age"]=min(
			int(p["age"])+1,
			int(p["days"])
		)

		p["water"]=maxi(
			0,
			int(
				p.get(
					"water",
					100
				)
			)-
			rng.randi_range(
				13,
				23
			)
		)

		if p.get(
			"problem",
			""
		)=="" and rng.randf()<0.08:
			p["problem"]=[
				"Light Stress",
				"Nutrient Imbalance",
				"Pests"
			][
				rng.randi_range(
					0,
					2
				)
			]

	process_tycoon_day()
	save_all()
	refresh_stats()
	show_grow()


func harvest(i:int):
	if i<0 or i>=plants.size():
		return

	var p=plants[i]

	discover_traits(
		p,
		2
	)

	record_genetic(p)

	var q=quality(p)
	var gs=genetic_score(p)

	var grams=roundi(
		(
			18.0+
			float(p["base"])/28.0
		)*
		(
			float(p["vigor"])/100.0
		)*
		(
			0.75+
			float(
				p["genome"]["stats"]["yield"]
			)/200.0
		)
	)

	inventory.append({
		"name":p["name"],
		"q":q,
		"genetic_score":gs,
		"rarity":rarity_from_score(gs),
		"grams":grams,
		"days":0,
		"pheno":p["pheno"]
	})

	xp+=roundi(
		30+
		q*0.55+
		gs*0.25
	)

	reputation+=maxi(
		1,
		roundi(
			q/12.0
		)
	)

	mission_harvests+=1

	unlock_achievement(
		"First Harvest"
	)

	if gs>=80:
		var exists=false

		for k in keepers:
			if k.get(
				"genome",
				{}
			).get(
				"id",
				""
			)==p["genome"]["id"]:
				exists=true

		if not exists:
			keepers.append(
				p.duplicate(true)
			)

			unlock_achievement(
				"Keeper Hunter"
			)

			if gs>=94:
				unlock_achievement(
					"Project 0 Verified"
				)

	plants.remove_at(i)

	level_up()
	save_all()
	refresh_stats()
	show_grow()


func level_up():
	while xp>=level*100:
		xp-=level*100
		level+=1


func water_plant(i:int):
	if i>=0 and i<plants.size():
		plants[i]["water"]=100
		save_all()
		show_grow()


func train_plant(i:int):
	if i>=0 and i<plants.size():
		plants[i]["trained"]=true
		reputation+=1
		save_all()
		show_grow()


func treat_plant(i:int):
	if i>=0 and i<plants.size() and cash>=25:
		cash-=25
		total_expenses+=25
		plants[i]["problem"]=""
		save_all()
		show_grow()


func save_mother(i:int):
	if i<0 or i>=plants.size():
		return

	if mothers.size()>=12:
		return

	var p=plants[i]

	for m in mothers:
		if m.get(
			"genome",
			{}
		).get(
			"id",
			""
		)==p["genome"]["id"]:
			return

	mothers.append(
		p.duplicate(true)
	)

	record_genetic(p)
	save_all()
	show_grow()


func show_breeding():
	clear_content()

	content.add_child(
		make_label(
			"PROJECT 0 • BREEDING LAB",
			29,
			RED
		)
	)

	content.add_child(
		make_label(
			"Mothers %d • Crosses %d • Seed Lots %d"%[
				mothers.size(),
				crosses.size(),
				seed_inventory.size()
			],
			16,
			GOLD
		)
	)

	for i in range(
		mothers.size()
	):
		var m=mothers[i]

		content.add_child(
			make_label(
				"%d. %s • %s • G%d"%[
					i+1,
					m["name"],
					m["genome"]["id"],
					genetic_score(m)
				],
				15
			)
		)

		content.add_child(
			make_button(
				"CLONE "+
				str(m["name"]),
				func(idx=i):
					clone_mother(idx)
			)
		)

	if mothers.size()>=2:
		content.add_child(
			make_button(
				"BREED MOTHER 1 × MOTHER 2",
				make_cross
			)
		)

	for c in crosses:
		content.add_child(
			make_label(
				"%s • %s • Stability %d%% • %d seeds"%[
					c["name"],
					c["generation"],
					c["stability"],
					c["seeds"]
				],
				15,
				MUTED
			)
		)

	content.add_child(
		make_button(
			"FAMILY TREE",
			show_family_tree
		)
	)


func clone_mother(i:int):
	if i<0 or i>=mothers.size():
		return

	if plants.size()>=grow_capacity():
		return

	var m=mothers[i].duplicate(true)

	m["age"]=0
	m["water"]=100
	m["problem"]=""
	m["name"]=str(m["name"])+" Clone"

	plants.append(m)

	save_all()
	show_grow()


func next_generation(a:String)->String:
	if a.begins_with("F"):
		var n=int(
			a.trim_prefix("F")
		)
		return "F"+str(n+1)

	return "F1"


func make_cross():
	if mothers.size()<2:
		return

	var a=mothers[0]
	var b=mothers[1]

	var cname=str(a["name"])+" × "+str(b["name"])
	var gen="F1"

	if str(a.get("name",""))==str(b.get("name","")):
		gen=next_generation(
			str(
				a.get(
					"generation",
					"F1"
				)
			)
		)

	var stability=clampi(
		roundi(
			(
				int(
					a["genome"]["stats"]["stability"]
				)+
				int(
					b["genome"]["stats"]["stability"]
				)
			)/2.0
		)+
		rng.randi_range(
			-5,
			8
		),
		30,
		100
	)

	if has_employee(
		"Breeding Tech"
	):
		stability=mini(
			100,
			stability+5
		)

	if "r3" in research_owned:
		stability=mini(
			100,
			stability+5
		)

	var seeds=rng.randi_range(
		3,
		7
	)

	var traits:Array=[]

	for t in a.get(
		"traits",
		[]
	):
		traits.append(t)

	for t in b.get(
		"traits",
		[]
	):
		if t not in traits:
			traits.append(t)

	var record={
		"name":cname,
		"parents":[
			a["genome"]["id"],
			b["genome"]["id"]
		],
		"generation":gen,
		"stability":stability,
		"seeds":seeds
	}

	crosses.append(record)

	seed_inventory.append({
		"name":cname,
		"generation":gen,
		"count":seeds,
		"days":10,
		"base":roundi(
			(
				int(a["base"])+
				int(b["base"])
			)/2.0
		),
		"traits":traits,
		"parents":record["parents"],
		"parent_a":a["genome"]["stats"],
		"parent_b":b["genome"]["stats"]
	})

	reputation+=15
	xp+=75

	unlock_achievement(
		"Breeder"
	)

	level_up()
	save_all()
	show_breeding()


func show_cure():
	clear_content()

	content.add_child(
		make_label(
			"DRY • CURE • FINISH",
			29,
			RED
		)
	)

	for i in range(
		inventory.size()
	):
		var c=inventory[i]

		content.add_child(
			make_button(
				"%s • %s • Q%d • %dg • CURE %d/3"%[
					c["name"],
					c.get(
						"rarity",
						"COMMON"
					),
					c["q"],
					c["grams"],
					c["days"]
				],
				func(idx=i):
					cure_day(idx)
			)
		)

	for i in range(
		cured_inventory.size()
	):
		var c=cured_inventory[i]

		content.add_child(
			make_button(
				"SELL • %s • $%d"%[
					c["name"],
					sale_value(c)
				],
				func(idx=i):
					sell_cured(idx)
			)
		)


func cure_day(i:int):
	if i<0 or i>=inventory.size():
		return

	inventory[i]["days"]+=1

	if inventory[i]["days"]>=3:
		cured_inventory.append(
			inventory[i]
		)
		inventory.remove_at(i)

	save_all()
	show_cure()


func sale_value(c:Dictionary)->int:
	var v=roundi(
		int(c["grams"])*
		(
			4.0+
			int(c["q"])/18.0
		)*
		(
			1.0+
			int(
				c.get(
					"genetic_score",
					60
				)
			)/250.0
		)
	)

	if has_employee(
		"Sales Rep"
	):
		v=roundi(
			v*1.10
		)

	return v


func sell_cured(i:int):
	if i<0 or i>=cured_inventory.size():
		return

	var v=sale_value(
		cured_inventory[i]
	)

	cash+=v
	total_revenue+=v

	cured_inventory.remove_at(i)

	save_all()
	refresh_stats()
	show_cure()


func show_market():
	clear_content()

	content.add_child(
		make_label(
			"UNDERGROUND MARKET",
			29,
			RED
		)
	)

	content.add_child(
		make_label(
			"Premium contract • 20g+ • Q80+",
			16,
			GOLD
		)
	)

	var eligible=-1

	for i in range(
		cured_inventory.size()
	):
		if int(
			cured_inventory[i]["q"]
		)>=80 and int(
			cured_inventory[i]["grams"]
		)>=20:
			eligible=i
			break

	if eligible>=0:
		content.add_child(
			make_button(
				"FULFILL PREMIUM CONTRACT",
				func(idx=eligible):
					fulfill_contract(idx)
			)
		)

	else:
		content.add_child(
			make_label(
				"No qualifying inventory.",
				16,
				MUTED
			)
		)

	content.add_child(
		make_label(
			"Contracts completed %d"%
			contracts_completed,
			16
		)
	)


func fulfill_contract(i:int):
	if i<0 or i>=cured_inventory.size():
		return

	var v=roundi(
		sale_value(
			cured_inventory[i]
		)*1.35
	)

	if "r4" in research_owned:
		v=roundi(
			v*1.15
		)

	cash+=v
	total_revenue+=v
	reputation+=12
	xp+=60
	contracts_completed+=1

	cured_inventory.remove_at(i)

	unlock_achievement(
		"Contract Killer"
	)

	level_up()
	save_all()
	refresh_stats()
	show_market()


func show_vault():
	clear_content()

	content.add_child(
		make_label(
			"PROJECT 0 • KEEPER VAULT",
			29,
			RED
		)
	)

	content.add_child(
		make_label(
			"PRESERVE THE GENETICS",
			16,
			GOLD
		)
	)

	content.add_child(
		make_label(
			"Keepers %d • Traits %d • Records %d"%[
				keepers.size(),
				trait_codex.size(),
				genetic_records.size()
			],
			15
		)
	)

	if keepers.is_empty():
		content.add_child(
			make_label(
				"Vault empty. Hunt ELITE+ phenotypes.",
				17,
				MUTED
			)
		)

	for k in keepers:
		var gs=genetic_score(k)
		var r=rarity_from_score(gs)
		var genome=k["genome"]

		content.add_child(
			make_label(
				"%s\n%s • %s • G%d\nTraits: %s"%[
					r,
					k["name"],
					genome["id"],
					gs,
					", ".join(
						genome.get(
							"discovered_traits",
							[]
						)
					)
				],
				16,
				rarity_color(r)
			)
		)

	content.add_child(
		make_button(
			"TRAIT CODEX",
			show_trait_codex
		)
	)

	content.add_child(
		make_button(
			"FAMILY TREE",
			show_family_tree
		)
	)


func mission_defs()->Array:
	return [
		{
			"id":"m01",
			"title":"Break Ground",
			"type":"plants",
			"goal":1,
			"cash":150,
			"xp":20
		},
		{
			"id":"m02",
			"title":"Keep Them Alive",
			"type":"day",
			"goal":3,
			"cash":200,
			"xp":25
		},
		{
			"id":"m03",
			"title":"First Harvest",
			"type":"harvests",
			"goal":1,
			"cash":300,
			"xp":40
		},
		{
			"id":"m04",
			"title":"Three Deep",
			"type":"harvests",
			"goal":3,
			"cash":1000,
			"xp":75
		},
		{
			"id":"m05",
			"title":"Level Up",
			"type":"level",
			"goal":2,
			"cash":350,
			"xp":40
		},
		{
			"id":"m06",
			"title":"Earn Respect",
			"type":"rep",
			"goal":20,
			"cash":450,
			"xp":50
		},
		{
			"id":"m07",
			"title":"Keeper Hunter",
			"type":"keepers",
			"goal":1,
			"cash":700,
			"xp":80
		},
		{
			"id":"m08",
			"title":"Project 0 Pair",
			"type":"keepers",
			"goal":2,
			"cash":900,
			"xp":100
		},
		{
			"id":"m09",
			"title":"Save The Cut",
			"type":"mothers",
			"goal":1,
			"cash":500,
			"xp":60
		},
		{
			"id":"m10",
			"title":"Mother Library",
			"type":"mothers",
			"goal":3,
			"cash":900,
			"xp":100
		},
		{
			"id":"m11",
			"title":"Genetic Depth",
			"type":"level",
			"goal":3,
			"cash":600,
			"xp":70
		},
		{
			"id":"m12",
			"title":"Vault Builder",
			"type":"keepers",
			"goal":3,
			"cash":1200,
			"xp":125
		},
		{
			"id":"m13",
			"title":"Make The Cross",
			"type":"crosses",
			"goal":1,
			"cash":1000,
			"xp":125
		},
		{
			"id":"m14",
			"title":"Breeder's Bench",
			"type":"crosses",
			"goal":2,
			"cash":1400,
			"xp":150
		},
		{
			"id":"m15",
			"title":"Deep Catalog",
			"type":"level",
			"goal":4,
			"cash":900,
			"xp":100
		},
		{
			"id":"m16",
			"title":"Preservation Crew",
			"type":"rep",
			"goal":60,
			"cash":1200,
			"xp":125
		},
		{
			"id":"m17",
			"title":"First Contract",
			"type":"contracts",
			"goal":1,
			"cash":800,
			"xp":90
		},
		{
			"id":"m18",
			"title":"Reliable Supplier",
			"type":"contracts",
			"goal":3,
			"cash":1600,
			"xp":175
		},
		{
			"id":"m19",
			"title":"Stack The Safe",
			"type":"cash",
			"goal":5000,
			"cash":1000,
			"xp":100
		},
		{
			"id":"m20",
			"title":"Known Name",
			"type":"rep",
			"goal":100,
			"cash":2000,
			"xp":200
		},
		{
			"id":"m21",
			"title":"Room Two",
			"type":"facility",
			"goal":2,
			"cash":1200,
			"xp":120
		},
		{
			"id":"m22",
			"title":"Ten Harvests",
			"type":"harvests",
			"goal":10,
			"cash":2500,
			"xp":250
		},
		{
			"id":"m23",
			"title":"Project 0 Vault",
			"type":"keepers",
			"goal":5,
			"cash":3000,
			"xp":300
		},
		{
			"id":"m24",
			"title":"Own The Show",
			"type":"level",
			"goal":6,
			"cash":5000,
			"xp":500
		},
		{
			"id":"g01",
			"title":"Trait Hunter",
			"type":"traits",
			"goal":3,
			"cash":1000,
			"xp":100
		},
		{
			"id":"g02",
			"title":"Genetic Archivist",
			"type":"records",
			"goal":5,
			"cash":1500,
			"xp":150
		},
		{
			"id":"g03",
			"title":"Seed Maker",
			"type":"seeds",
			"goal":1,
			"cash":1200,
			"xp":125
		},
		{
			"id":"g04",
			"title":"Legendary Hunt",
			"type":"legendary",
			"goal":1,
			"cash":3000,
			"xp":300
		}
	]


func mission_value(t:String)->int:
	match t:
		"plants":
			return plants.size()+mission_harvests

		"day":
			return day

		"harvests":
			return mission_harvests

		"level":
			return level

		"rep":
			return reputation

		"keepers":
			return keepers.size()

		"mothers":
			return mothers.size()

		"crosses":
			return crosses.size()

		"contracts":
			return contracts_completed

		"cash":
			return cash

		"facility":
			return facility_level

		"traits":
			return trait_codex.size()

		"records":
			return genetic_records.size()

		"seeds":
			return seed_inventory.size()

		"legendary":
			var n=0

			for k in keepers:
				if genetic_score(k)>=88:
					n+=1

			return n

	return 0


func show_missions():
	clear_content()

	content.add_child(
		make_label(
			"PROJECT 0 • CAMPAIGN",
			29,
			RED
		)
	)

	content.add_child(
		make_label(
			"%d / %d COMPLETE"%[
				mission_claimed.size(),
				mission_defs().size()
			],
			16,
			GOLD
		)
	)

	for m in mission_defs():
		var done=m["id"] in mission_claimed
		var value=mission_value(
			m["type"]
		)

		var card=panel()
		content.add_child(card)

		var v=VBoxContainer.new()
		card.add_child(v)

		v.add_child(
			make_label(
				(
					"✓ "
					if done
					else "◆ "
				)+
				str(m["title"]),
				17,
				GREEN if done else WHITE
			)
		)

		v.add_child(
			make_label(
				"%d/%d • $%d + %d XP"%[
					mini(
						value,
						int(m["goal"])
					),
					m["goal"],
					m["cash"],
					m["xp"]
				],
				14,
				GOLD
			)
		)

		if not done and value>=int(
			m["goal"]
		):
			v.add_child(
				make_button(
					"CLAIM",
					func(id=m["id"]):
						claim_campaign_mission(id)
				)
			)


func claim_campaign_mission(id:String):
	if id in mission_claimed:
		return

	for m in mission_defs():
		if m["id"]==id and mission_value(
			m["type"]
		)>=int(m["goal"]):

			mission_claimed.append(id)

			cash+=int(m["cash"])
			total_revenue+=int(m["cash"])
			xp+=int(m["xp"])
			reputation+=2

			if id=="m04" and facility_level<2:
				facility_level=2
				room_two_unlocked=true

				unlock_achievement(
					"Empire Builder"
				)

			level_up()
			save_all()
			refresh_stats()
			show_missions()
			return


func side_defs()->Array:
	var d:Array=[]
	var n=1

	var groups=[
		[
			"harvests",
			"Harvest Run",
			2,
			2,
			250
		],
		[
			"rep",
			"Build The Name",
			15,
			15,
			300
		],
		[
			"keepers",
			"Keeper Hunt",
			1,
			1,
			450
		],
		[
			"mothers",
			"Mother Room",
			1,
			1,
			400
		],
		[
			"crosses",
			"Breeding Work",
			1,
			1,
			650
		],
		[
			"contracts",
			"Market Work",
			1,
			1,
			600
		],
		[
			"cash",
			"Stack Cash",
			1500,
			1500,
			500
		],
		[
			"traits",
			"Trait Hunt",
			2,
			2,
			600
		],
		[
			"records",
			"Archive Work",
			3,
			3,
			650
		]
	]

	for g in groups:
		for tier in range(1,5):
			d.append({
				"id":"s%02d"%n,
				"title":str(g[1])+
				" "+
				str(tier),
				"type":g[0],
				"goal":int(g[2])+
				int(g[3])*
				(tier-1),
				"cash":int(g[4])*tier,
				"xp":20*tier
			})

			n+=1

	return d


func show_side_missions():
	clear_content()

	content.add_child(
		make_label(
			"SIDE MISSIONS",
			29,
			RED
		)
	)

	for m in side_defs():
		var done=m["id"] in side_claimed
		var v=mission_value(
			m["type"]
		)

		content.add_child(
			make_label(
				(
					"✓ "
					if done
					else "◆ "
				)+
				str(m["title"])+
				" • %d/%d"%[
					mini(
						v,
						int(m["goal"])
					),
					m["goal"]
				],
				15,
				GREEN if done else WHITE
			)
		)

		if not done and v>=int(
			m["goal"]
		):
			content.add_child(
				make_button(
					"CLAIM $%d"%
					m["cash"],
					func(id=m["id"]):
						claim_side(id)
				)
			)

	content.add_child(
		make_button(
			"BACK TO EMPIRE",
			show_empire
		)
	)


func claim_side(id:String):
	if id in side_claimed:
		return

	for m in side_defs():
		if m["id"]==id and mission_value(
			m["type"]
		)>=int(m["goal"]):

			side_claimed.append(id)

			cash+=int(m["cash"])
			total_revenue+=int(m["cash"])
			xp+=int(m["xp"])

			level_up()
			save_all()
			show_side_missions()
			return


func show_weekly():
	clear_content()

	content.add_child(
		make_label(
			"PROJECT 0 • WEEKLY",
			29,
			RED
		)
	)

	var cs=[
		{
			"id":"w1",
			"title":"Clock In",
			"value":day-weekly_start_day,
			"goal":2,
			"cash":300
		},
		{
			"id":"w2",
			"title":"Production Push",
			"value":mission_harvests-weekly_harvest_start,
			"goal":2,
			"cash":700
		},
		{
			"id":"w3",
			"title":"Build The Brand",
			"value":reputation-weekly_rep_start,
			"goal":15,
			"cash":800
		}
	]

	for c in cs:
		var done=c["id"] in weekly_claimed

		content.add_child(
			make_label(
				(
					"✓ "
					if done
					else "◆ "
				)+
				str(c["title"])+
				" • %d/%d"%[
					mini(
						int(c["value"]),
						int(c["goal"])
					),
					c["goal"]
				],
				16
			)
		)

		if not done and int(
			c["value"]
		)>=int(c["goal"]):

			content.add_child(
				make_button(
					"CLAIM $%d"%
					c["cash"],
					func(
						id=c["id"],
						reward=c["cash"]
					):
						claim_weekly(
							id,
							reward
						)
				)
			)

	content.add_child(
		make_button(
			"BACK TO EMPIRE",
			show_empire
		)
	)


func claim_weekly(
	id:String,
	reward:int
):
	if id in weekly_claimed:
		return

	weekly_claimed.append(id)

	cash+=reward
	total_revenue+=reward
	xp+=50

	level_up()
	save_all()
	show_weekly()


func show_research():
	clear_content()

	content.add_child(
		make_label(
			"PROJECT 0 • RESEARCH",
			29,
			RED
		)
	)

	for r in RESEARCH:
		var owned=r["id"] in research_owned

		content.add_child(
			make_label(
				"%s • %s"%[
					r["name"],
					(
						"COMPLETE"
						if owned
						else "$"+
						str(r["cost"])
					)
				],
				17,
				GREEN if owned else WHITE
			)
		)

		if not owned:
			content.add_child(
				make_button(
					"RESEARCH",
					func(id=r["id"]):
						buy_research(id)
				)
			)

	content.add_child(
		make_button(
			"BACK TO EMPIRE",
			show_empire
		)
	)


func buy_research(id:String):
	if id in research_owned:
		return

	for r in RESEARCH:
		if r["id"]==id:
			if cash<int(r["cost"]):
				return

			cash-=int(r["cost"])
			total_expenses+=int(r["cost"])

			research_owned.append(id)

			save_all()
			refresh_stats()
			show_research()
			return


func show_competitions():
	clear_content()

	content.add_child(
		make_label(
			"GENETICS COMPETITIONS",
			29,
			RED
		)
	)

	var events=[
		{
			"name":"Local Grow-Off",
			"fee":250,
			"rep":15,
			"reward":1000,
			"keepers":0
		},
		{
			"name":"Regional Genetics Cup",
			"fee":1000,
			"rep":40,
			"reward":5000,
			"keepers":1
		},
		{
			"name":"Project 0 Invitational",
			"fee":5000,
			"rep":100,
			"reward":20000,
			"keepers":3
		}
	]

	for e in events:
		content.add_child(
			make_button(
				"%s • $%d entry • $%d prize"%[
					e["name"],
					e["fee"],
					e["reward"]
				],
				func(ev=e):
					enter_competition(ev)
			)
		)

	content.add_child(
		make_button(
			"BACK TO EMPIRE",
			show_empire
		)
	)


func enter_competition(e:Dictionary):
	if cash<int(e["fee"]):
		return

	if keepers.size()<int(e["keepers"]):
		return

	cash-=int(e["fee"])
	total_expenses+=int(e["fee"])

	var best=0

	for k in keepers:
		best=maxi(
			best,
			genetic_score(k)
		)

	var score=
		reputation+
		level*10+
		best+
		crosses.size()*8+
		rng.randi_range(
			0,
			50
		)

	if has_employee(
		"Genetics Researcher"
	):
		score+=15

	if "r5" in research_owned:
		score+=20

	var target=
		90+
		int(e["keepers"])*35

	if score>=target:
		cash+=int(e["reward"])
		total_revenue+=int(e["reward"])
		reputation+=int(e["rep"])
		cups_won+=1

		event_log.append(
			"Won "+
			str(e["name"])
		)

		unlock_achievement(
			"Cup Winner"
		)

	else:
		event_log.append(
			"Placed outside the money at "+
			str(e["name"])
		)

	save_all()
	refresh_stats()
	show_competitions()


func show_shop():
	clear_content()

	content.add_child(
		make_label(
			"EMPIRE EQUIPMENT",
			29,
			RED
		)
	)

	var shop_items=[
		[
			"LED Upgrade",
			750
		],
		[
			"Environment Controller",
			1250
		]
	]

	for item in shop_items:
		var owned=owned_upgrades[
			item[0]
		]

		var text=str(
			item[0]
		)+" • "

		if owned:
			text+="OWNED"

		else:
			text+="$"+
			str(item[1])

		var b=make_button(
			text,
			func(
				n=item[0],
				c=item[1]
			):
				buy_upgrade(
					n,
					c
				)
		)

		b.disabled=owned
		content.add_child(b)

	content.add_child(
		make_button(
			"BACK TO EMPIRE",
			show_empire
		)
	)


func buy_upgrade(
	n:String,
	c:int
):
	if cash<c:
		return

	cash-=c
	total_expenses+=c
	owned_upgrades[n]=true

	save_all()
	refresh_stats()
	show_shop()


func show_finances():
	clear_content()

	content.add_child(
		make_label(
			"EMPIRE FINANCES",
			29,
			RED
		)
	)

	content.add_child(
		make_label(
			"Cash $%d\nRevenue $%d\nExpenses $%d\nNet $%d\nPayroll $%d\nOverhead $%d\nEmpire Value $%d"%[
				cash,
				total_revenue,
				total_expenses,
				total_revenue-
				total_expenses,
				employee_payroll(),
				facility_data()["overhead"],
				business_value()
			],
			18
		)
	)

	content.add_child(
		make_button(
			"BACK TO EMPIRE",
			show_empire
		)
	)


func process_tycoon_day():
	if day-last_bill_day>=5:
		var bills=
			int(
				facility_data()["overhead"]
			)+
			employee_payroll()

		if "r1" in research_owned:
			bills=roundi(
				bills*0.9
			)

		cash-=bills
		total_expenses+=bills
		last_bill_day=day

		event_log.append(
			"Day %d bills paid: $%d"%[
				day,
				bills
			]
		)

	if day-weekly_start_day>=7:
		weekly_start_day=day
		weekly_harvest_start=mission_harvests
		weekly_rep_start=reputation
		weekly_claimed.clear()

		event_log.append(
			"New weekly challenges."
		)

	if rng.randf()<0.13:
		trigger_empire_event()


func trigger_empire_event():
	match rng.randi_range(0,5):
		0:
			var b=150+level*40
			cash+=b
			total_revenue+=b
			event_log.append(
				"Local buzz +$%d"%b
			)

		1:
			var c=75+facility_level*35
			cash-=c
			total_expenses+=c
			event_log.append(
				"Equipment repair -$%d"%c
			)

		2:
			reputation+=4
			event_log.append(
				"Genetics buzz +4 reputation"
			)

		3:
			xp+=35
			level_up()
			event_log.append(
				"Crew training +35 XP"
			)

		4:
			var b=100+keepers.size()*25
			cash+=b
			total_revenue+=b
			event_log.append(
				"Collector premium +$%d"%b
			)

		5:
			event_log.append(
				"Quiet day. Empire keeps moving."
			)


func unlock_achievement(id:String):
	if id not in achievements:
		achievements.append(id)


func show_achievements():
	clear_content()

	content.add_child(
		make_label(
			"ACHIEVEMENTS",
			29,
			RED
		)
	)

	var defs=[
		[
			"First Harvest",
			"Complete a harvest"
		],
		[
			"Keeper Hunter",
			"Preserve an Elite phenotype"
		],
		[
			"Breeder",
			"Create a cross"
		],
		[
			"Contract Killer",
			"Complete a contract"
		],
		[
			"Empire Builder",
			"Expand the operation"
		],
		[
			"Cup Winner",
			"Win a competition"
		],
		[
			"Project 0 Verified",
			"Discover a G94+ phenotype"
		]
	]

	for a in defs:
		var done=a[0] in achievements

		content.add_child(
			make_label(
				(
					"✓ "
					if done
					else "○ "
				)+
				str(a[0])+
				"\n"+
				str(a[1]),
				16,
				GREEN if done else MUTED
			)
		)

	content.add_child(
		make_button(
			"BACK TO EMPIRE",
			show_empire
		)
	)


func save_all():
	save_game()
	tycoon_save()


func save_game():
	var d={
		"cash":cash,
		"xp":xp,
		"level":level,
		"reputation":reputation,
		"day":day,
		"plants":plants,
		"keepers":keepers,
		"mothers":mothers,
		"crosses":crosses,
		"seed_inventory":seed_inventory,
		"inventory":inventory,
		"cured_inventory":cured_inventory,
		"achievements":achievements,
		"mission_claimed":mission_claimed,
		"mission_harvests":mission_harvests,
		"contracts_completed":contracts_completed,
		"facility_level":facility_level,
		"room_two_unlocked":room_two_unlocked,
		"upgrades":owned_upgrades,
		"trait_codex":trait_codex,
		"genetic_records":genetic_records,
		"phenotype_counter":phenotype_counter
	}

	var f=FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if f:
		f.store_string(
			JSON.stringify(d)
		)


func load_game():
	if not FileAccess.file_exists(
		SAVE_PATH
	):
		return

	var f=FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if not f:
		return

	var d=JSON.parse_string(
		f.get_as_text()
	)

	if typeof(d)!=TYPE_DICTIONARY:
		return

	cash=int(
		d.get(
			"cash",
			500
		)
	)

	xp=int(
		d.get(
			"xp",
			0
		)
	)

	level=int(
		d.get(
			"level",
			1
		)
	)

	reputation=int(
		d.get(
			"reputation",
			0
		)
	)

	day=int(
		d.get(
			"day",
			1
		)
	)

	plants=d.get(
		"plants",
		[]
	)

	keepers=d.get(
		"keepers",
		[]
	)

	mothers=d.get(
		"mothers",
		[]
	)

	crosses=d.get(
		"crosses",
		[]
	)

	seed_inventory=d.get(
		"seed_inventory",
		[]
	)

	inventory=d.get(
		"inventory",
		[]
	)

	cured_inventory=d.get(
		"cured_inventory",
		[]
	)

	achievements=d.get(
		"achievements",
		[]
	)

	mission_claimed=d.get(
		"mission_claimed",
		[]
	)

	mission_harvests=int(
		d.get(
			"mission_harvests",
			0
		)
	)

	contracts_completed=int(
		d.get(
			"contracts_completed",
			0
		)
	)

	facility_level=int(
		d.get(
			"facility_level",
			1
		)
	)

	room_two_unlocked=bool(
		d.get(
			"room_two_unlocked",
			false
		)
	)

	owned_upgrades=d.get(
		"upgrades",
		owned_upgrades
	)

	trait_codex=d.get(
		"trait_codex",
		[]
	)

	genetic_records=d.get(
		"genetic_records",
		{}
	)

	phenotype_counter=int(
		d.get(
			"phenotype_counter",
			0
		)
	)

	for p in plants:
		if not p.has("water"):
			p["water"]=100

		if not p.has("pheno"):
			p["pheno"]="A"

		if not p.has("vigor"):
			p["vigor"]=100

		if not p.has("trained"):
			p["trained"]=false

		if not p.has("problem"):
			p["problem"]=""


func tycoon_save():
	var d={
		"total_revenue":total_revenue,
		"total_expenses":total_expenses,
		"employees":employees,
		"side_claimed":side_claimed,
		"weekly_claimed":weekly_claimed,
		"research_owned":research_owned,
		"cups_won":cups_won,
		"event_log":event_log,
		"last_bill_day":last_bill_day,
		"weekly_start_day":weekly_start_day,
		"weekly_harvest_start":weekly_harvest_start,
		"weekly_rep_start":weekly_rep_start
	}

	var f=FileAccess.open(
		TYCOON_SAVE_PATH,
		FileAccess.WRITE
	)

	if f:
		f.store_string(
			JSON.stringify(d)
		)


func tycoon_load():
	if not FileAccess.file_exists(
		TYCOON_SAVE_PATH
	):
		last_bill_day=day
		weekly_start_day=day
		weekly_harvest_start=mission_harvests
		weekly_rep_start=reputation
		return

	var f=FileAccess.open(
		TYCOON_SAVE_PATH,
		FileAccess.READ
	)

	if not f:
		return

	var d=JSON.parse_string(
		f.get_as_text()
	)

	if typeof(d)!=TYPE_DICTIONARY:
		return

	total_revenue=int(
		d.get(
			"total_revenue",
			0
		)
	)

	total_expenses=int(
		d.get(
			"total_expenses",
			0
		)
	)

	employees=d.get(
		"employees",
		[]
	)

	side_claimed=d.get(
		"side_claimed",
		[]
	)

	weekly_claimed=d.get(
		"weekly_claimed",
		[]
	)

	research_owned=d.get(
		"research_owned",
		[]
	)

	cups_won=int(
		d.get(
			"cups_won",
			0
		)
	)

	event_log=d.get(
		"event_log",
		[]
	)

	last_bill_day=int(
		d.get(
			"last_bill_day",
			day
		)
	)

	weekly_start_day=int(
		d.get(
			"weekly_start_day",
			day
		)
	)

	weekly_harvest_start=int(
		d.get(
			"weekly_harvest_start",
			mission_harvests
		)
	)

	weekly_rep_start=int(
		d.get(
			"weekly_rep_start",
			reputation
		)
	)
