extends Control

const RED = Color("#d30b16")
const RED_DARK = Color("#6d070d")
const DARK = Color("#080808")
const PANEL = Color("#171717")
const PANEL_2 = Color("#222222")
const WHITE = Color("#ffffff")
const MUTED = Color("#b7b7b7")
const GREEN = Color("#4ee17a")
const GOLD = Color("#e7b94a")
const SAVE_PATH = "user://grow_empire_save.json"

var cash := 500
var xp := 0
var level := 1
var reputation := 0
var day := 1
var plants: Array = []
var keepers: Array = []
var mothers: Array = []
var crosses: Array = []
var inventory: Array = []
var cured_inventory: Array = []
var achievements: Array = []
var mission_claimed: Array = []
var mission_harvests := 0
var contracts_completed := 0
var facility_level := 1
var room_two_unlocked := false
var owned_upgrades := {
	"LED Upgrade": false,
	"Environment Controller": false
}
var rng := RandomNumberGenerator.new()

var genetics = {
	"GG4 S1": {
		"cost": 40,
		"days": 8,
		"base": 230,
		"unlock": 1,
		"traits": "Gas • Resin • Vigor"
	},
	"Slurricane #7": {
		"cost": 75,
		"days": 10,
		"base": 390,
		"unlock": 2,
		"traits": "Grape • Frost • Color"
	},
	"RKS S1": {
		"cost": 120,
		"days": 12,
		"base": 620,
		"unlock": 3,
		"traits": "Skunk • Funk • Preservation"
	},
	"Queen's Revenge S1": {
		"cost": 180,
		"days": 14,
		"base": 950,
		"unlock": 4,
		"traits": "Exotic • Resin • Keeper"
	}
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
    tycoon_boot()
	build_ui()
	show_title()


func make_label(text: String, size := 18, color := WHITE) -> Label:
	var l = Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l


func make_button(text: String, callback: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0, 52)
	b.add_theme_font_size_override("font_size", 16)

	var sb = StyleBoxFlat.new()
	sb.bg_color = RED
	sb.corner_radius_top_left = 10
	sb.corner_radius_top_right = 10
	sb.corner_radius_bottom_left = 10
	sb.corner_radius_bottom_right = 10
	sb.border_width_left = 1
	sb.border_width_right = 1
	sb.border_width_top = 1
	sb.border_width_bottom = 1
	sb.border_color = Color("#ff5961")

	b.add_theme_stylebox_override("normal", sb)
	b.pressed.connect(callback)
	return b


func panel() -> PanelContainer:
	var p = PanelContainer.new()
	var sb = StyleBoxFlat.new()

	sb.bg_color = PANEL
	sb.corner_radius_top_left = 14
	sb.corner_radius_top_right = 14
	sb.corner_radius_bottom_left = 14
	sb.corner_radius_bottom_right = 14
	sb.border_width_top = 2
	sb.border_color = RED

	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14

	p.add_theme_stylebox_override("panel", sb)
	return p


func build_ui():
	var bg = ColorRect.new()
	bg.color = DARK
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	var outer = VBoxContainer.new()
	outer.custom_minimum_size = Vector2(680, 0)
	outer.add_theme_constant_override("separation", 10)
	scroll.add_child(outer)

	var head = panel()
	outer.add_child(head)

	var hv = VBoxContainer.new()
	head.add_child(hv)

	var brand = make_label("SHOCKER OWNZ", 18, RED)
	brand.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(brand)

	var title = make_label("GROW EMPIRE", 36)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(title)

	var motto = make_label(
		"PROJECT 0 • GENETICS WITHOUT COMPROMISE",
		13,
		MUTED
	)
	motto.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(motto)

	stats_label = make_label("", 16)
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hv.add_child(stats_label)

	var nav = GridContainer.new()
	nav.columns = 4
	nav.add_theme_constant_override("h_separation", 5)
	nav.add_theme_constant_override("v_separation", 5)
	outer.add_child(nav)

	var nav_items = [
        ["EMPIRE", show_empire],
		["GROW", show_grow],
		["GENETICS", show_genetics],
		["BREED", show_breeding],
		["CURE", show_cure],
		["PROJECT 0", show_vault],
		["MARKET", show_market],
		["SHOP", show_shop],
		["MISSIONS", show_missions]
	]

	for item in nav_items:
		var b = make_button(item[0], item[1])
		b.custom_minimum_size = Vector2(165, 48)
		nav.add_child(b)

	content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	outer.add_child(content)

	refresh_stats()


func clear_content():
	for c in content.get_children():
		c.queue_free()


func refresh_stats():
	stats_label.text = "$%d   LV %d   XP %d/%d   REP %d   DAY %d" % [
		cash,
		level,
		xp,
		level * 100,
		reputation,
		day
	]


func show_title():
	clear_content()

	var hero = panel()
	content.add_child(hero)

	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	hero.add_child(v)

	var t = make_label("⚠  SHOCKER OWNZ  ⚠", 24, RED)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t)

	var g = make_label("GROW EMPIRE", 46)
	g.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(g)

	var art = TextureRect.new()
	var tex = load("res://shocker_ownz_reference.jpg")

	if tex:
		art.texture = tex
		art.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.custom_minimum_size = Vector2(0, 300)
		v.add_child(art)

	var sub = make_label(
		"PROJECT 0 • PRESERVE THE GENETICS",
		16,
		GOLD
	)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(sub)

	v.add_child(make_button("ENTER THE GROW", show_grow))
	v.add_child(make_button("PROJECT 0 CAMPAIGN", show_missions))
	v.add_child(make_button("ACHIEVEMENTS", show_achievements))


func stage_info(p: Dictionary) -> Array:
	if p.age >= p.days:
		return ["✦", "HARVEST READY", GOLD]

	if p.age > p.days * 0.45:
		return ["♣", "FLOWER", Color("#8eea75")]

	if p.age > 1:
		return ["♠", "VEG", GREEN]

	return ["◆", "SEEDLING", Color("#a9e6b8")]


