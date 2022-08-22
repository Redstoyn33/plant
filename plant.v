import rand
import clipboard
import term
import os { get_line, input }
import encoding.hex as enc
import strings

const (
	nothing = '  '
	block   = '██'
)

fn main() {
	mut game := new_game()
	game.display()
	for {
		match get_line() {
			'R' {
				game = new_game()
				game.display()
			}
			'r' {
				game.reset_game()
				game.display()
			}
			'w' {
				game.reset_world()
				game.display()
			}
			'v' {
				game.show_gens()
				game.display()
			}
			'' {
				if game.end {
					term.clear_previous_line()
					continue
				}
				game.step()
				game.display()
			}
			'e' {
				if game.end {
					term.clear_previous_line()
					continue 
				}
				game.step_to_end()
				game.display()
			}
			else {
				term.clear_previous_line()
			}
		}
	}
}

fn (g Game) display() {
	term.clear()
	mut b := strings.new_builder(1)
	b.write_string('┌')
	for _ in 0 .. g.size {
		b.write_string('──')
	}
	b.writeln('┐')
	for x in 0 .. g.size {
		b.write_string('│')
		for y in 0 .. g.size {
			match g.world[x][y] {
				30 { b.write_string(nothing) }
				31 { b.write_string(block) }
				else { b.write_string('${g.world[x][y]:02}') }
			}
		}
		b.write_string('│')
		b.writeln('')
	}
	b.write_string('└')
	for _ in 0 .. g.size {
		b.write_string('──')
	}
	b.write_string('┘')
	b.writeln('')
	b.writeln('r для перезапуска, R для полного перезапуска,')
	b.writeln('w для перезапуска мира, e для щага до конца')
	b.writeln('v для просмотра цепи генов, enter для шага')
	print(b.str())
}

fn (mut g Game) step_to_end() {
	for {
		if g.end { return }
		g.step()
	}
}

fn (mut g Game) step() {
	mut end_c := true
	mut temp_w := g.world.clone()
	for x in 0 .. g.size {
		for y in 0 .. g.size {
			if g.world[x][y] < g.genc {
				if g.gens[g.world[x][y]].up < g.genc && x - 1 != -1 && g.world[x - 1][y] == 30 {
					temp_w[x - 1][y] = g.gens[g.world[x][y]].up
				}
				if g.gens[g.world[x][y]].left < g.genc && y - 1 != -1 && g.world[x][y - 1] == 30 {
					temp_w[x][y - 1] = g.gens[g.world[x][y]].left
				}
				if g.gens[g.world[x][y]].right < g.genc && y + 1 != g.size
					&& g.world[x][y + 1] == 30 {
					temp_w[x][y + 1] = g.gens[g.world[x][y]].right
				}
				if g.gens[g.world[x][y]].down < g.genc && x + 1 != g.size && g.world[x + 1][y] == 30 {
					temp_w[x + 1][y] = g.gens[g.world[x][y]].down
				}
				temp_w[x][y] = 31
				end_c = false
			}
		}
	}
	g.world = temp_w
	g.end = end_c
}

struct Game {
mut:
	genc  int
	size  int
	gens  []Gen
	world [][]u8
	end   bool
}

