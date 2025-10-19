// lib/repositories/reading_repository.dart
import 'package:vocachat/models/reading_models.dart';

class ReadingRepository {
  // Singleton pattern için özel constructor.
  ReadingRepository._();
  static final ReadingRepository instance = ReadingRepository._();

  // Hikaye verilerini _seed metodundan alıyoruz.
  final List<ReadingStory> _stories = _seed();

  // Tüm hikayeleri değiştirelemeyen bir liste olarak döndürür.
  List<ReadingStory> all() => List.unmodifiable(_stories);

  // Belirtilen id'ye sahip hikayeyi bulur, bulamazsa null döndürür.
  ReadingStory? byId(String id) {
    try {
      return _stories.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  // Başlangıç verilerini oluşturan özel metot.
  static List<ReadingStory> _seed() {
    return [
      // =======================================================================
      // BEGINNER STORIES
      // =======================================================================
      const ReadingStory(
        id: 'r1',
        title: 'A Busy Morning',
        category: 'Daily Life',
        level: ReadingLevel.beginner,
        description: 'Simple morning routine story.',
        content: '''Emma wakes up very early. It is 6:00 in the morning. The sun is not in the sky yet, but the room is not dark. She gets out of bed and walks to the window.

She opens the window. The air is cool and fresh. She takes a deep breath. She can hear the birds singing in the trees. Emma's house has a small garden, and she can see the green leaves. She feels happy and calm.

After a few minutes, she goes to the kitchen. The kitchen is small and clean. She takes her favorite yellow cup. She wants to make a cup of tea. She puts a tea bag in the cup. She boils some water and pours it into the cup. She likes to watch the water change color.

She takes her hot tea and sits at the kitchen table. She drinks her tea slowly. There is no noise in the house. It is very quiet. This is Emma's favorite time of day.

When her tea is finished, she takes a small notebook and a pen. She thinks about her day. Then she writes a short list. She writes that she needs to go to the market for bread and apples. She also plans to read her new book for an hour, water the flowers in her garden, and call her friend, David.

The list is not long. It is a simple plan. Emma smiles. She is ready for the day. Emma likes her quiet mornings very much.''',
      ),
      const ReadingStory(
        id: 'r4',
        title: 'A Walk in the Park',
        category: 'Daily Life',
        level: ReadingLevel.beginner,
        description: 'A simple story about visiting a park.',
        content: '''It is a sunny afternoon. Leo wants to go to the park. He puts on his shoes and opens the door. The park is not far from his house. He walks for ten minutes.

Soon, he is at the park. He sees many big, green trees. He sees beautiful red and yellow flowers. Many people are in the park. Some people are walking. Some people are sitting on benches.

Leo walks on a long path. He sees a small pond. There are ducks in the water. They are swimming and making noise. Leo smiles. He likes watching the ducks.

He finds an empty bench and sits down. He has an apple in his bag. He eats the apple slowly and watches the people. The park is a happy place. After thirty minutes, he feels relaxed and rested. He decides to go home. It was a good day.''',
      ),
      const ReadingStory(
        id: 'r5',
        title: 'Making Pasta',
        category: 'Food',
        level: ReadingLevel.beginner,
        description: 'Following simple steps to cook a meal.',
        content: '''Sarah is in her kitchen. She is hungry and wants to eat dinner. She decides to make pasta. It is easy and fast.

First, she takes a big pot. She fills the pot with water. She puts the pot on the stove and turns on the heat. She waits for the water to boil. While she waits, she gets the other ingredients. She needs pasta, a jar of tomato sauce, and some cheese.

When the water is boiling with big bubbles, she adds the dry pasta to the pot. She cooks it for ten minutes. She sometimes stirs the pasta with a big spoon.

Next, she takes the pot off the stove. She carefully pours the hot water into the sink. Now, only the cooked pasta is in the pot. She opens the jar of tomato sauce and pours it over the pasta. She stirs everything together.

Finally, she puts the pasta and sauce on a plate. She adds some cheese on top. Her dinner is ready. She sits at the table and eats. The pasta is hot and very delicious.''',
      ),

      // Additional Beginner Stories (longer)
      const ReadingStory(
        id: 'r10',
        title: 'At the Grocery Store',
        category: 'Daily Life',
        level: ReadingLevel.beginner,
        description: 'A longer, simple story about shopping and choices.',
        content: '''Mia needs food for the week. She takes a cloth bag and her small list. The grocery store is five streets away, so she walks. The day is bright, but the wind is cool. She likes the feeling of moving and thinking.

Inside the store, she picks a small cart. First, she goes to the fruit section. Red apples look shiny. Green pears look fresh. She takes four apples and three pears. She thinks of breakfast. She puts a bunch of bananas in the cart too.

Next is the bread aisle. There are many kinds: white bread, brown bread, bread with seeds. Mia reads the labels slowly. She chooses a round, brown loaf. It smells warm and soft.

She turns to the dairy section. She needs milk and yogurt. The milk is cold. She takes a small bottle so she can finish it before it goes bad. She also takes plain yogurt. She likes to add honey and walnuts at home.

For dinner, she wants rice and vegetables. She takes a bag of rice and a small bottle of olive oil. In the vegetable section, she finds carrots, broccoli, and a red onion. She touches the broccoli gently. It is firm and dark green. Good.

Mia stops at a quiet corner and checks her list again. She adds tea, because her friend will visit on Sunday. She also remembers to buy soap. She chooses one with a lemon smell. It reminds her of summer.

At the checkout, the line is short. The cashier smiles and asks, "Did you find everything?" Mia smiles back. "Yes, thank you." She pays and puts the items in her cloth bag. The bag is heavy now, but she feels happy. She knows what she will cook this week.

On the way home, she walks slowly. She watches a small dog pull a big stick. A child laughs. A bus stops and opens its doors with a soft hiss. Life around her feels simple and kind.

At home, Mia washes the vegetables and places the fruit in a bowl. She makes tea and sits by the window. The day is still bright. She writes a few ideas for meals: rice with broccoli and carrot, yogurt with honey, toast with olive oil and a little salt. Her plans are small, but they make her week feel warm and easy.''',
      ),
      const ReadingStory(
        id: 'r11',
        title: 'A Rainy Day Plan',
        category: 'Daily Life',
        level: ReadingLevel.beginner,
        description: 'Staying inside, making a cozy day feel full.',
        content: '''Rain taps on the window all morning. David wakes up and listens. He likes the gentle sound. The sky is gray, and the streets are wet. He decides to stay home and make the day slow and nice.

He makes oatmeal with cinnamon. He stirs it until it is thick. He eats near the window and watches the rain lines on the glass. After breakfast, he cleans the table and washes the bowl.

He takes a small box from a shelf. Inside are puzzle pieces. He pours them out on the table. The picture is a lighthouse by the sea. The edges are easy. He starts with them and feels calm as the pieces click together.

After an hour, he takes a break. He boils water and makes mint tea. He calls his grandmother. They talk about the garden, the cat, and an old recipe for lentil soup. She laughs when he says he forgot the salt last time. "It happens," she says. "Just taste as you go."

The rain gets stronger and louder. He takes a blanket and reads a simple book he loves. The story is about a boy who plants a seed and waits. David likes the waiting part. It reminds him that slow is good.

In the afternoon, he cooks the lentil soup again. This time, he adds salt. He tastes and nods. It is better. He eats with bread and feels warm.

By evening, the rain becomes soft again. David finishes the puzzle. The lighthouse stands tall in the picture. He turns on a small lamp and writes a short note in his journal: "A rainy day can be full, even when I do not go anywhere." He smiles and gets ready for bed.''',
      ),

      // =======================================================================
      // INTERMEDIATE STORIES
      // =======================================================================
      const ReadingStory(
        id: 'r2',
        title: 'The Lost Key',
        category: 'Mystery',
        level: ReadingLevel.intermediate,
        description: 'A small mystery about a missing key.',
        content: '''The day had been demanding, and Liam felt the exhaustion in his bones as he finally reached his front door. He longed for the simple comfort of his armchair. Reaching into his jacket pocket, he anticipated the familiar cool, metallic touch of his house key. His fingers, however, found nothing but the smooth lining of the pocket and a crumpled receipt from lunch. A flicker of irritation sparked within him. "Odd," he thought, and patted his other jacket pocket. Empty.

His heart rate quickened slightly. He methodically began to check his trouser pockets, first the right, then the left, his movements becoming less casual and more urgent. The knot of annoyance in his stomach was now tightening into genuine concern. He placed his heavy briefcase on the ground with a thud and knelt, deciding to conduct a more thorough search. He unzipped every compartment of the briefcase, pulling out documents, a laptop, and a collection of pens, but the key was nowhere to be found among them.

The sky, which had been a neutral, overcast gray, began to shed a persistent, drizzling rain. The cold droplets on his neck made him shiver. A sense of desperation crept in. He looked around his porch, his eyes scanning for any possible place he might have left it. He lifted the worn, bristly doormat, revealing nothing but a few dry leaves and a spider. He peered into the depths of a large, dusty plant pot nearby, feeling increasingly ridiculous. What if he had dropped it on the street? The thought of searching the entire sidewalk was overwhelming.

He leaned against the cold brick of his house, the rain dampening his hair, and closed his eyes. He took a deep breath, trying to push down the rising panic and reconstruct his afternoon. He visualized leaving his office building, walking down the busy street, getting on the bus... The bus! He had been reading a book. Maybe it slipped out of his pocket then? But that didn't feel right. He continued the mental playback. After the bus, he had felt a sudden need for caffeine. And then, the memory surfaced, sharp and vivid.

The small coffee shop, "The Daily Grind." He could almost smell the rich aroma of roasted coffee beans. He pictured the worn wooden counter, the friendly barista, and the way the afternoon light streamed through the front window. And there it was, a clear image in his mind's eye: his solitary silver key, resting on the counter right next to his empty espresso cup, forgotten at the exact moment he paid and rushed out.

A sudden, booming laugh escaped his lips, startling a passing pedestrian. The intense wave of relief was so powerful it erased all his previous frustration. He was a fool, but a relieved one. Shaking his head at his own forgetfulness, he zipped up his briefcase, leaving it on the porch, and began to jog back through the steady rain, a wide, self-deprecating smile fixed on his face.''',
      ),
      const ReadingStory(
        id: 'r6',
        title: 'The Missed Train',
        category: 'Adventure',
        level: ReadingLevel.intermediate,
        description: 'A story of quick thinking under pressure.',
        content: '''Clara raced through the crowded station, her bag bouncing against her side. The enormous station clock showed it was 9:02 AM. Her train—the 9:00 AM express to Crestwood—was scheduled for the most important interview of her career. As she reached the platform, she saw the last red lights of her train disappearing down the track. A feeling of cold dread washed over her. For a moment, she just stood there, watching her opportunity vanish into the distance.

Panic began to set in, but she forced it down. "Okay, think," she whispered to herself. The interview was at 10:30 AM. Crestwood was an hour away by train. She quickly looked at the departure board. The next train wasn't for another fifty minutes; it would be far too late. Her mind raced through the possibilities. A taxi would be incredibly expensive, and the morning traffic would be a nightmare.

Her eyes scanned the station signs and she saw a small, faded one she had never noticed before: "Intercity Bus Terminal." With a new surge of hope, she hurried towards it. The terminal was much smaller and quieter than the train station. She found the ticket counter and asked the attendant, "Is there a bus to Crestwood leaving soon?"

The man looked at his schedule. "The 9:15 Express just started boarding. It's your lucky day. It makes only one stop. You'll be there by 10:15." Relief so powerful it almost made her dizzy flooded through her. The ticket was more expensive than the train, but it was a small price to pay. She bought it, thanked the man, and ran to the indicated departure gate. As she settled into her seat and the bus pulled away from the station, she took a deep breath. She had turned a potential disaster into a minor inconvenience. The interview was still on.''',
      ),
      const ReadingStory(
        id: 'r7',
        title: 'An Unexpected Letter',
        category: 'Human Story',
        level: ReadingLevel.intermediate,
        description: 'Receiving a message from a long-lost friend.',
        content: '''It was an ordinary Tuesday for Elara until the mail arrived. She sorted through the usual collection of bills and advertisements without much interest. But then she saw it: a thick, cream-colored envelope made of heavy paper. It stood out immediately. There was no return address, and her name was written in elegant, looping cursive with an ink pen. It felt like an object from another time.

Curiosity piqued, she carefully opened it. The paper inside was slightly yellowed with age and carried a faint, pleasant scent of old books. The handwriting matched the envelope—graceful and strangely familiar. As she began to read, her breath caught in her throat. The letter was signed "Leo," her childhood best friend, from whom she hadn't heard in nearly fifteen years after his family moved across the country.

The letter was not just a simple hello. Leo wrote about recently finding an old journal where he described a "time capsule" they had buried together in the woods behind her childhood home. He said he couldn't remember what they put inside, but he vividly recalled the promise they made to open it together one day. He had even drawn a detailed, hand-drawn map from memory, marking an old oak tree with a small "X" at its base.

A flood of forgotten memories rushed back to Elara: building forts, exploring the creek, and the solemn ceremony of burying their secret box. She had completely forgotten about it until this moment. The letter ended with a question: "Is it still there? I'll be in town next month. Maybe we can finally find out." Holding the letter, Elara felt a surprising mix of nostalgia and a thrilling sense of adventure. A piece of her past had reached out and offered a new beginning.''',
      ),

      // Additional Intermediate Stories (longer)
      const ReadingStory(
        id: 'r12',
        title: 'The Old Library Puzzle',
        category: 'Mystery',
        level: ReadingLevel.intermediate,
        description: 'A quiet riddle hidden between dusty shelves.',
        content: '''On rainy afternoons, Noor liked to sit in the city library, a building of stone and stained glass that smelled of old paper and lemon polish. The reading room was her favorite: long tables, brass lamps, and a ceiling painted with faded constellations. That day, the librarian placed a small cardboard box on the returns desk with a note: "Found between stacks G-H. No checkout record."

Noor asked if she could open it. Inside lay a pocket-sized notebook bound in cracked blue leather. The first pages were lists of book titles, each title followed by a number and a small symbol. Some had circles, some had triangles, and a few had stars. The dates were from decades before Noor was born.

She took the notebook to a table and compared the titles to the library catalog. Each book still existed in the collection, each still in the same call number range. She pulled the first one—"A Treatise on Wind"—and a slip of onion-skin paper fell out: "North windows whistle when words wander." It made no immediate sense.

Hours passed. The rain fell harder. Noor noticed a pattern: star-marked books hid slips with sentences. The sentences, when placed in the order of the catalog numbers, formed a paragraph that sounded like advice. When she assembled them, the message read: "In rooms of silence, carry small questions as lanterns. Leave answers where the dust is thin. Let the wind teach you which pages to turn."

She smiled, feeling as if someone from the past had reached across time to leave a gentle instruction. Noor returned the notebook and the slips to the box and wrote her own note on a card: "The lanterns still glow." She left it between stacks G-H, where the librarian had found the box, and walked into the soft echo of rain, her mind lit by the smallest of mysteries.''',
      ),
      const ReadingStory(
        id: 'r13',
        title: 'Detour on the Mountain Road',
        category: 'Travel',
        level: ReadingLevel.intermediate,
        description: 'A wrong turn becomes the day’s best choice.',
        content: '''The GPS lost its signal as soon as the road began to climb. Tessa had planned a straight route to the lake, a quick hike, and a late lunch. But a sign that read "ROAD CLOSED AHEAD" forced her to take a narrow detour that wound through pines and sudden, dizzying overlooks.

She considered turning back, yet the detour offered something the main road never had: silence, except for the tick of cooling brakes when she stopped to look. She found a pullout where a forgotten trail began, marked only by a wooden post with peeling paint. She took her water bottle and followed the path.

The trail bent through ferns and damp rock, then opened to a small meadow filled with wildflowers in improbable colors. She stood still. Bees moved like commas between sentences of color. A hawk circled once and vanished behind a ridge. Tessa checked the time, then put her phone back in her pocket. Lunch could wait.

At the meadow’s far edge, the trail ended at a viewpoint over a hidden tarn. The surface of the water was a mirror, disturbed only by wind. She sat, ate an apple, and felt her plans loosen. The day no longer measured itself in destinations, but in the length of her breath.

When she returned to the car, the GPS found her again. It offered her three fast routes to the lake. She chose the slowest one and laughed, already knowing that the best part of the day had happened off the map.''',
      ),
      const ReadingStory(
        id: 'r14',
        title: 'A Call at Midnight',
        category: 'Suspense',
        level: ReadingLevel.intermediate,
        description: 'An unexpected call reopens an old story.',
        content: '''The phone rang once at 11:59 PM, a single bright sound in a quiet apartment. Mara let it go to voicemail. It rang again at 12:03 AM. She answered.

"Mara?" The voice was older than she remembered, but the shape of it was the same. Amir. Ten years had passed since their last conversation, which had ended with a door closing softly and a plane taking off.

"I found the key," he said without preface. "The one from your grandmother’s music box. The tune it plays has another part—there’s a second cylinder hidden under the velvet. It wasn’t broken after all."

Mara stood and turned on a small lamp, suddenly more awake than she’d felt all week. Her grandmother had taught her to listen for the notes that were missing, to hear the shape of a song even when it was broken. "Where are you?" she asked.

"Outside," he said. "Look down."

Mara pulled the curtain aside and saw him standing on the street, a small figure under the halo of a streetlamp, holding up a familiar wooden box. The years slid back like a drawer, revealing what had always been tucked away. She laughed, then cried, then laughed again, unlocking the door as the first notes of the full song rose, clear and whole, to meet the new day.''',
      ),

      // =======================================================================
      // ADVANCED STORIES
      // =======================================================================
      const ReadingStory(
        id: 'r3',
        title: 'Winds Above the Valley',
        category: 'Literary',
        level: ReadingLevel.advanced,
        description: 'Reflective descriptive prose.',
        content: '''Perched precariously upon the mountain's formidable spine, where the air thins to a crystalline sharpness, the old observatory endures. It is a lonely sentinel, a monument to a bygone era of cosmic inquiry. With every relentless gust of wind that sweeps across the barren rock, its entire structure groans, a deep, resonant complaint against the implacable forces of nature. The thin steel cables anchoring it to the granite hum with a tense, vibrational frequency, a monotonous metallic drone that harmonizes with the percussive rattling of loosened, rust-stained panels. This is the mountain's desolate symphony, a fragile cacophony set against the profound, indifferent silence of the peaks.

To step inside is to cross a threshold into a pocket of arrested time. The air is heavy, freighted with the distinct, nostalgic scents of decaying paper, cold, dormant metal, and the pervasive, chalky smell of dust. In the narrow shafts of light that manage to pierce the gloom of the interior, constellations of dust motes perform a slow, silent ballet, their dance momentarily illuminating the faded grandeur of the space. They settle upon vast celestial charts that curl at the edges, their once-bold black ink softened by decades of sunlight to a ghostly gray. Here, forgotten discoveries and superseded theories lie in state. The colossal telescope, a masterpiece of brass and glass, remains a silent oracle. Its great lens, clouded by a fine nebula of neglect, is perpetually aimed at a sky it can no longer resolve, a mute testament to its own obsolescence.

Yet, the profound quietude that saturates this chamber is not an emptiness; it is not a void. Rather, it is a spacious, pregnant pause—a temporal vessel holding the accumulated weight of innumerable, patient questions posed to the cosmos. One can almost sense the spectral presence of the long-dead astronomers, their intellectual fervor and disciplined curiosity lingering like a residual energy. The observatory, in its inexorable decay, becomes a philosophical artifact, a meditation on the poignant juxtaposition of ephemeral human endeavor against the vast, almost incomprehensible timescale of the universe itself.

Outside, as the earth completes its diurnal rotation, the day surrenders its dominion. The night does not simply arrive; it performs a majestic, deliberate gathering of the scattered remnants of light. It collects the bruised purples, the fading tangerines, and the last vestiges of sapphire from the horizon, meticulously folding them into a deep, crystalline indigo. This profound darkness is not an erasure but a revelation. It is a grand unveiling of the celestial stage, promising another immaculate, star-dusted dawn for any consciousness—or any instrument—still calibrated, still willing, to look upward and wonder.''',
      ),
      const ReadingStory(
        id: 'r8',
        title: 'The City from Above',
        category: 'Literary',
        level: ReadingLevel.advanced,
        description: 'A philosophical observation of a metropolis at night.',
        content: '''From the fifty-fourth floor, the city ceased to be a place of concrete, steel, and individual lives. It transmuted into an abstraction, a sprawling, luminous circuit board alive with pulsing energy. The relentless cacophony of traffic, the symphony of a million simultaneous actions, was muted to a distant, ambient hum—the sound of a colossal, sleeping organism. Headlights and taillights became coherent streams of data, flowing through the arterial canyons of the streets, their red and white currents painting transient patterns on the asphalt canvas below.

Each pinprick of light in the buildings across the expanse was not merely a window, but a potential narrative. Behind one, a drama of heartbreak; behind another, a celebration of success; behind thousands more, the quiet, unremarkable rituals of domesticity. The observer on the balcony is granted a god's-eye view, yet it is a perspective devoid of divine insight. The sheer scale of it all renders the individual story both infinitely precious and statistically insignificant. This is the central paradox of the metropolis: a profound sense of isolation experienced amidst an unprecedented density of human connection.

The city breathes. The slow, rhythmic pulse of the traffic lights acts as a regulatory heartbeat, while the occasional wail of a distant siren is a nerve impulse, a signal of distress within the larger system. This sprawling entity is a testament to humanity's collective will, a complex ecosystem built of ambition, commerce, and dreams. Yet, it remains utterly indifferent to the observer, a beautiful and terrifying construct that would continue its luminous, intricate dance whether anyone was watching or not. To witness it from such a height is to contemplate one's own transience against a backdrop of something that feels, deceptively, like permanence.''',
      ),
      const ReadingStory(
        id: 'r9',
        title: 'The Forgotten Photograph',
        category: 'Literary',
        level: ReadingLevel.advanced,
        description: 'Reflections on time, memory, and an old picture.',
        content: '''Deep within the cedar-scented confines of an attic trunk, nestled between moth-eaten woolen blankets and bundles of letters tied with faded ribbon, lay the photograph. It was a small, sepia-toned rectangle of cardstock, its corners softened and its edges feathered from a century of patient obscurity. The image it held captive was of four individuals—two men, two women—posed formally before a clapboard house that had long since surrendered to time and been replaced by a parking lot.

Their faces, frozen in the unforgiving clarity of the old collodion process, were studies in ambiguity. Their expressions were neither happy nor sad, but possessed a stolid neutrality that defied simple interpretation, leaving the viewer to project their own narratives onto the silent subjects. These were not ancestors he recognized; their identities were as lost as the house they once inhabited. They were artifacts of a parallel existence, their entire world of relationships, struggles, and joys compressed into this single, silent tableau. The photograph was not, for him, a vessel of memory, but a stark confrontation with its absence.

Holding the object was like holding a fragment of unwritten history. It served as a potent reminder that the past is not a singular, monolithic narrative, but an infinite collection of such forgotten fragments, each one a complete universe that has collapsed into a single point. These four people had lived lives as complex and vivid as his own, yet their entire legacy, at least in this attic, had been distilled into this chemical shadow on paper. It was a humbling, disquieting thought: that we are all, ultimately, destined to become someone else's forgotten photograph, our own intricate lives eventually flattening into a mysterious, unreadable artifact for a future we cannot imagine.''',
      ),

      // Additional Advanced Stories (longer)
      const ReadingStory(
        id: 'r15',
        title: 'The Cartographer of Lost Rivers',
        category: 'Literary',
        level: ReadingLevel.advanced,
        description: 'A meditation on maps, memory, and water that disappears.',
        content: '''He arrived in towns no atlas remembered and asked for directions to water that no longer showed its face. People would point, vaguely at first, toward a dry arroyo or a line of darker soil threading a field, and he would follow, notebook in hand, sketching the contour of absence. He was a cartographer of lost rivers, a maker of maps that marked not what could be sailed, but what could be mourned.

His maps were beautiful in the way old scars are beautiful—evidence of healing, but also of harm. Blue ink for what had once been, a pale gray for what might return in years of kindness. He noted the artifacts the water had abandoned: a bridge that now leapt over weeds, an oar nailed above a door like a charm, the fossil of a boat ramp that led to dust.

Where elders remembered, he listened. They spoke of flood years when the world was a mirror, and of summers when cattle kicked up clouds that tasted like pennies. A woman with a voice like gravel told him about lantern festivals on the river that had stitched light into the current. Her hands moved as if arranging candles that were no longer there. When she finished, he drew a small procession of flames beside the blue thread of the river that had once approached her village like a blessing.

The work changed him. He began to hear dryness as a sound—small stones clicking in a streambed, the brittle whisper of reeds finding only wind. In hotel rooms, he awoke at night hearing water that did not exist, the way a missing limb might itch with remembered nerve. He traced and retraced the ghostly paths until they were as familiar as the veins on his own hands.

On his last map, he drew a river that had not yet vanished but was thinning, its geometry becoming tentative. He added, in the margin, a note in the tiniest script: "Maps are promises we make to what we love: that we will look again, and then again, until looking becomes a form of care."''',
      ),
      const ReadingStory(
        id: 'r16',
        title: 'The Museum at Closing Time',
        category: 'Literary',
        level: ReadingLevel.advanced,
        description: 'After hours, objects speak in the language of light and dust.',
        content: '''At 5:58 PM, the museum became a theater of almosts. The guards hovered near doors, docents delivered the last facts, and visitors hurried through final rooms wearing the look of people trying to drink a river with their hands. By 6:05, the rooms were empty, but emptiness is a misnomer; what remained was everything that had never left: the hush inside marble, the patience of clay, the long breath of wood.

He was the last conservator on duty, a man whose job required a tenderness that made him quiet in other parts of his life. He carried a small flashlight not to banish darkness, but to invite it to soften around what he needed to see. In the Impressionists gallery, the paint still seemed wet with weather. He leaned close to a haystack and saw, within what looked like yellow, a hundred greens speaking in low voices.

In the hall of instruments, a viol trembled on its stand when a subway passed beneath the building, a resonance so subtle it felt like a secret. He thought of the hands that had polished it centuries ago, of rosin and rooms the size of pockets. He made a note to adjust the humidity by a single degree.

Closing time is a misdirection. What closes is the door to rush. What opens is the possibility of attention that is not transactional. He stood in the room of unlabelled fragments—terracotta, bone, a bronze hinge—and felt the grandeur of what's incomplete. He wrote in his log: "Some objects are not waiting to be explained. They are waiting to be accompanied."''',
      ),
      const ReadingStory(
        id: 'r17',
        title: 'Letters to a Future Self',
        category: 'Reflective',
        level: ReadingLevel.advanced,
        description: 'Time capsules in plain envelopes, mailed across years.',
        content: '''He wrote on cheap stationery because he wanted the words to do the work, not the paper. Every birthday, he addressed an envelope to himself ten years hence and mailed it to a post office box he paid for in five-year increments. Inside, he placed a letter that did not predict but recorded: the names of trees in his neighborhood, the recipe he had finally gotten right, a mistake he did not yet know how to forgive.

The first letter arrived like a stranger at the door who knew the color of the kitchen walls. He opened it with a paring knife and found himself described with a precision that was neither kind nor cruel, only exact. The letter did not ask whether he had become successful. It asked whether he still hummed when he read, whether the shoes by the door formed a small conversation when he was asleep.

As the years passed, the letters accumulated into an archive of the ordinary, which is to say, an archive of life. He learned to trust the person who had written to him and to write back with the same honesty: "I am trying to be a neighbor to my own days. Some mornings I succeed."

On the last occasion, he wrote only a single sentence and folded the page around a pressed leaf: "Please remember that you are allowed to change the question."''',
      ),
      const ReadingStory(
        id: 'r18',
        title: 'Tectonics of Quiet',
        category: 'Essay',
        level: ReadingLevel.advanced,
        description: 'A lyrical essay on silence as movement rather than absence.',
        content: '''Quiet is not the absence of sound but the presence of attention spread so evenly that it does not clump around any single noise. In the library, quiet is the geography of pages turning in asynchronous weather. In a chapel, quiet is a vertical wind. In a forest after snow, quiet is an attic where all the stairs remember your feet.

We speak of fault lines when the earth moves, but our days have their own tectonics. Conversations shift plates beneath our ribs; a glance can raise a mountain range overnight. Quiet, then, is not stillness but a way of noticing the slow continental drift of meaning as it builds new coastlines inside us. The loudest changes arrive without sirens.''',
      ),
      const ReadingStory(
        id: 'r19',
        title: 'An Atlas of Small Kindnesses',
        category: 'Human Story',
        level: ReadingLevel.advanced,
        description: 'Mapping the ordinary gestures that hold a city together.',
        content: '''No one recorded them, so she did. Not with a camera—too intrusive—but with a notebook that fit in a coat pocket and a series of symbols she invented on the train. A triangle for the person who stood so a tired nurse could sit. A wavy line for the cafe owner who knew the names of stray cats. A dot inside a circle for the teenager who, without ceremony, held a door against a rush of wind that might have knocked an old man backward.

She began to see the city as a palimpsest of kindness, faint lines revealing a second map under the visible streets. At certain intersections, generosity pooled like rainwater after storms. On some blocks, it rose in the mornings like steam from grates—small wafts of gentleness as buses exhaled and bakery doors opened.

When she felt hopeless, she took the notebook and walked the routes where her symbols clustered. There, a mechanic refused payment for tightening a loose chain. There, a child placed a sticker on a parking meter and the meter, suddenly decorated with a smiling sun, seemed to forgive the whole enterprise. Her atlas did not pretend the city was always kind. It simply proved that kindness was always somewhere, and that "somewhere" could be reached by foot.''',
      ),
      const ReadingStory(
        id: 'r20',
        title: 'The Clockmaker’s Apprentice',
        category: 'Fiction',
        level: ReadingLevel.advanced,
        description: 'Precision, patience, and the moment a mechanism remembers time.',
        content: '''Master Grunwald taught with his hands more than his voice. "Listen," he would say, placing a failed escapement on the bench. "Failure is a sound. Find it." The workshop smelled of oil and tin, and the city’s hours arrived in waves through the window: bells, the hiss of buses, footsteps that accelerated at lunch and softened at dusk.

The apprentice learned the ethics of attention. Steel could be persuaded but not bullied; brass preferred apologies to pressure. He polished until his fingers memorized the heat of friction and learned, in his wrists, the geometry of grace. One evening, after a week of misaligned teeth and temper, the apprentice set a repaired carriage clock on the counter and wound it. The mechanism caught, hesitated, and then—tick. Not a loud tick. A right tick. A tick that matched the pulse in his throat.

Master Grunwald nodded as if he had heard a sentence finally spoken in the correct tense. "You did not fix it," he said. "You invited it to remember itself."''',
      ),
      const ReadingStory(
        id: 'r21',
        title: 'After the Storm, the City',
        category: 'Descriptive',
        level: ReadingLevel.advanced,
        description: 'A city rinsed and rearranged by weather becomes legible again.',
        content: '''Morning found the city edged in brightness, every surface newly articulate. The storm had spent itself in the small hours, hammering roofs and braiding gutters into temporary rivers. Now, leaves lay pressed like coins against drains, and the air carried the sharp metal scent of clean.

Shopkeepers swept water out of doorways in synchronized gestures learned from years of weather. A boy in rubber boots sailed a paper boat along the curb and chased it until the current took it under the street, where all small voyages end. Sunlight found millions of water droplets and assigned each a brief duty: mirror, prism, jewel.

The storm had rearranged the grammar of things. Puddles became commas that slowed pedestrians into noticing. A toppled sign—CAREFUL: SLIPPERY—was now a quiet joke. The city, rinsed, seemed to say: try again. And the day did.''',
      ),
      const ReadingStory(
        id: 'r22',
        title: 'The Algorithm and the Orchard',
        category: 'Speculative',
        level: ReadingLevel.advanced,
        description: 'Where prediction meets seasons and both learn humility.',
        content: '''They built a model to predict the yield of an old orchard, feeding it weather data, soil moisture, bee counts, and the history of hands. The model grew elegant and precise, drawing delicate curves that foretold sweetness, as if sugar could be graphed.

Then the bees arrived late, the rain arrived early, and the hands did not arrive at all because sickness had thinned them. The model apologized by adjusting its confidence intervals, but the trees were unconcerned. They followed a choreography not written in code: a late frost rehearsed for decades, a wind that made and unmade its mind. The apples that did grow were fewer, stranger, and more delicious, as if irregularity itself were a spice.

In the end, the algorithm learned to output not a number but a sentence: "Expect surprises; prepare generosity." The orchard learned nothing, which was its wisdom.''',
      ),
    ];
  }
}