func show_grow():
	clear_content()

	var banner = panel()
	content.add_child(banner)

	var bv = VBoxContainer.new()
	banner.add_child(bv)

	bv.add_child(
		make_label(
			"ROOM %02d • UNDERGROUND GROW" % facility_level,
			25,
			RED
		)
	)

	bv.add_child(
		make_label(
			"Grow Like You Own The Show.",
			15,
			GOLD
		)
	)

	if room_two_unlocked:
		bv.add_child(
			make_label(
				"● ROOM 02 ONLINE",
				14,
				GREEN
			)
		)

	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	content.add_child(grid)

	for i in range(4):
		var site = panel()
		site.custom_minimum_size = Vector2(330, 220)
		grid.add_child(site)

		var sv = VBoxContainer.new()
		site.add_child(sv)

		if i < plants.size():
			var p = plants[i]
			var st = stage_info(p)

			var stage = make_label(
				st[0] + "  " + st[1],
				28,
				st[2]
			)
			stage.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(stage)

			sv.add_child(
				make_label(
					p.name + " • PHENO " + str(p.pheno),
					17
				)
			)

			var growbar = ProgressBar.new()
			growbar.max_value = p.days
			growbar.value = p.age
			growbar.custom_minimum_size = Vector2(0, 20)
			sv.add_child(growbar)

			sv.add_child(
				make_label(
					"DAY %d/%d • Q%d • WATER %d%%" % [
						p.age,
						p.days,
						quality(p),
						p.water
					],
					14,
					MUTED
				)
			)

			if p.get("problem", "") != "":
				sv.add_child(
					make_button(
						"⚠ TREAT " + p.problem,
						func(): treat_plant(i)
					)
				)

			if p.water < 45:
				sv.add_child(
					make_button(
						"WATER",
						func(): water_plant(i)
					)
				)

			if p.age >= 2 and p.age < p.days * 0.45 and not p.get("trained", false):
				sv.add_child(
					make_button(
						"TRAIN",
						func(): train_plant(i)
					)
				)

			if p.age >= maxi(2, roundi(p.days * 0.35)):
				sv.add_child(
					make_button(
						"SAVE MOTHER",
						func(): save_mother(i)
					)
				)

			if p.age >= p.days:
				sv.add_child(
					make_button(
						"HARVEST",
						func(): harvest(i)
					)
				)

		else:
			var empty = make_label("＋", 52, MUTED)
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(empty)

			var et = make_label(
				"EMPTY GROW SITE",
				15,
				MUTED
			)
			et.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			sv.add_child(et)

	content.add_child(
		make_button(
			"ADVANCE 1 DAY",
			advance_day
		)
	)

	var controls = panel()
	content.add_child(controls)

	var cv = VBoxContainer.new()
	controls.add_child(cv)

	cv.add_child(
		make_label(
			"ENVIRONMENT CONTROL",
			20,
			RED
		)
	)

	light_slider = slider_row(
		cv,
		"LIGHT",
		25,
		100,
		55
	)

	rh_slider = slider_row(
		cv,
		"HUMIDITY",
		35,
		80,
		65
	)

	feed_slider = slider_row(
		cv,
		"FEED",
		5,
		24,
		12
	)

	var seeds = panel()
	content.add_child(seeds)

	var se = VBoxContainer.new()
	seeds.add_child(se)

	se.add_child(
		make_label(
			"GENETIC VAULT • SEEDS",
			20,
			GOLD
		)
	)

	for name in genetics:
		var x = genetics[name]
		var locked = level < x.unlock

		var button_text = "%s • $%d" % [
			name,
			x.cost
		]

		if locked:
			button_text += " • LV " + str(x.unlock)

		var b = make_button(
			button_text,
			func(n = name): plant(n)
		)

		b.disabled = locked
		se.add_child(b)

	log_label = make_label(
		"Room status: operational.",
		14,
		MUTED
	)
	content.add_child(log_label)


func slider_row(
	parent: VBoxContainer,
	label: String,
	minv: float,
	maxv: float,
	val: float
) -> HSlider:

	parent.add_child(
		make_label(
			label,
			13,
			MUTED
		)
	)

	var s = HSlider.new()
	s.min_value = minv
	s.max_value = maxv
	s.value = val
	s.step = 1
	s.custom_minimum_size = Vector2(0, 36)

	parent.add_child(s)
	return s


func quality(p: Dictionary) -> int:
	var l = light_slider.value if is_instance_valid(light_slider) else 70.0
	var h = rh_slider.value if is_instance_valid(rh_slider) else 57.0
	var f = feed_slider.value / 10.0 if is_instance_valid(feed_slider) else 1.5

	var flower = p.age > p.days * 0.45

	var q = 100.0
	q -= abs(l - (82 if flower else 55)) * 0.45
	q -= abs(h - (50 if flower else 65)) * 0.7
	q -= abs(f - (1.8 if flower else 1.2)) * 14

	q -= maxi(
		0,
		45 - int(p.get("water", 100))
	) * 0.6

	if p.get("trained", false):
		q += 4

	if p.get("problem", "") != "":
		q -= 8

	q *= float(p.get("vigor", 100)) / 100.0

	if owned_upgrades["LED Upgrade"]:
		q += 5

	if owned_upgrades["Environment Controller"]:
		q += 5

	return clampi(
		roundi(q),
		35,
		100
	)


func plant(name: String):
	var g = genetics[name]

	if plants.size() >= 4:
		return

	if cash < g.cost:
		return

	cash -= g.cost

	var phenos = [
		"A",
		"B",
		"C",
		"D"
	]

	plants.append({
		"name": name,
		"age": 0,
		"days": g.days,
		"base": g.base,
		"traits": g.traits,
		"water": 100,
		"pheno": phenos[rng.randi_range(0, 3)],
		"vigor": rng.randi_range(88, 112),
		"trained": false,
		"problem": ""
	})
    process_tycoon_day()
	save_game()
	refresh_stats()
	show_grow()


func advance_day():
	day += 1

	for p in plants:
		p.age = min(
			p.age + 1,
			p.days
		)

		p.water = maxi(
			0,
			int(p.get("water", 100)) - rng.randi_range(13, 23)
		)

		if p.get("problem", "") == "" and rng.randf() < 0.08:
			var probs = [
				"Light Stress",
				"Nutrient Imbalance",
				"Pests"
			]

			p.problem = probs[
				rng.randi_range(0, 2)
			]
    process_tycoon_day()
	save_game()
	refresh_stats()
	show_grow()


func harvest(i: int):
	if i < 0 or i >= plants.size():
		return

	var p = plants[i]
	var q = quality(p)

	var grams = roundi(
		(18.0 + p.base / 28.0) *
		(float(p.vigor) / 100.0)
	)

	inventory.append({
		"name": p.name,
		"q": q,
		"grams": grams,
		"days": 0,
		"pheno": p.pheno
	})

	xp += roundi(
		30 + q * 0.55
	)

	reputation += maxi(
		1,
		roundi(q / 12.0)
	)

	mission_harvests += 1

	unlock_achievement(
		"First Harvest"
	)

	if q >= 90:
		var exists = keepers.any(
			func(k):
				return k.name == p.name and k.pheno == p.pheno
		)

		if not exists:
			keepers.append({
				"name": p.name,
				"q": q,
				"traits": p.traits,
				"pheno": p.pheno
			})

			unlock_achievement(
				"Keeper Hunter"
			)

	plants.remove_at(i)

	level_up()
	save_game()
	refresh_stats()
	show_grow()


func level_up():
	while xp >= level * 100:
		xp -= level * 100
		level += 1


func water_plant(i: int):
	if i >= 0 and i < plants.size():
		plants[i].water = 100
		save_game()
		show_grow()


func train_plant(i: int):
	if i >= 0 and i < plants.size():
		plants[i].trained = true
		reputation += 1
		save_game()
		show_grow()


func treat_plant(i: int):
	if i >= 0 and i < plants.size() and cash >= 25:
		cash -= 25
		plants[i].problem = ""
		save_game()
		show_grow()


func save_mother(i: int):
	if i < 0 or i >= plants.size():
		return

	if mothers.size() >= 6:
		return

	var p = plants[i]

	var exists = mothers.any(
		func(m):
			return m.name == p.name and m.pheno == p.pheno
	)

	if exists:
		return

	mothers.append({
		"name": p.name,
		"pheno": p.pheno,
		"q": quality(p),
		"traits": p.traits,
		"vigor": p.vigor
	})

	save_game()
	show_grow()

func show_genetics():
	clear_content()

	var p = panel()
	content.add_child(p)

	var v = VBoxContainer.new()
	p.add_child(v)

	v.add_child(
		make_label(
			"GENETICS LIBRARY",
			27,
			RED
		)
	)

	for name in genetics:
		var g = genetics[name]

		v.add_child(
			make_label(
				"◆ %s • LV %d\n%s\nSeed $%d • Cycle %d days" % [
					name,
					g.unlock,
					g.traits,
					g.cost,
					g.days
				],
				17,
				WHITE
			)
		)


