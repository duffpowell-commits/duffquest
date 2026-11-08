extends RefCounted
## Palahniuk-style "fun fact" drops (M9, Nov 8): Duff at the bar dropping a real, deadpan fact and
## turning it on his own life. Shown on bus/minivan rides (35%) and after "So where was I." on load.
## Rules: every fact must be TRUE (or framed as legend); one turn of the knife after it, max.
## Keep them ~120 chars: they share the dialogue box (tools/text_fit.gd checks them).

const FACTS: = [
	"Fun fact: Omaha gave the world the TV dinner. 1953, Swanson. A meal built so nobody has to sit at a table.",
	"Fun fact: FEMA checks if the Waffle House is open to judge how bad a disaster is. If they're closed, run.",
	"Fun fact: Monopoly started as 'The Landlord's Game,' 1904. It was made to show how landlords ruin you. We missed the point.",
	"Fun fact: your body rebuilds donated plasma in a day or two. The $50 is gone in about an hour.",
	"Fun fact: the US supplies about two-thirds of the world's plasma. We export ourselves, one arm at a time.",
	"Fun fact: plasma is about 92% water. So technically I'm selling water. To a company. That sells it back.",
	"Fun fact: cats sleep 12 to 16 hours a day. Ours save the other 8 for 3 AM.",
	"Fun fact: cats can't taste sweet. Which explains a lot about {cat3}.",
	"Fun fact: a newborn sleeps 14 to 17 hours a day. In two-hour pieces. Like a bomb with a snooze button.",
	"Fun fact: babies have around 300 bones. Grown-ups have 206. Life just fuses you together and calls it maturity.",
	"Fun fact: a baby goes through about 2,500 diapers the first year. I've changed every single one in my sleep.",
	"Fun fact: caffeine's half-life is about five hours. The 4 PM coffee is still in me at 9. Half of it. Judging me.",
	"Fun fact: 18 hours awake slows your reflexes like a couple of drinks. Closing shift is basically a bar crawl.",
	"Fun fact: nobody knows for sure where '86' comes from. Every cook has a theory. Every theory is wrong.",
	"Fun fact: legend says the 100 pleats on a chef's hat are 100 ways to cook an egg. I know four. Two are on fire.",
	"Fun fact: fryer oil runs 350 to 375 degrees. Water burns skin in a second at 160. Do the math. My arms did.",
	"Fun fact: the real name of Black Forest cake is Schwarzwälder Kirschtorte. There's cherry brandy in it. Hell of a cake.",
	"Fun fact: vanilla is the second most expensive spice on Earth. Vanilla Ensure costs $4. Somebody's lying.",
	"Fun fact: ketchup was sold as medicine in the 1830s. Then they realized fries were the medicine.",
	"Fun fact: the microwave was invented when a radar melted a candy bar in an engineer's pocket. Science is just accidents with funding.",
	"Fun fact: Heinz had over 60 products when it picked '57.' Henry just liked the number. That's branding.",
	"Fun fact: honey basically never spoils. Archaeologists found edible honey in Egyptian tombs. My rent check spoils in a day.",
	"Fun fact: bananas are berries. Strawberries aren't. Nothing is what it says on the label.",
	"Fun fact: the lining of your stomach replaces itself every few days. Mine files for a transfer after family meal.",
	"Fun fact: there's enough iron in a person to make a small nail. Some days that's the whole retirement plan.",
	"Fun fact: the first ATM opened in London in 1967. Now my bank charges $3 to give me my own money.",
	"Fun fact: legend says the credit card started when a guy forgot his wallet at dinner. He forgot. We pay 34%.",
	"Fun fact: a dollar bill lasts about six and a half years. Mine last about six and a half minutes.",
	"Fun fact: pay only the minimum on a credit card and the balance can take decades to clear. Not a bug. The product.",
	"Fun fact: a cat's purr runs about 25 to 150 hertz. Some scientists think that helps bones heal. {cat1} uses it for tuna.",
	"Fun fact: an octopus has three hearts. I have one, and it works doubles.",
	"Fun fact: Kool-Aid was invented in Hastings, Nebraska, in 1927. Our proudest export is sugar water. Respect.",
	"Fun fact: your skin sheds tens of thousands of cells a minute. Every shift, I leave a little of me on the line.",
	"Fun fact: line cooks stand eight hours or more a shift. The chair in the break room is for decoration.",
	"Fun fact: self-checkout was sold as 'saving you time.' It saves THEM a cashier. You're the cashier now. Unpaid.",
	"Fun fact: the US doesn't guarantee a single day of paid vacation. Chef calls that 'flexibility.'",
	"Fun fact: Nebraska is the only state with a one-house legislature. Even our government skipped a step to save money.",
	"Fun fact: the Reuben sandwich might have been invented in Omaha. New York says no. Both sides are eating well.",
	"Fun fact: the brain uses about 20% of your calories. Mine spends all of it on rent math.",
	"Fun fact: a skunk can spray about ten feet. A raccoon can open a trash can latch. The animals are unionizing.",
]

static func pick(i: int) -> String:
	return FACTS[posmod(i, FACTS.size())]