fn (mut g Game) show_gens() {
	term.clear()
	for i in 0 .. g.genc {
		up := if g.gens[i].up < g.genc { g.gens[i].up.str() } else { 'X' }
		down := if g.gens[i].down < g.genc { g.gens[i].down.str() } else { 'X' }
		right := if g.gens[i].right < g.genc { g.gens[i].right.str() } else { 'X' }
		left := if g.gens[i].left < g.genc { g.gens[i].left.str() } else { 'X' }
		println('$i ↑$up ↓$down →$right ←$left')
	}
	println('enter для возврата, e для редактирования гена')
	println('c для копирования, v для вставки')
	match get_line() {
		'e' {
			mut gen := -1
			for gen <= -1 || gen >= g.genc {
				term.clear_previous_line()
				s := input('ген (0-${g.genc - 1}) (enter для отмены): ')
				if s == '' {
					return
				}
				if s.contains_only('0123456789') {
					gen = s.int()
				}
			}
			term.clear_previous_line()
			term.clear_previous_line()
			term.clear_previous_line()
			println('')
			up := if g.gens[gen].up < g.genc { g.gens[gen].up.str() } else { 'X' }
			down := if g.gens[gen].down < g.genc { g.gens[gen].down.str() } else { 'X' }
			right := if g.gens[gen].right < g.genc { g.gens[gen].right.str() } else { 'X' }
			left := if g.gens[gen].left < g.genc { g.gens[gen].left.str() } else { 'X' }
			mut upe := -1
			mut downe := -1
			mut lefte := -1
			mut righte := -1
			println('$gen ↑$up ↓$down →$right ←$left')
			println('')
			for upe <= -1 || upe >= 31 {
				term.clear_previous_line()
				print('$gen ↑')
				s := get_line()
				if s.contains_only('0123456789') {
					upe = s.int()
				}
				if s == '' {
					upe = 30
				}
			}
			upes := if upe < g.genc { upe.str() } else { 'X' }
			for downe <= -1 || downe >= 31 {
				term.clear_previous_line()
				print('$gen ↑$upes ↓')
				s := get_line()
				if s.contains_only('0123456789') {
					downe = s.int()
				}
				if s == '' {
					downe = 30
				}
			}
			downes := if downe < g.genc { downe.str() } else { 'X' }
			for righte <= -1 || righte >= 31 {
				term.clear_previous_line()
				print('$gen ↑$upes ↓$downes →')
				s := get_line()
				if s.contains_only('0123456789') {
					righte = s.int()
				}
				if s == '' {
					righte = 30
				}
			}
			rightes := if righte < g.genc { righte.str() } else { 'X' }
			for lefte <= -1 || lefte >= 31 {
				term.clear_previous_line()
				print('$gen ↑$upes ↓$downes →$rightes ←')
				s := get_line()
				if s.contains_only('0123456789') {
					lefte = s.int()
				}
				if s == '' {
					lefte = 30
				}
			}
			g.gens[gen] = Gen{u8(upe), u8(downe), u8(lefte), u8(righte)}
			g.show_gens()
		}
		'c' {
			mut c := clipboard.new()
			mut data := []u8{cap: g.genc * 4}
			for gen in g.gens {
				data << gen.up
				data << gen.down
				data << gen.left
				data << gen.right
			}
			if c.copy(enc.encode(data)) {
				println('скопированно')
			}
			c.destroy()
		}
		'v' {
			mut c := clipboard.new()
			data := enc.decode(c.paste()) or { [] }
			if data.len == 0 || data.len > 30 * 4 || data.len % 4 != 0 {
				println('не удалось загрузить')
				get_line()
			} else {
				g.genc = data.len / 4
				mut chain := []Gen{cap: g.genc}
				for i in 0 .. g.genc {
					chain << Gen{data[4 * i], data[4 * i + 1], data[4 * i + 2], data[4 * i + 3]}
				}
				g.gens = chain
				g.show_gens()
			}
			c.destroy()
		}
		else {}
	}
}

struct Gen {
	up    u8
	down  u8
	left  u8
	right u8
}

fn new_game() Game {
	mut size := 0
	mut genc := 0
	term.clear()
	for size <= 0 || size >= 101 {
		term.clear_previous_line()
		size = input('размер поля: ').int()
	}
	println('')
	for genc <= 0 || genc >= 31 {
		term.clear_previous_line()
		genc = input('количество генов (1-30): ').int()
	}
	mut world := [][]u8{len: size, init: []u8{len: size, init: 30}}
	world[size / 2][size / 2] = 0
	return Game{genc, size, new_gens(genc), world, false}
}

fn (mut g Game) reset_game() {
	mut world := [][]u8{len: g.size, init: []u8{len: g.size, init: 30}}
	world[g.size / 2][g.size / 2] = 0
	g.world = world
	g.gens = new_gens(g.genc)
	g.end = false
}

fn (mut g Game) reset_world() {
	mut world := [][]u8{len: g.size, init: []u8{len: g.size, init: 30}}
	world[g.size / 2][g.size / 2] = 0
	g.world = world
	g.end = false
}

fn new_gens(genc int) []Gen {
	mut gens := []Gen{len: genc}
	for mut g in gens {
		g = new_gen()
	}
	return gens
}

fn new_gen() Gen {
	return Gen{rand.u8() % 30, rand.u8() % 30, rand.u8() % 30, rand.u8() % 30}
}
