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