func show_breeding():
	clear_content()

	var p = panel()
	content.add_child(p)

	var v = VBoxContainer.new()
	p.add_child(v)

	v.add_child(
		make_label(
			"PROJECT 0 • BREEDING LAB",
			27,
			RED
		)
	)

	v.add_child(
		make_label(
			"MOTHERS %d/6 • CROSSES %d" % [
				mothers.size(),
				crosses.size()
			],
			15,
			GOLD
		)
	)

	for i in range(mothers.size()):
		var m = mothers[i]

		v.add_child(
			make_button(
				"CLONE • %s PHENO %s • Q%d" % [
					m.name,
					m.pheno,
					m.q
				],
				func(idx = i): clone_mother(idx)
			)
		)

	if mothers.size() >= 2:
		v.add_child(
			make_button(
				"CREATE CROSS • %s × %s" % [
					mothers[0].name,
					mothers[1].name
				],
				make_cross
			)
		)

	for c in crosses:
		v.add_child(
			make_label(
				"DNA ◆ %s\n%s • Stability %d%%" % [
					c.name,
					c.traits,
					c.stability
				],
				16,
				MUTED
			)
		)


func clone_mother(i: int):
	if i < 0 or i >= mothers.size():
		return

	if plants.size() >= 4:
		return

	var m = mothers[i]
	var base = 300

	if genetics.has(m.name):
		base = genetics[m.name].base

	plants.append({
		"name": m.name + " Clone",
		"age": 0,
		"days": 9,
		"base": base,
		"traits": m.traits,
		"water": 100,
		"pheno": m.pheno,
		"vigor": m.vigor,
		"trained": false,
		"problem": ""
	})

	save_game()
	show_grow()


func make_cross():
	if mothers.size() < 2:
		return

	var a = mothers[0]
	var b = mothers[1]
	var cname = a.name + " × " + b.name

	var exists = crosses.any(
		func(c):
			return c.name == cname
	)

	if exists:
		return

	crosses.append({
		"name": cname,
		"traits": a.traits + " • " + b.traits,
		"stability": rng.randi_range(55, 82)
	})

	reputation += 15
	xp += 75

	unlock_achievement("Breeder")
	level_up()
	save_game()
	refresh_stats()
	show_breeding()


func show_cure():
	clear_content()

	var p = panel()
	content.add_child(p)

	var v = VBoxContainer.new()
	p.add_child(v)

	v.add_child(
		make_label(
			"DRY • CURE • FINISH",
			27,
			RED
		)
	)

	if inventory.is_empty() and cured_inventory.is_empty():
		v.add_child(
			make_label(
				"No harvests in processing.",
				17,
				MUTED
			)
		)

	for i in range(inventory.size()):
		var c = inventory[i]

		v.add_child(
			make_button(
				"%s • Q%d • %dg • CURE %d/3" % [
					c.name,
					c.q,
					c.grams,
					c.days
				],
				func(idx = i): cure_day(idx)
			)
		)

	for i in range(cured_inventory.size()):
		var c = cured_inventory[i]

		v.add_child(
			make_button(
				"SELL • %s • Q%d • $%d" % [
					c.name,
					c.q,
					sale_value(c)
				],
				func(idx = i): sell_cured(idx)
			)
		)


func cure_day(i: int):
	if i < 0 or i >= inventory.size():
		return

	inventory[i].days += 1

	if inventory[i].days >= 3:
		cured_inventory.append(
			inventory[i]
		)
		inventory.remove_at(i)

	save_game()
	show_cure()


func sale_value(c: Dictionary) -> int:
	return roundi(
		c.grams *
		(4.0 + c.q / 18.0)
	)


func sell_cured(i: int):
	if i < 0 or i >= cured_inventory.size():
		return

	cash += sale_value(
		cured_inventory[i]
	)

	cured_inventory.remove_at(i)

	save_game()
	refresh_stats()
	show_cure()


func show_market():
	clear_content()

	var p = panel()
	content.add_child(p)

	var v = VBoxContainer.new()
	p.add_child(v)

	v.add_child(
		make_label(
			"UNDERGROUND MARKET",
			27,
			RED
		)
	)

	v.add_child(
		make_label(
			"PREMIUM SHELF CONTRACT • Need 20g+ at Q80+",
			16,
			GOLD
		)
	)

	var eligible = -1

	for i in range(cured_inventory.size()):
		if cured_inventory[i].q >= 80 and cured_inventory[i].grams >= 20:
			eligible = i
			break

	if eligible >= 0:
		var c = cured_inventory[eligible]

		v.add_child(
			make_button(
				"FULFILL • %s • Q%d • %dg" % [
					c.name,
					c.q,
					c.grams
				],
				func(idx = eligible): fulfill_contract(idx)
			)
		)
	else:
		v.add_child(
			make_label(
				"No qualifying cured inventory.",
				16,
				MUTED
			)
		)

	v.add_child(
		make_label(
			"CONTRACTS COMPLETED • %d" % contracts_completed,
			17
		)
	)


func fulfill_contract(i: int):
	if i < 0 or i >= cured_inventory.size():
		return

	var c = cured_inventory[i]

	cash += roundi(
		sale_value(c) * 1.35
	)

	reputation += 12
	xp += 60
	contracts_completed += 1

	cured_inventory.remove_at(i)

	unlock_achievement(
		"Contract Killer"
	)

	level_up()
	save_game()
	refresh_stats()
	show_market()


func show_shop():
	clear_content()

	var p = panel()
	content.add_child(p)

	var v = VBoxContainer.new()
	p.add_child(v)

	v.add_child(
		make_label(
			"EMPIRE EQUIPMENT",
			27,
			RED
		)
	)

	var shop_items = [
		["LED Upgrade", 750],
		["Environment Controller", 1250]
	]

	for item in shop_items:
		var owned = owned_upgrades[item[0]]

		var text = item[0] + " • "

		if owned:
			text += "OWNED"
		else:
			text += "$" + str(item[1])

		var b = make_button(
			text,
			func(n = item[0], c = item[1]): buy_upgrade(n, c)
		)

		b.disabled = owned
		v.add_child(b)


func buy_upgrade(n: String, c: int):
	if cash < c:
		return

	cash -= c
	owned_upgrades[n] = true

	save_game()
	refresh_stats()
	show_shop()


func show_vault():
	clear_content()

	var p = panel()
	content.add_child(p)

	var v = VBoxContainer.new()
	p.add_child(v)

	v.add_child(
		make_label(
			"PROJECT 0 • KEEPER VAULT",
			27,
			RED
		)
	)

	v.add_child(
		make_label(
			"PRESERVE THE GENETICS",
			16,
			GOLD
		)
	)

	if keepers.is_empty():
		v.add_child(
			make_label(
				"Vault empty. Hunt Q90+ phenotypes.",
				17,
				MUTED
			)
		)

	for k in keepers:
		v.add_child(
			make_label(
				"PROJECT 0 VERIFIED\n%s • PHENO %s • Q%d\n%s" % [
					k.name,
					k.get("pheno", "A"),
					k.q,
					k.traits
				],
				17,
				WHITE
			)
		)


