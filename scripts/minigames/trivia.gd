extends "res://scripts/minigames/quiz.gd"
## Thursday trivia night at Club Cloud 9 (main.gd trivia_menu): Duff + {coworker} vs the Long Positions.
## Same clipboard quiz as the lineup, pub questions, painted club behind it.

const TRIVIA: = [
	{"q": "Omaha is the biggest city in which state?", "a": ["Nebraska", "Iowa", "Kansas", "Missouri"], "why": "Nebraska. Lincoln is the capital, Omaha is the big one."},
	{"q": "Which river separates Omaha from Council Bluffs?", "a": ["The Missouri", "The Platte", "The Mississippi", "The Elkhorn"], "why": "The Missouri River. Iowa is right across it."},
	{"q": "The College World Series is played in Omaha every June. Which sport?", "a": ["Baseball", "Basketball", "Volleyball", "Wrestling"], "why": "College baseball. Omaha's hosted it since 1950."},
	{"q": "Which famous investor is nicknamed the 'Oracle of Omaha'?", "a": ["Warren Buffett", "Charlie Munger", "Peter Lynch", "Ray Dalio"], "why": "Warren Buffett. Still lives in the same house he bought in 1958."},
	{"q": "A Reuben sandwich is corned beef, Swiss, Russian dressing and...?", "a": ["Sauerkraut", "Coleslaw", "Pickles", "Fried onions"], "why": "Sauerkraut, on rye. Omaha claims it was invented there."},
	{"q": "How many minutes in a standard NBA quarter?", "a": ["12", "10", "15", "20"], "why": "12. College halves are 20."},
	{"q": "What's the most-used letter in English?", "a": ["E", "A", "T", "S"], "why": "E. Wordle players know."},
	{"q": "How many sides does a hexagon have?", "a": ["6", "5", "7", "8"], "why": "Six. Like a honeycomb. Or a bolt."},
	{"q": "Which planet is known as the Red Planet?", "a": ["Mars", "Venus", "Jupiter", "Mercury"], "why": "Mars. The red is iron oxide. Rust."},
	{"q": "What's the chemical symbol for gold?", "a": ["Au", "Ag", "Gd", "Go"], "why": "Au, from the Latin 'aurum'."},
	{"q": "Which country gave us the croissant as we know it?", "a": ["France", "Italy", "Belgium", "Switzerland"], "why": "France, though it started as an Austrian kipferl."},
	{"q": "How many players does a soccer team have on the field?", "a": ["11", "9", "10", "12"], "why": "Eleven, keeper included."},
	{"q": "What do you call a baby kangaroo?", "a": ["A joey", "A kit", "A cub", "A pup"], "why": "A joey. Lives in the pouch for months."},
	{"q": "Which ocean is the largest?", "a": ["Pacific", "Atlantic", "Indian", "Arctic"], "why": "The Pacific. Bigger than all the land on Earth put together."},
	{"q": "Water boils at sea level at what temperature in Fahrenheit?", "a": ["212°F", "200°F", "180°F", "100°F"], "why": "212°F. 100°C."},
	{"q": "Sriracha's original bottle has a picture of what animal?", "a": ["A rooster", "A dragon", "A tiger", "A snake"], "why": "A rooster. 'Rooster sauce.'"},
	{"q": "How many strings does a standard guitar have?", "a": ["6", "4", "5", "8"], "why": "Six. Bass usually has four."},
	{"q": "What's the hardest natural substance?", "a": ["Diamond", "Granite", "Quartz", "Titanium"], "why": "Diamond. Titanium is a metal, and softer."},
	{"q": "The Statue of Liberty was a gift from which country?", "a": ["France", "England", "Spain", "Canada"], "why": "France, dedicated in 1886."},
	{"q": "In poker, what beats a full house?", "a": ["Four of a kind", "A flush", "A straight", "Three of a kind"], "why": "Four of a kind. Then straight flush. Then royal."},
	{"q": "Which fruit is the main ingredient in guacamole?", "a": ["Avocado", "Lime", "Tomatillo", "Mango"], "why": "Avocado. The lime is just keeping it green."},
	{"q": "What year did the first iPhone come out?", "a": ["2007", "2005", "2009", "2010"], "why": "2007. It didn't even have an App Store yet."},
	{"q": "How many hearts does an octopus have?", "a": ["3", "1", "2", "8"], "why": "Three. And blue blood. Overachiever."},
	{"q": "What's the capital of Canada?", "a": ["Ottawa", "Toronto", "Montreal", "Vancouver"], "why": "Ottawa. Everybody guesses Toronto."},
	{"q": "Which cheese is traditionally on a Philly cheesesteak (besides Whiz)?", "a": ["Provolone", "Cheddar", "Swiss", "Pepper jack"], "why": "Provolone, or Cheez Whiz, or American. Never Swiss."},
	{"q": "A 'baker's dozen' is how many?", "a": ["13", "12", "14", "24"], "why": "Thirteen. One extra so nobody gets shorted."},
	{"q": "Which bird is the fastest diver in the world?", "a": ["Peregrine falcon", "Bald eagle", "Hummingbird", "Pelican"], "why": "Peregrine falcon. 200+ mph in a dive."},
	{"q": "What's the longest bone in the human body?", "a": ["The femur", "The spine", "The tibia", "The humerus"], "why": "The femur. Thigh bone."},
]

func _setup() -> void:
	bank = TRIVIA
	count = 7
	super._setup()
	title = "TRIVIA NIGHT @ CLUB CLOUD 9"
	backdrop = ""
	music = ""

func _draw_backdrop() -> void:
	if Art.tex("arena_djvape") == null:
		super._draw_backdrop()
		return
	Art.image(self, "arena_djvape", Vector2.ZERO)
	draw_rect(Rect2(0, 0, W, H), Color(0.05, 0.03, 0.08, 0.5))