func mission_defs() -> Array:
	return [
		{
			"id": "m01",
			"chapter": "CHAPTER 1 • FIRST ROOTS",
			"title": "Break Ground",
			"desc": "Plant your first genetic.",
			"type": "plants",
			"goal": 1,
			"cash": 150,
			"xp": 20
		},
		{
			"id": "m02",
			"chapter": "CHAPTER 1 • FIRST ROOTS",
			"title": "Keep Them Alive",
			"desc": "Reach Day 3.",
			"type": "day",
			"goal": 3,
			"cash": 200,
			"xp": 25
		},
		{
			"id": "m03",
			"chapter": "CHAPTER 1 • FIRST ROOTS",
			"title": "First Harvest",
			"desc": "Complete your first harvest.",
			"type": "harvests",
			"goal": 1,
			"cash": 300,
			"xp": 40
		},
		{
			"id": "m04",
			"chapter": "CHAPTER 1 • FIRST ROOTS",
			"title": "Three Deep",
			"desc": "Complete 3 harvests.",
			"type": "harvests",
			"goal": 3,
			"cash": 1000,
			"xp": 75
		},
		{
			"id": "m05",
			"chapter": "CHAPTER 2 • PHENO HUNT",
			"title": "Level Up",
			"desc": "Reach grower level 2.",
			"type": "level",
			"goal": 2,
			"cash": 350,
			"xp": 40
		},
		{
			"id": "m06",
			"chapter": "CHAPTER 2 • PHENO HUNT",
			"title": "Earn Respect",
			"desc": "Reach 20 reputation.",
			"type": "rep",
			"goal": 20,
			"cash": 450,
			"xp": 50
		},
		{
			"id": "m07",
			"chapter": "CHAPTER 2 • PHENO HUNT",
			"title": "Keeper Hunter",
			"desc": "Preserve your first Q90+ keeper.",
			"type": "keepers",
			"goal": 1,
			"cash": 700,
			"xp": 80
		},
		{
			"id": "m08",
			"chapter": "CHAPTER 2 • PHENO HUNT",
			"title": "Project 0 Pair",
			"desc": "Preserve 2 keepers.",
			"type": "keepers",
			"goal": 2,
			"cash": 900,
			"xp": 100
		},
		{
			"id": "m09",
			"chapter": "CHAPTER 3 • MOTHER ROOM",
			"title": "Save The Cut",
			"desc": "Establish your first mother.",
			"type": "mothers",
			"goal": 1,
			"cash": 500,
			"xp": 60
		},
		{
			"id": "m10",
			"chapter": "CHAPTER 3 • MOTHER ROOM",
			"title": "Mother Library",
			"desc": "Establish 3 mothers.",
			"type": "mothers",
			"goal": 3,
			"cash": 900,
			"xp": 100
		},
		{
			"id": "m11",
			"chapter": "CHAPTER 3 • MOTHER ROOM",
			"title": "Genetic Depth",
			"desc": "Reach grower level 3.",
			"type": "level",
			"goal": 3,
			"cash": 600,
			"xp": 70
		},
		{
			"id": "m12",
			"chapter": "CHAPTER 3 • MOTHER ROOM",
			"title": "Vault Builder",
			"desc": "Preserve 3 keepers.",
			"type": "keepers",
			"goal": 3,
			"cash": 1200,
			"xp": 125
		},
		{
			"id": "m13",
			"chapter": "CHAPTER 4 • BREEDING LAB",
			"title": "Make The Cross",
			"desc": "Create your first cross.",
			"type": "crosses",
			"goal": 1,
			"cash": 1000,
			"xp": 125
		},
		{
			"id": "m14",
			"chapter": "CHAPTER 4 • BREEDING LAB",
			"title": "Breeder's Bench",
			"desc": "Create 2 crosses.",
			"type": "crosses",
			"goal": 2,
			"cash": 1400,
			"xp": 150
		},
		{
			"id": "m15",
			"chapter": "CHAPTER 4 • BREEDING LAB",
			"title": "Deep Catalog",
			"desc": "Reach grower level 4.",
			"type": "level",
			"goal": 4,
			"cash": 900,
			"xp": 100
		},
		{
			"id": "m16",
			"chapter": "CHAPTER 4 • BREEDING LAB",
			"title": "Preservation Crew",
			"desc": "Reach 60 reputation.",
			"type": "rep",
			"goal": 60,
			"cash": 1200,
			"xp": 125
		},
		{
			"id": "m17",
			"chapter": "CHAPTER 5 • MARKET PRESSURE",
			"title": "First Contract",
			"desc": "Complete a dispensary contract.",
			"type": "contracts",
			"goal": 1,
			"cash": 800,
			"xp": 90
		},
		{
			"id": "m18",
			"chapter": "CHAPTER 5 • MARKET PRESSURE",
			"title": "Reliable Supplier",
			"desc": "Complete 3 contracts.",
			"type": "contracts",
			"goal": 3,
			"cash": 1600,
			"xp": 175
		},
		{
			"id": "m19",
			"chapter": "CHAPTER 5 • MARKET PRESSURE",
			"title": "Stack The Safe",
			"desc": "Hold $5,000 cash.",
			"type": "cash",
			"goal": 5000,
			"cash": 1000,
			"xp": 100
		},
		{
			"id": "m20",
			"chapter": "CHAPTER 5 • MARKET PRESSURE",
			"title": "Known Name",
			"desc": "Reach 100 reputation.",
			"type": "rep",
			"goal": 100,
			"cash": 2000,
			"xp": 200
		},
		{
			"id": "m21",
			"chapter": "CHAPTER 6 • GROW EMPIRE",
			"title": "Room Two",
			"desc": "Expand to facility level 2.",
			"type": "facility",
			"goal": 2,
			"cash": 1200,
			"xp": 120
		},
		{
			"id": "m22",
			"chapter": "CHAPTER 6 • GROW EMPIRE",
			"title": "Ten Harvests",
			"desc": "Complete 10 harvests.",
			"type": "harvests",
			"goal": 10,
			"cash": 2500,
			"xp": 250
		},
		{
			"id": "m23",
			"chapter": "CHAPTER 6 • GROW EMPIRE",
			"title": "Project 0 Vault",
			"desc": "Preserve 5 elite keepers.",
			"type": "keepers",
			"goal": 5,
			"cash": 3000,
			"xp": 300
		},
		{
			"id": "m24",
			"chapter": "CHAPTER 6 • GROW EMPIRE",
			"title": "Own The Show",
			"desc": "Reach level 6.",
			"type": "level",
			"goal": 6,
			"cash": 5000,
			"xp": 500
		}
	]


func mission_value(t: String) -> int:
	match t:
		"plants":
			return plants.size() + mission_harvests
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

	return 0


func show_missions():
	clear_content()

	var top = panel()
	content.add_child(top)

	var tv = VBoxContainer.new()
	top.add_child(tv)

	tv.add_child(
		make_label(
			"PROJECT 0 • CAMPAIGN",
			29,
			RED
		)
	)

	tv.add_child(
		make_label(
			"PRESERVE • BUILD • BREED • OWN THE SHOW",
			14,
			GOLD
		)
	)

	tv.add_child(
		make_label(
			"%d / %d MISSIONS COMPLETE" % [
				mission_claimed.size(),
				mission_defs().size()
			],
			17
		)
	)

	var current = ""

	for m in mission_defs():
		if m.chapter != current:
			current = m.chapter

			content.add_child(
				make_label(
					current,
					20,
					RED
				)
			)

		var card = panel()
		content.add_child(card)

		var v = VBoxContainer.new()
		card.add_child(v)

		var done = m.id in mission_claimed
		var value = mission_value(m.type)
		var progress = mini(
			value,
			int(m.goal)
		)

		v.add_child(
			make_label(
				("✓ " if done else "◆ ") + m.title,
				19,
				GREEN if done else WHITE
			)
		)

		v.add_child(
			make_label(
				m.desc,
				14,
				MUTED
			)
		)

		var bar = ProgressBar.new()
		bar.max_value = m.goal
		bar.value = progress
		bar.custom_minimum_size = Vector2(0, 20)
		v.add_child(bar)

		v.add_child(
			make_label(
				"%d/%d • REWARD $%d + %d XP" % [
					progress,
					m.goal,
					m.cash,
					m.xp
				],
				14,
				GOLD
			)
		)

		if not done and value >= m.goal:
			v.add_child(
				make_button(
					"CLAIM MISSION",
					func(id = m.id):
						claim_campaign_mission(id)
				)
			)


func claim_campaign_mission(id: String):
	if id in mission_claimed:
		return

	for m in mission_defs():
		if m.id == id and mission_value(m.type) >= m.goal:
			mission_claimed.append(id)

			cash += m.cash
			xp += m.xp
			reputation += 2

			if id == "m04" and facility_level < 2:
				facility_level = 2
				room_two_unlocked = true

				unlock_achievement(
					"Empire Builder"
				)

			level_up()
			save_game()
			refresh_stats()
			show_missions()
			return


func unlock_achievement(id: String):
	if id not in achievements:
		achievements.append(id)


func show_achievements():
	clear_content()

	var p = panel()
	content.add_child(p)

	var v = VBoxContainer.new()
	p.add_child(v)

	v.add_child(
		make_label(
			"SHOCKER OWNZ • ACHIEVEMENTS",
			27,
			RED
		)
	)

	var defs = [
		[
			"First Harvest",
			"Complete your first harvest."
		],
		[
			"Keeper Hunter",
			"Preserve a Q90+ phenotype."
		],
		[
			"Breeder",
			"Create your first cross."
		],
		[
			"Contract Killer",
			"Complete a market contract."
		],
		[
			"Empire Builder",
			"Unlock Room 02."
		]
	]

	for a in defs:
		var done = a[0] in achievements

		v.add_child(
			make_label(
				("✓ " if done else "○ ") +
				a[0] +
				"\n" +
				a[1],
				17,
				GREEN if done else MUTED
			)
		)

	v.add_child(
		make_button(
			"BACK TO GROW",
			show_grow
		)
	)


func save_game():
	var data = {
		"cash": cash,
		"xp": xp,
		"level": level,
		"reputation": reputation,
		"day": day,
		"plants": plants,
		"keepers": keepers,
		"mothers": mothers,
		"crosses": crosses,
		"inventory": inventory,
		"cured_inventory": cured_inventory,
		"achievements": achievements,
		"mission_claimed": mission_claimed,
		"mission_harvests": mission_harvests,
		"contracts_completed": contracts_completed,
		"facility_level": facility_level,
		"room_two_unlocked": room_two_unlocked,
		"upgrades": owned_upgrades
	}

	var f = FileAccess.open(
		SAVE_PATH,
		FileAccess.WRITE
	)

	if f:
		f.store_string(
			JSON.stringify(data)
		)


func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var f = FileAccess.open(
		SAVE_PATH,
		FileAccess.READ
	)

	if not f:
		return

	var d = JSON.parse_string(
		f.get_as_text()
	)

	if typeof(d) != TYPE_DICTIONARY:
		return

	cash = int(
		d.get("cash", 500)
	)

	xp = int(
		d.get("xp", 0)
	)

	level = int(
		d.get("level", 1)
	)

	reputation = int(
		d.get("reputation", 0)
	)

	day = int(
		d.get("day", 1)
	)

	plants = d.get(
		"plants",
		[]
	)

	keepers = d.get(
		"keepers",
		[]
	)

	mothers = d.get(
		"mothers",
		[]
	)

	crosses = d.get(
		"crosses",
		[]
	)

	inventory = d.get(
		"inventory",
		[]
	)

	cured_inventory = d.get(
		"cured_inventory",
		[]
	)

	achievements = d.get(
		"achievements",
		[]
	)

	mission_claimed = d.get(
		"mission_claimed",
		[]
	)

	mission_harvests = int(
		d.get(
			"mission_harvests",
			0
		)
	)

	contracts_completed = int(
		d.get(
			"contracts_completed",
			0
		)
	)

	facility_level = int(
		d.get(
			"facility_level",
			1
		)
	)

	room_two_unlocked = bool(
		d.get(
			"room_two_unlocked",
			false
		)
	)

	owned_upgrades = d.get(
		"upgrades",
		owned_upgrades
	)

	for p in plants:
		if not p.has("water"):
			p.water = 100

		if not p.has("pheno"):
			p.pheno = "A"

		if not p.has("vigor"):
			p.vigor = 100

		if not p.has("trained"):
			p.trained = false

		if not p.has("problem"):
			p.problem = ""


# ============================================================
# SHOCKER OWNZ: GROW EMPIRE
# ALPHA 0.11 — TYCOON EXPANSION
# ============================================================

var tycoon_started := false
var total_revenue := 0
var total_expenses := 0
var employees: Array = []
var side_claimed: Array = []
var daily_claimed: Array = []
var research_owned: Array = []
var cups_won := 0
var event_log: Array = []
var last_bill_day := 0
var last_daily_reset := 0


const FACILITIES = [
	{
		"name": "Closet Start",
		"cost": 0,
		"slots": 4,
		"overhead": 35,
		"unlock": 1
	},
	{
		"name": "Pro Tent",
		"cost": 2500,
		"slots": 6,
		"overhead": 75,
		"unlock": 2
	},
	{
		"name": "Basement Lab",
		"cost": 7500,
		"slots": 8,
		"overhead": 150,
		"unlock": 3
	},
	{
		"name": "Garage Facility",
		"cost": 18000,
		"slots": 10,
		"overhead": 300,
		"unlock": 4
	},
	{
		"name": "Warehouse",
		"cost": 50000,
		"slots": 12,
		"overhead": 650,
		"unlock": 5
	},
	{
		"name": "Project 0 Compound",
		"cost": 125000,
		"slots": 16,
		"overhead": 1200,
		"unlock": 6
	}
]


const STAFF = [
	{
		"role": "Grow Tech",
		"hire": 600,
		"pay": 55,
		"bonus": "Plant care + quality"
	},
	{
		"role": "Breeding Tech",
		"hire": 1200,
		"pay": 90,
		"bonus": "Genetics + breeding"
	},
	{
		"role": "Sales Rep",
		"hire": 1600,
		"pay": 110,
		"bonus": "Contracts + revenue"
	},
	{
		"role": "Facility Manager",
		"hire": 3000,
		"pay": 180,
		"bonus": "Lower overhead"
	},
	{
		"role": "Genetics Researcher",
		"hire": 5000,
		"pay": 260,
		"bonus": "Research + keeper hunting"
	}
]


const RESEARCH = [
	{
		"id": "r1",
		"name": "Efficient Lighting",
		"cost": 1000,
		"desc": "Reduce operating pressure and improve quality."
	},
	{
		"id": "r2",
		"name": "Climate Automation",
		"cost": 2500,
		"desc": "Improve consistency across the facility."
	},
	{
		"id": "r3",
		"name": "Genetic Analytics",
		"cost": 5000,
		"desc": "Boost Project 0 keeper hunting."
	},
	{
		"id": "r4",
		"name": "Contract Network",
		"cost": 7500,
		"desc": "Increase business reputation."
	},
	{
		"id": "r5",
		"name": "Project 0 Lab",
		"cost": 15000,
		"desc": "Unlock elite research status."
	}
]


func tycoon_boot():
	if tycoon_started:
		return

	tycoon_started = true

	if last_daily_reset == 0:
		last_daily_reset = day

	if last_bill_day == 0:
		last_bill_day = day

	tycoon_load_extension()


func facility_data() -> Dictionary:
	var idx = clampi(
		facility_level - 1,
		0,
		FACILITIES.size() - 1
	)

	return FACILITIES[idx]


func employee_payroll() -> int:
	var total := 0

	for e in employees:
		total += int(
			e.get("pay", 0)
		)

	return total


func business_value() -> int:
	var genetic_value = (
		keepers.size() * 900 +
		mothers.size() * 500 +
		crosses.size() * 1400
	)

	var asset_value = (
		facility_level *
		facility_level *
		3500
	)

	var staff_value = (
		employees.size() * 750
	)

	var brand_value = (
		reputation * 75 +
		cups_won * 5000
	)

	return maxi(
		0,
		cash +
		genetic_value +
		asset_value +
		staff_value +
		brand_value
	)


func show_empire():
	tycoon_boot()
	clear_content()

	var p = panel()
	content.add_child(p)

	var v = VBoxContainer.new()
	p.add_child(v)

	v.add_child(
		make_label(
			"SHOCKER OWNZ • EMPIRE HQ",
			29,
			RED
		)
	)

	v.add_child(
		make_label(
			facility_data().name,
			20,
			GOLD
		)
	)

	v.add_child(
		make_label(
			"NET WORTH  $%d" % business_value(),
			24,
			WHITE
		)
	)

	v.add_child(
		make_label(
			"Cash $%d  •  Revenue $%d  •  Expenses $%d" % [
				cash,
				total_revenue,
				total_expenses
			],
			15,
			MUTED
		)
	)

	v.add_child(
		make_label(
			"Staff %d  •  Payroll $%d  •  Cups %d  •  Project 0 Keepers %d" % [
				employees.size(),
				employee_payroll(),
				cups_won,
				keepers.size()
			],
			15,
			MUTED
		)
	)

	var actions = GridContainer.new()
	actions.columns = 2
	v.add_child(actions)

	var empire_actions = [
		["FACILITIES", show_facilities],
		["EMPLOYEES", show_employees],
		["SIDE MISSIONS", show_side_missions],
		["DAILY", show_daily],
		["RESEARCH", show_research],
		["COMPETE", show_competitions],
		["FINANCES", show_finances],
		["GROW ROOM", show_grow]
	]

	for item in empire_actions:
		var b = make_button(
			item[0],
			item[1]
		)

		b.custom_minimum_size = Vector2(
			310,
			48
		)

		actions.add_child(b)

	if event_log.size() > 0:
		v.add_child(
			make_label(
				"LATEST EMPIRE NEWS",
				18,
				RED
			)
		)

		for i in range(
			mini(
				3,
				event_log.size()
			)
		):
			v.add_child(
				make_label(
					"• " +
					str(
						event_log[
							event_log.size() - 1 - i
						]
					),
					14,
					MUTED
				)
			)


func show_facilities():
	tycoon_boot()
	clear_content()

	content.add_child(
		make_label(
			"FACILITY EMPIRE",
			28,
			RED
		)
	)

	for i in range(
		FACILITIES.size()
	):
		var f = FACILITIES[i]

		var card = panel()
		content.add_child(card)

		var v = VBoxContainer.new()
		card.add_child(v)

		var status = "LOCKED"

		if i < facility_level:
			status = "OWNED"
		elif i == facility_level:
			status = "NEXT"

		v.add_child(
			make_label(
				"%s • %s" % [
					f.name,
					status
				],
				19,
				GOLD if i < facility_level else WHITE
			)
		)

		v.add_child(
			make_label(
				"Capacity tier %d • Overhead $%d / 5 days" % [
					f.slots,
					f.overhead
				],
				14,
				MUTED
			)
		)

		if (
			i == facility_level and
			facility_level < FACILITIES.size()
		):
			var b = make_button(
				"EXPAND • $%d" % f.cost,
				func(idx = i):
					buy_facility(idx)
			)

			b.disabled = (
				level < int(f.unlock)
			)

			v.add_child(b)


func buy_facility(idx: int):
	if (
		idx != facility_level or
		idx >= FACILITIES.size()
	):
		return

	var f = FACILITIES[idx]

	if (
		cash < int(f.cost) or
		level < int(f.unlock)
	):
		return

	cash -= int(f.cost)
	total_expenses += int(f.cost)

	facility_level += 1

	room_two_unlocked = (
		facility_level >= 2
	)

	event_log.append(
		"Empire expanded into " +
		str(f.name) +
		"."
	)

	xp += 150 * facility_level
	reputation += 10 * facility_level

	level_up()
	save_game()
	tycoon_save_extension()
	refresh_stats()
	show_facilities()


func show_employees():
	tycoon_boot()
	clear_content()

	content.add_child(
		make_label(
			"EMPLOYEE MANAGEMENT",
			28,
			RED
		)
	)

	content.add_child(
		make_label(
			"Staff strengthen your empire. Payroll is charged every 5 game days.",
			14,
			MUTED
		)
	)

	for s in STAFF:
		var card = panel()
		content.add_child(card)

		var v = VBoxContainer.new()
		card.add_child(v)

		var count := 0

		for e in employees:
			if e.get(
				"role",
				""
			) == s.role:
				count += 1

		v.add_child(
			make_label(
				"%s • EMPLOYED %d" % [
					s.role,
					count
				],
				18,
				WHITE
			)
		)

		v.add_child(
			make_label(
				"%s • Hire $%d • Payroll $%d" % [
					s.bonus,
					s.hire,
					s.pay
				],
				14,
				MUTED
			)
		)

		v.add_child(
			make_button(
				"HIRE " + str(s.role),
				func(role = s.role):
					hire_employee(role)
			)
		)


func hire_employee(role: String):
	for s in STAFF:
		if s.role == role:
			if cash < int(s.hire):
				return

			cash -= int(s.hire)
			total_expenses += int(s.hire)

			employees.append({
				"role": s.role,
				"pay": s.pay,
				"skill": 1
			})

			reputation += 2

			event_log.append(
				"Hired a " +
				role +
				"."
			)

			save_game()
			tycoon_save_extension()
			refresh_stats()
			show_employees()
			return


func process_tycoon_day():
	tycoon_boot()

	if day - last_bill_day >= 5:
		var overhead = int(
			facility_data().overhead
		)

		var payroll = employee_payroll()

		var managers := 0

		for e in employees:
			if e.get(
				"role",
				""
			) == "Facility Manager":
				managers += 1

		overhead = roundi(
			overhead *
			maxf(
				0.70,
				1.0 - managers * 0.05
			)
		)

		if "r1" in research_owned:
			overhead = roundi(
				overhead * 0.90
			)

		var bill = (
			overhead +
			payroll
		)

		cash -= bill
		total_expenses += bill
		last_bill_day = day

		event_log.append(
			"Bills paid: -$%d." % bill
		)

	if (
		day -
		last_daily_reset >= 7
	):
		daily_claimed.clear()
		last_daily_reset = day

		event_log.append(
			"Weekly challenges refreshed."
		)

	if rng.randf() < 0.13:
		trigger_empire_event()

	tycoon_save_extension()


func trigger_empire_event():
	var roll = rng.randi_range(
		0,
		5
	)

	match roll:
		0:
			var bonus = (
				150 +
				level * 40
			)

			cash += bonus
			total_revenue += bonus

			event_log.append(
				"Surprise buyer bonus: +$%d." %
				bonus
			)

		1:
			var cost = (
				75 +
				facility_level * 40
			)

			cash -= cost
			total_expenses += cost

			event_log.append(
				"Equipment repair: -$%d." %
				cost
			)

		2:
			reputation += 5

			event_log.append(
				"Word of mouth is spreading: +5 reputation."
			)

		3:
			xp += 35
			level_up()

			event_log.append(
				"Staff breakthrough: +35 XP."
			)

		4:
			if keepers.size() > 0:
				reputation += 8

				event_log.append(
					"Project 0 keeper gets attention: +8 reputation."
				)

		5:
			var bonus = (
				100 *
				facility_level
			)

			cash += bonus
			total_revenue += bonus

			event_log.append(
				"Local contract deposit: +$%d." %
				bonus
			)

# ============================================================
# ALPHA 0.11 — PART 2
# SIDE MISSIONS + WEEKLY CHALLENGES
# ============================================================


func side_defs() -> Array:
	var defs: Array = []

	var types = [
		["harvests", "Harvest Run"],
		["rep", "Build The Name"],
		["keepers", "Keeper Hunt"],
		["mothers", "Mother Room"],
		["crosses", "Breeding Order"],
		["contracts", "Market Push"],
		["cash", "Stack Capital"],
		["level", "Grower Rank"]
	]

	for i in range(36):
		var t = types[
			i % types.size()
		]

		var tier = int(
			i / 8
		) + 1

		var goal = tier

		if t[0] == "harvests":
			goal = tier * 3

		elif t[0] == "rep":
			goal = tier * 30

		elif t[0] == "cash":
			goal = tier * 5000

		elif t[0] == "level":
			goal = tier + 1

		elif t[0] == "contracts":
			goal = tier * 2

		var id = "s%02d" % (
			i + 1
		)

		defs.append({
			"id": id,
			"title":
				str(t[1]) +
				" " +
				str(tier),
			"desc":
				"Build the empire and hit the target.",
			"type": t[0],
			"goal": goal,
			"cash":
				250 * tier +
				i * 25,
			"xp":
				30 * tier
		})

	return defs


func show_side_missions():
	tycoon_boot()
	clear_content()

	content.add_child(
		make_label(
			"SIDE MISSIONS • %d/36" %
				side_claimed.size(),
			28,
			RED
		)
	)

	content.add_child(
		make_label(
			"Optional contracts, challenges and empire objectives.",
			14,
			GOLD
		)
	)

	for m in side_defs():
		var done = (
			m.id in side_claimed
		)

		var val = mission_value(
			m.type
		)

		var card = panel()
		content.add_child(card)

		var v = VBoxContainer.new()
		card.add_child(v)

		v.add_child(
			make_label(
				(
					"✓ "
					if done
					else "◆ "
				) +
				m.title,
				18,
				GREEN
				if done
				else WHITE
			)
		)

		v.add_child(
			make_label(
				"%s  •  %d/%d" % [
					m.desc,
					mini(
						val,
						int(m.goal)
					),
					m.goal
				],
				14,
				MUTED
			)
		)

		var bar = ProgressBar.new()

		bar.max_value = int(
			m.goal
		)

		bar.value = mini(
			val,
			int(m.goal)
		)

		bar.custom_minimum_size = Vector2(
			0,
			18
		)

		v.add_child(bar)

		v.add_child(
			make_label(
				"REWARD • $%d + %d XP" % [
					m.cash,
					m.xp
				],
				14,
				GOLD
			)
		)

		if (
			not done and
			val >= int(m.goal)
		):
			v.add_child(
				make_button(
					"CLAIM SIDE MISSION",
					func(id = m.id):
						claim_side(id)
				)
			)


func claim_side(id: String):
	if id in side_claimed:
		return

	for m in side_defs():
		if (
			m.id == id and
			mission_value(
				m.type
			) >= int(m.goal)
		):
			side_claimed.append(id)

			cash += int(
				m.cash
			)

			total_revenue += int(
				m.cash
			)

			xp += int(
				m.xp
			)

			reputation += 1

			event_log.append(
				"Side mission complete: " +
				str(m.title) +
				"."
			)

			level_up()
			save_game()
			tycoon_save_extension()
			refresh_stats()
			show_side_missions()
			return


func daily_defs() -> Array:
	var scale = maxi(
		1,
		level
	)

	return [
		{
			"id": "d1",
			"title": "Clock In",
			"desc":
				"Keep the operation moving for 2 more days.",
			"type": "day",
			"goal":
				last_daily_reset + 2,
			"cash":
				150 * scale,
			"xp": 25
		},
		{
			"id": "d2",
			"title": "Production Push",
			"desc":
				"Complete another harvest.",
			"type": "harvests",
			"goal":
				maxi(
					1,
					mission_harvests + 1
				),
			"cash":
				200 * scale,
			"xp": 35
		},
		{
			"id": "d3",
			"title": "Build The Brand",
			"desc":
				"Push your reputation higher.",
			"type": "rep",
			"goal":
				reputation + 5,
			"cash":
				250 * scale,
			"xp": 40
		}
	]


func show_daily():
	tycoon_boot()
	clear_content()

	content.add_child(
		make_label(
			"WEEKLY CHALLENGES",
			28,
			RED
		)
	)

	content.add_child(
		make_label(
			"New objectives refresh every 7 in-game days.",
			14,
			GOLD
		)
	)

	for m in daily_defs():
		var done = (
			m.id in daily_claimed
		)

		var val = mission_value(
			m.type
		)

		var card = panel()
		content.add_child(card)

		var v = VBoxContainer.new()
		card.add_child(v)

		v.add_child(
			make_label(
				(
					"✓ "
					if done
					else "◆ "
				) +
				m.title,
				18,
				GREEN
				if done
				else WHITE
			)
		)

		v.add_child(
			make_label(
				m.desc,
				14,
				MUTED
			)
		)

		var bar = ProgressBar.new()

		bar.max_value = int(
			m.goal
		)

		bar.value = mini(
			val,
			int(m.goal)
		)

		bar.custom_minimum_size = Vector2(
			0,
			18
		)

		v.add_child(bar)

		v.add_child(
			make_label(
				"%d/%d • REWARD $%d + %d XP" % [
					mini(
						val,
						int(m.goal)
					),
					m.goal,
					m.cash,
					m.xp
				],
				14,
				GOLD
			)
		)

		if (
			not done and
			val >= int(m.goal)
		):
			v.add_child(
				make_button(
					"CLAIM CHALLENGE",
					func(id = m.id):
						claim_daily(id)
				)
			)


func claim_daily(id: String):
	if id in daily_claimed:
		return

	for m in daily_defs():
		if (
			m.id == id and
			mission_value(
				m.type
			) >= int(m.goal)
		):
			daily_claimed.append(id)

			cash += int(
				m.cash
			)

			total_revenue += int(
				m.cash
			)

			xp += int(
				m.xp
			)

			reputation += 2

			event_log.append(
				"Weekly challenge complete: " +
				str(m.title) +
				"."
			)

			level_up()
			save_game()
			tycoon_save_extension()
			refresh_stats()
			show_daily()
			return


# ============================================================
# RESEARCH SYSTEM
# ============================================================


func show_research():
	tycoon_boot()
	clear_content()

	content.add_child(
		make_label(
			"PROJECT 0 • RESEARCH",
			28,
			RED
		)
	)

	content.add_child(
		make_label(
			"Invest empire profits into permanent technology.",
			14,
			GOLD
		)
	)

	for r in RESEARCH:
		var owned = (
			r.id in research_owned
		)

		var card = panel()
		content.add_child(card)

		var v = VBoxContainer.new()
		card.add_child(v)

		v.add_child(
			make_label(
				(
					"✓ "
					if owned
					else "◆ "
				) +
				str(r.name),
				18,
				GREEN
				if owned
				else WHITE
			)
		)

		v.add_child(
			make_label(
				str(r.desc),
				14,
				MUTED
			)
		)

		if not owned:
			v.add_child(
				make_button(
					"RESEARCH • $%d" %
						r.cost,
					func(id = r.id):
						buy_research(id)
				)
			)


func buy_research(id: String):
	for r in RESEARCH:
		if (
			r.id == id and
			id not in research_owned
		):
			if cash < int(
				r.cost
			):
				return

			cash -= int(
				r.cost
			)

			total_expenses += int(
				r.cost
			)

			research_owned.append(
				id
			)

			xp += 100
			reputation += 5

			level_up()

			event_log.append(
				"Research complete: " +
				str(r.name) +
				"."
			)

			save_game()
			tycoon_save_extension()
			refresh_stats()
			show_research()
			return

# ============================================================
# ALPHA 0.11 — PART 3
# COMPETITIONS + FINANCES + TYCOON SAVE SYSTEM
# ============================================================


func show_competitions():
	tycoon_boot()
	clear_content()

	content.add_child(
		make_label(
			"PROJECT 0 • COMPETITION CIRCUIT",
			28,
			RED
		)
	)

	content.add_child(
		make_label(
			"Put your best genetics against the competition.",
			14,
			GOLD
		)
	)

	var events = [
		{
			"name": "Local Grow-Off",
			"need": 1,
			"fee": 250,
			"q": 82,
			"reward": 1500
		},
		{
			"name": "Regional Genetics Cup",
			"need": 2,
			"fee": 1000,
			"q": 88,
			"reward": 6000
		},
		{
			"name": "Project 0 Invitational",
			"need": 4,
			"fee": 5000,
			"q": 94,
			"reward": 25000
		}
	]

	for e in events:
		var card = panel()
		content.add_child(card)

		var v = VBoxContainer.new()
		card.add_child(v)

		v.add_child(
			make_label(
				str(e.name),
				19,
				GOLD
			)
		)

		v.add_child(
			make_label(
				"Need %d keeper(s) • Entry $%d" % [
					e.need,
					e.fee
				],
				14,
				MUTED
			)
		)

		v.add_child(
			make_label(
				"Target Q%d • Prize $%d" % [
					e.q,
					e.reward
				],
				14,
				WHITE
			)
		)

		var enter = make_button(
			"ENTER COMPETITION",
			func(ev = e):
				enter_competition(ev)
		)

		enter.disabled = (
			cash < int(e.fee) or
			keepers.size() < int(e.need)
		)

		v.add_child(enter)

	content.add_child(
		make_label(
			"CAREER CUP WINS • %d" %
				cups_won,
			18,
			RED
		)
	)


func enter_competition(
	e: Dictionary
):
	if (
		cash < int(e.fee) or
		keepers.size() < int(e.need)
	):
		return

	cash -= int(e.fee)
	total_expenses += int(e.fee)

	var best := 0

	for k in keepers:
		best = maxi(
			best,
			int(
				k.get(
					"q",
					0
				)
			)
		)

	var staff_bonus := 0

	for emp in employees:
		if emp.get(
			"role",
			""
		) == "Genetics Researcher":
			staff_bonus += 1

	var research_bonus := 0

	if "r3" in research_owned:
		research_bonus = 2

	var score = (
		best +
		staff_bonus +
		research_bonus +
		rng.randi_range(
			-3,
			5
		)
	)

	if score >= int(e.q):
		cash += int(
			e.reward
		)

		total_revenue += int(
			e.reward
		)

		cups_won += 1
		reputation += 20
		xp += 200

		event_log.append(
			"CUP WINNER: " +
				str(e.name) +
				"!"
		)

		unlock_achievement(
			"Cup Winner"
		)

	else:
		reputation += 2
		xp += 25

		event_log.append(
			"Strong showing at " +
				str(e.name) +
				"."
		)

	level_up()
	save_game()
	tycoon_save_extension()
	refresh_stats()
	show_competitions()


# ============================================================
# BUSINESS FINANCE DASHBOARD
# ============================================================


func show_finances():
	tycoon_boot()
	clear_content()

	var p = panel()
	content.add_child(p)

	var v = VBoxContainer.new()
	p.add_child(v)

	v.add_child(
		make_label(
			"BUSINESS FINANCES",
			28,
			RED
		)
	)

	v.add_child(
		make_label(
			facility_data().name,
			17,
			GOLD
		)
	)

	v.add_child(
		make_label(
			"Cash On Hand",
			14,
			MUTED
		)
	)

	v.add_child(
		make_label(
			"$%d" % cash,
			30,
			WHITE
		)
	)

	v.add_child(
		make_label(
			"LIFETIME REVENUE • $%d" %
				total_revenue,
			17,
			GREEN
		)
	)

	v.add_child(
		make_label(
			"LIFETIME EXPENSES • $%d" %
				total_expenses,
			17,
			RED
		)
	)

	var profit = (
		total_revenue -
		total_expenses
	)

	v.add_child(
		make_label(
			"LIFETIME PROFIT • $%d" %
				profit,
			17,
			GOLD
			if profit >= 0
			else RED
		)
	)

	v.add_child(
		make_label(
			"BUSINESS VALUATION",
			15,
			MUTED
		)
	)

	v.add_child(
		make_label(
			"$%d" %
				business_value(),
			27,
			GOLD
		)
	)

	v.add_child(
		make_label(
			"Facility overhead • $%d every 5 days" %
				int(
					facility_data().overhead
				),
			15,
			MUTED
		)
	)

	v.add_child(
		make_label(
			"Employee payroll • $%d every 5 days" %
				employee_payroll(),
			15,
			MUTED
		)
	)

	v.add_child(
		make_label(
			"Employees • %d" %
				employees.size(),
			15,
			MUTED
		)
	)

	v.add_child(
		make_label(
			"Cup Championships • %d" %
				cups_won,
			15,
			MUTED
		)
	)

	v.add_child(
		make_label(
			"Project 0 Keepers • %d" %
				keepers.size(),
			15,
			MUTED
		)
	)

	v.add_child(
		make_button(
			"BACK TO EMPIRE HQ",
			show_empire
		)
	)


# ============================================================
# TYCOON SAVE / LOAD
# ============================================================


func tycoon_save_extension():
	var data = {
		"total_revenue":
			total_revenue,

		"total_expenses":
			total_expenses,

		"employees":
			employees,

		"side_claimed":
			side_claimed,

		"daily_claimed":
			daily_claimed,

		"research_owned":
			research_owned,

		"cups_won":
			cups_won,

		"event_log":
			event_log,

		"last_bill_day":
			last_bill_day,

		"last_daily_reset":
			last_daily_reset
	}

	var f = FileAccess.open(
		"user://grow_empire_tycoon.json",
		FileAccess.WRITE
	)

	if f:
		f.store_string(
			JSON.stringify(
				data
			)
		)


func tycoon_load_extension():
	if not FileAccess.file_exists(
		"user://grow_empire_tycoon.json"
	):
		return

	var f = FileAccess.open(
		"user://grow_empire_tycoon.json",
		FileAccess.READ
	)

	if not f:
		return

	var d = JSON.parse_string(
		f.get_as_text()
	)

	if typeof(d) != TYPE_DICTIONARY:
		return

	total_revenue = int(
		d.get(
			"total_revenue",
			0
		)
	)

	total_expenses = int(
		d.get(
			"total_expenses",
			0
		)
	)

	employees = d.get(
		"employees",
		[]
	)

	side_claimed = d.get(
		"side_claimed",
		[]
	)

	daily_claimed = d.get(
		"daily_claimed",
		[]
	)

	research_owned = d.get(
		"research_owned",
		[]
	)

	cups_won = int(
		d.get(
			"cups_won",
			0
		)
	)

	event_log = d.get(
		"event_log",
		[]
	)

	last_bill_day = int(
		d.get(
			"last_bill_day",
			day
		)
	)

	last_daily_reset = int(
		d.get(
			"last_daily_reset",
			day
		)
	)
