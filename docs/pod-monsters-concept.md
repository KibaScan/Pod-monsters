# Pod Monsters — Concept Document

A heads-up, hands-free wellness RPG built on AirPods Pro 4 cameras and spatial audio. **Walk. Lift. Meditate. Cast.** Discover, capture, and evolve a personal team of Pod Monsters by training, sitting still, and fishing in the real world.

> **Companion documents**
> - `pod-monsters-asset-pipeline.md` — Asset strategy, tooling, tech stack, cost tiers for Phase 0

---

## 1. Pitch

Pod Monsters turns the real world into an immersive RPG without requiring the user to stare at a screen. Three core activity pillars — walking/cardio, strength training, and meditation — power a creature-collection loop, with a fourth destination modality (fishing) anchoring weekend rituals and active recovery. The differentiator is AirPods Pro 4's infrared cameras, spatial audio, and gesture detection, which let players discover and capture monsters while keeping form clean and presence high. **The quality of the workout is the controller.**

**Positioning:** Pokémon GO meets a personal trainer, but heads-up and hands-free.

**Tagline:** *Walk. Lift. Meditate. Cast.*

---

## 2. The Golden Rule

The single design principle the rest of the app flows from:

- **The Hunt is 100% audio + gesture.** Phone stays in the pocket during workouts. All interaction is driven by spatial audio cues, biometrics, and empty-handed gestures detected by AirPods.
- **The Habitat is 100% iPhone AR.** After the cool-down, users pull out their phone to view captured monsters in their physical space, feed them, manage evolutions, and browse the collection.

This separation solves the safety hazard of screen-staring during exercise (Pokémon GO's biggest flaw) and keeps form clean during lifts.

---

## 3. Hardware Foundation

AirPods Pro 4 (rumored late 2026) ship with **infrared cameras** plus enhanced motion and audio sensors. They're built for environmental sensing and gesture recognition, not photography. Designing to what the hardware actually does — not what feels cinematic — is the difference between a buildable app and a demo reel.

### What AirPods Pro 4 can do
- Detect environment around the user (biome, lighting, proximity to objects)
- Recognize hand gestures in the field of view
- Track head position, stillness, and micro-movements
- Detect head tilt and carriage (downward IR coverage)
- Capture cadence, gait, and motion via accelerometer/IMU
- Deliver directional spatial audio
- Pass visual context to iPhone via Apple Intelligence
- Estimate breath rhythm via internal mics and motion

### What AirPods Pro 4 cannot do
- See the user's face or eyes (cameras face outward from the ears)
- See the user's full body or spine
- Track gaze
- Score lifting form by skeletal geometry alone
- Replace ARKit-grade spatial mapping

### What Apple Watch contributes
- Heart rate, heart rate zones
- HRV (heart rate variability) — critical for verifying actual parasympathetic state
- AssistiveTouch pinch and clench detection (works today)
- Sleep tracking

**Design rule:** if a mechanic requires the AirPods to see something on or in front of the user's body, it doesn't work. Use the iPhone or Apple Watch, or redesign the mechanic.

---

## 4. Core Loop

1. **Equip a buddy** — pick the Pod Monster that comes with you for this session. It earns the XP.
2. **Train** — walk, lift, meditate, or fish. AirPods detect activity, environment, cadence, stillness, and gestures.
3. **Discover** — monsters spawn based on biome, pace, time, and exertion state. Spatial audio cues their location.
4. **Capture** — use activity-specific mechanics (pace-match, shield crack + rest capture, breath sync, Tai-Chi reel) plus a gesture to seal the catch.
5. **Evolve** — XP routes into stats. Balanced training across all pillars unlocks hybrid monsters.
6. **Return** — geodes hatch on cumulative thresholds, bait stockpiles fund fishing trips, seasonal monsters appear, rested buddies grant XP multipliers.

---

## 5. Monster Taxonomy & The Day 1 Choice

Three base factions mapped one-to-one with the activity pillars. New users take a brief lifestyle baseline and pick their starter based on their primary wellness goal.

### The Kinetic Faction (Cardio / Agility)
- **Elements:** Wind, electricity, kinetic light
- **Stats:** Speed, agility
- **Starter — Zephyr:** A sleek, geometric hare/fox hybrid made of static electricity. Its ears pulse to the beat of your live heart rate.

### The Forge Faction (Strength / Power)
- **Elements:** Earth, magma, metal
- **Stats:** Power, HP
- **Starter — Basalt:** A levitating golem made of cracked obsidian with glowing magma inside. The heavier and slower you lift (Time Under Tension), the brighter its core burns.

### The Aether Faction (Meditation / Focus)
- **Elements:** Water, cosmic light, void
- **Stats:** Focus, special
- **Starter — Lumina:** An ethereal jellyfish-like manta ray that floats silently. Its wings expand and contract in sync with the ideal 4-7-8 breathing tempo, acting as a visual breath-pacer.

### Hybrids and Legendaries
Balanced training unlocks hybrid evolutions and fusion monsters. A Forge starter fed cardio and meditation XP can evolve into a Monk-type with balanced stats. Legendaries unlock through milestones (30-day streaks, lifetime PRs) and seasonal events.

Every monster has a visible reason to do every activity.

---

## 6. Art Direction: "Bioluminescent Geometry"

Pod Monsters must avoid looking like a Pokémon clone. The app is a premium wellness tool; the aesthetic should feel sleek, calming, and mature — Apple design meets Studio Ghibli.

Pod Monsters are made of glowing, semi-transparent energy arrays and natural elements. Not fleshy, not cartoony. Living origami made of frosted glass, neon light, and raw elements. The style:

- **Looks incredible in iPhone AR**, casting real-time colored light onto real surfaces
- **Keeps GPU load light**, since semi-transparent geometric forms render efficiently
- **Reads as premium**, not childish — important for the wellness positioning
- **Scales across factions**, since each element family (electric, magma, cosmic) has natural visual identity

**Asset strategy:** rather than full 3D AR assets (which run $100-250K for a respectable roster), Pod Monsters ships with a layered approach — 2D pixel art for Phase 0/1, with hero monsters upgrading to procedural 3D in Phase 2 post-revenue. See the companion document **`pod-monsters-asset-pipeline.md`** for the full asset strategy, tooling recommendations, and cost tiers.

---

## 7. Discovery — How Monsters Appear

### Biome scanning
AirPod cameras continuously read the environment. Different surroundings spawn different pools.
- Parks, trails, greenery → flora and agile types
- Gyms, weight rooms → Forge and beast types
- Quiet indoor spaces → Aether spirits and ethereal types
- Urban concrete → electric/urban variants
- Water nearby → aqua variants

### Lures (state-based attraction)
The body's current state changes what's drawn to it.
- **Cadence Lure** — 140+ steps/min draws rare Aero monsters
- **Exertion Lure** — sustained zone 2+ heart rate spawns bosses mid-session
- **Zen Lure** — verified parasympathetic state (HRV delta + head stillness) summons Aether spirits
- **Stillness Lure** — sub-threshold motion during rests pulls in shy monsters

### Sniff Mode (audio compass)
Monsters chirp from a direction in 3D space. Turn your head toward the sound until the audio centers and the camera locks on, then they materialize. Rewards presence, not screen-staring.

### Time, weather, and context triggers
- Sunrise walks → light variants
- Night walks → nocturnal variants
- Rain → water variants
- Cold → frost variants

### Geodes (cumulative-effort hatching)
Replaces Pokémon GO–style distance eggs with effort-based incubation.
- **Iron Geode** cracks at 500 cumulative strength reps
- **Void Geode** cracks at 100 cumulative meditation minutes
- **Wind Geode** cracks at a distance + cadence combination
- **Trinity Core** cracks only after a balanced 48-hour window: 10k steps + 30 min lifting + 15 min meditation

### Streak and milestone unlocks
- 30-day meditation streak → legendary "Master Mind" Aether spirit
- 100k lifetime steps → "Endurance Legend"
- First triathlon week → first hybrid

### Pokédex with locked silhouettes
A gallery of unlock conditions partially visible. Mystery pulls harder than abstract XP bars.

### Seasonal and event spawns
Limited-time monsters tied to real-world conditions (cherry blossom spring monsters, harvest moon variants). Live-ops content without app rebuilds.

---

## 8. Capture — The Gotcha Moment

### Gesture library
Detected by AirPod IR cameras in the peripheral field of view.
- **Pinch-and-flick** — fast, agile monsters. A swift flick of the wrist throws a capture orb.
- **Cradle / palm offering** — shy, ethereal spirits. Hold out a flat open palm; moving too fast spooks them.
- **Two-hand cradle** — soothing a skittish monster
- New gestures unlock as meta-progression.

### Pace matching (cardio)
The monster runs ahead in spatial audio. Increase cadence to "catch up," hold for 60 seconds, then pinch-and-flick.

### Shield Crack + Rest Capture (strength) — solving the "Barbell Problem"
Gestures *never* happen mid-lift. This is non-negotiable for safety.
- **During the set:** clean reps (tracked via AirPod IMU for tempo + Apple Watch for rep count) crack the monster's shield with audible cracks. Sloppy reps don't damage the shield.
- **During the rest:** once the weight is racked, the monster materializes spatially. The user has 60–90 seconds of hands-free rest to perform capture gestures. Gym downtime becomes the game.

### Tempo Whisper Coaching
The app whispers cadence: *"Lower for 3 seconds… pause… explode up."* Nailing the exact tempo damages the shield faster and draws out legendary monsters. The personal-trainer-in-your-ear mechanic.

### Warm-Up Mimicry
A nimble monster performs a stretch — a deep lunge, an arm circle, a thoracic rotation. The user mirrors it. IR cameras verify the geometry. Gamifies mobility work.

### Breath synchronization (meditation)
The spirit's breathing is audible in spatial audio. Sync your inhales and exhales to its rhythm to bond. Apple Watch + AirPod motion estimate breath cadence.

### Stillness Lock
Rare monsters appear briefly but only stay capturable if you hold completely still. Twitching scares them off. Fuses meditation discipline into capture.

### Distraction Resistance
A taming test for Aether spirits: the monster generates fake spatial audio illusions (a buzzing fly, a whisper). Jerk your head toward the noise and it flees. Ignore it and the bond completes.

---

## 9. Activity Pillars — Deep Dive

### 9a. Walking & Cardio: "The Hunt and the Chase"

**Discovery hooks**
- Biome scanning during walks
- Cadence Lure rewards faster paces with rarer spawns
- Migration monsters require walking through 2+ different biomes in one session
- Distance-evolved monsters level at km thresholds

**Capture mechanics**
- Pace matching at target heart rate zone
- Sniff Mode audio compass
- Pinch-and-flick at peak effort

**Stat impact**
- Cardio XP → speed and agility on the equipped buddy

---

### 9b. Strength Training: "The Trial of Might"

**Discovery hooks**
- Object recognition (looking at a rack or dumbbell draws Forge types)
- Exertion Lair (a few sets in, exertion summons bosses)
- PR bosses spawn only on tracked personal records

**Capture mechanics**
- Shield crack during sets, capture during rest
- Tempo Whisper Coaching damages shields faster
- Warm-Up Mimicry for mobility-based captures

**Stat impact**
- Strength XP → power and HP on the equipped buddy

**Critical design call:** capture mechanics never trigger during a working set. Safety first, always.

---

### 9c. Meditation & Recovery: "Luring the Ethereal"

**Discovery hooks**
- HRV delta gate — Aether spirits only spawn when Apple Watch verifies actual parasympathetic shift, not just sitting still
- 3+ minutes of head stillness + low HR
- Sunrise / sunset variants

**Capture mechanics**
- Breath synchronization (4-7-8 and other patterns)
- Stillness Lock
- Distraction Resistance

**Stat impact**
- Meditation XP → focus and special abilities; can grant in-app "focus mode" perks

---

### 9d. The Blue Mind Modality: "Fishing" (Destination Recovery)

*Focus: Environment, parasympathetic activation, and patience.*

Grounded in "Blue Mind" research — proximity to water measurably lowers cortisol — fishing is the app's premier **destination ritual**. It relies on geographic friction (GPS verification of real water) and gives users a genuine reason to seek out parks, rivers, coastlines, and urban fountains as restorative escapes. Marketed as the **fourth modality** ("Walk. Lift. Meditate. Cast.") but mechanically routed as an Aether sub-mode, fishing serves as the ultimate cross-pillar synthesis. The core three-pillar economy stays clean; water is the crucible where it all comes together.

**The Bait Economy (cross-pillar lock-in)**

Fishing cannot be spammed. Bait comes from the three core pillars, so users have to maintain their physical fitness routines to fund their weekend fishing trips. *You cannot skip leg day if you want to catch a Leviathan.*
- **Iron Hooks** (from Strength) — attract aggressive, heavy underwater beasts (Forge/Water hybrids)
- **Spinner Lures** (from Cardio) — attract fast, agile aqua-sprites (Kinetic/Water hybrids)
- **Mind Beads** (from Meditation) — attract deep, ethereal water spirits (pure Aether)
- **Master Lures** (Pod Monsters+ subscription) — small rare-pull rate boost

**The screen-down core loop**

1. **Arrive** — GPS + OpenStreetMap verifies proximity to an outdoor water source (ocean, river, lake, large pond, urban fountain, canal, harbor)
2. **Cast** — overhand wrist gesture, detected via Apple Watch IMU or AirPod IR
3. **Wait (the gameplay)** — AirPods verify head is *predominantly* oriented toward the water with low overall movement. Strict fixation isn't required — real water-gazing includes soft focus, occasional glances at the horizon, birds, the sky. Apple Watch monitors HRV.
4. **Bite** — spatial audio cue (a distant splash, line tension), accompanied by a sharp, distinct **Haptic Tug** on the Apple Watch. The physical sensation mimicking real line pull is the dopamine hit.
5. **Set the hook** — sharp reactive upward wrist flick
6. **Tai-Chi Reel** — the monster fights. The app whispers: *"Inhale… pull… exhale… hold."* User performs a smooth, sweeping arm motion synced to deep chest expansion (detected by AirPods/Watch IMU). Jerking the hand, spiking HR, or losing breath rhythm maxes virtual line tension and snaps the line. **You are literally using tactical breathing to land the fish.**
7. **Land** — final pinch-and-lift gesture. Monster materializes in spatial audio first, then in iPhone AR if the user pulls the phone out.

**Patience tiers (HRV-gated, not time-gated)**

Time alone is not enough. Scrolling on your phone won't catch legendaries — the nervous system has to actually drop into parasympathetic state.
- **5 min sustained presence** → common aqua sprites
- **15 min** → uncommon catches
- **30 min + verified HRV shift** → rare monsters
- **60 min + deep parasympathetic state** → local legendaries

**Water biomes & variations**

- **Oceans (saltwater)** — prestigious deep-sea catches, tide-gated spawns via free NOAA tide data, sunrise/sunset bonuses. Audible waves picked up by the Apple Watch mic actively *increase* reel difficulty — chaos makes it harder to stay calm, which is the entire point.
- **Rivers (flowing)** — flow rate affects spawns; real-world salmon/herring/shad migration seasons trigger limited spawns
- **Lakes / ponds (still water)** — the most meditative variant; highest chance for HRV-gated Aether legendaries
- **Urban water (fountains, canals, harbors)** — solves accessibility for city players. Smaller, mischievous sprites. Brooklyn Bridge Park, the Hudson, Newtown Creek, the Central Park Reservoir all become viable fishing holes.
- **The Weather Exception ("Puddle Fishing")** — if WeatherKit reports active rain at the user's location, their porch/yard temporarily becomes fishable for small **Tempest sprites**. Bad weather becomes a gameplay advantage rather than a blocker, while the strict geographic gate stays intact for everything legendary.

**Shore-Casting (cardio crossover)**

Real anglers walk the banks. The system checks two conditions: (1) walking cadence detected by accelerometer, and (2) GPS path running parallel to a mapped water boundary. The lure drags as you walk and attracts highly agile Aqua/Cardio hybrids (like river salmon variants). Stop walking and the lure sinks. Especially active during migration events.

**Catch and release (anti-hoarding)**

Release a catch to channel its essence as a flat XP boost into an existing buddy. Discourages hoarding, encourages collection variety, and rewards players who already have the monster they just caught.

**Local Legends and "The Big One"**

Specific real-world bodies of water host unique catches. The Hudson has its own legendary. Lake Tahoe has its own. Cape Cod has its own. Some are curated at launch; others are crowd-sourced over time as the playerbase grows. **The Big One** is a single ultra-rare legendary tied to a specific real location, catchable once per user per year — when someone lands one, it lights up the social feed for that region. Gives users a reason to travel.

**Equipment & beginner forgiveness**

Reel-snap thresholds scale with equipment tier. Beginners get very lenient gesture and breath tolerances so the first catches feel achievable. Advanced rods (unlocked via fishing XP) have tighter thresholds and access to rarer pools. Frustration kills the parasympathetic state — onboarding must feel like winning.

**Guardrails & tonal shift**

- **Zero notifications.** The app will *never* push users to "go fish." It must remain a sacred, user-initiated escape.
- **Diminishing returns** kick in heavily after 60 min in one session. Live your life; don't fish forever.
- **Daily Patience XP cap** and **per-location per-day catch limit** encourage variety over grinding one spot.
- **Safety messaging** — open water in lightning, slippery shorelines, ice. The app gently warns and suspends Tempest fishing during severe storms.
- **Audio design** — the high-energy narrator from cardio and strength is *absent* here. The audioscape is ambient water, spatial wind, and meditative silence. Possibly a different, slower voice for the rare prompts. The quiet is the feature.

**Stat impact**

- Fishing XP → routed to the equipped buddy's Aether stats (focus, special), with small crossover bonuses depending on bait used
- Bait consumption creates a healthy resource sink that justifies continued training across all pillars

---

## 10. XP and Progression

### Equipping a buddy
Before any session, pick the Pod Monster that comes with you. That session's XP routes to it. Forces meaningful pre-workout choice and a reason to log every session.

### XP routing
- Cardio XP → speed, agility
- Strength XP → power, HP
- Meditation XP → focus, special
- Fishing XP → Aether stats with bait-dependent crossover bonuses

### Bait as cross-pillar economy
Bait earned from cardio (Spinner Lures), strength (Iron Hooks), and meditation (Mind Beads) is consumed by fishing sessions. This creates a healthy resource sink that funds destination rituals without letting users abandon their physical routine. See Section 9d for detail.

### Synergy Evolutions
Monsters evolve when fed targeted XP they don't normally get. A base Forge Brawler fed only Strength XP becomes a slow Obsidian Titan. The same Brawler taken on runs and meditated with evolves into a balanced Monk-type. Visible evolution trees in the Pokédex create long-term goals.

### Habitat
Captured Pod Monsters live in a virtual habitat viewable through iPhone AR — your apartment, your backyard, wherever. Free users get a basic terrarium; premium habitats are a monetization lever (see Section 13).

---

## 11. Retention Design

### Deep Sleep — rest days as a reward
Skip a workout day or clock 8+ hours of quality sleep, and your buddies enter **Deep Sleep**. They wake with a **1.5x Well-Rested XP Multiplier** for the next session. Perfect sleep over multiple nights summons ultra-rare **Slumber Spirits**. Rest is part of the meta, not a punishment.

### Daily quests tied to the three pillars
Small, achievable, varied. Rotates the user through pillars naturally.

### Seasonal limited-time monsters
Cherry blossom spring monsters, harvest variants. Cheap live ops, strong return hook.

### Cosmetic shiny variants for streaks
Reward consistency with collectibles, not power. Avoids pay-to-win pressure.

### Posture XP drip
AirPod downward IR detects head tilt and carriage during the workday. Sustained good head carriage drips small amounts of "Discipline XP" to the equipped buddy. Light passive mechanic, not a major feature — and reframed as "head carriage" rather than full posture since the cameras can't see the spine.

### Spatial audio personality
Equipped buddies react in your ear — cheer during PR sets, whisper breathing cues, chirp encouragement on long walks. Makes the monster feel present.

---

## 12. The First 10 Minutes — Screen-less Onboarding

The hardest UX problem in the app: teaching users to play an invisible game. The iPhone screen exists only to initiate the magic.

### Step 1: The Drop-In (phone screen)
User creates an account and pairs HealthKit. Screen reads: *"Put in your AirPods. Lock your phone. Put it in your pocket. We won't need it for a while."* Screen goes black.

### Step 2: Spatial Audio Calibration (audio only)
> Narrator (calm, premium AI guide voice): "Welcome. Let's make sure I can track you. Turn your head toward the sound of the bell."

A chime rings in the spatial left ear. User turns left. "Perfect." Next chime is behind them. User turns around. "Got it."

### Step 3: Baseline Mimicry (sensor test)
> Narrator: "Take a deep breath and hold your arms out wide like a T."

AirPod cameras detect the pose. A warm hum fills the audio field as the pose validates. "Excellent. Your sensors are calibrated."

### Step 4: The First Catch (the walk)
> Narrator: "Start walking. Let's see what's out there."

Accelerometers verify cadence. After 30 seconds, a rustling triggers in the right ear.

> Narrator: "Stop. Hear that? Turn toward it."

User turns right. "There it is. Bring your hand up, pinch your fingers together… now flick forward to toss a snare."

User pinches and flicks. *Whoosh… zap… chime.*

> Narrator: "You caught it. Pull out your phone and let's see what it is."

### Step 5: The AR Reward (phone screen)
User unlocks their phone. AR camera opens to their real living room. A glowing Core sits on the floor. It cracks open, revealing their starter — Zephyr, Basalt, or Lumina.

---

## 13. Monetization

Pod Monsters never charges for health, never caps workouts with energy meters, and never sells pay-to-win XP. Four ethical revenue streams:

### Stream 1: Premium Cosmetics (the AR Habitat)
- Free: basic terrarium for displaying Pod Monsters
- Paid: premium habitats (Zen Garden, Obsidian Volcano, Mountain Shrine), Halo cosmetics, alternate colorways, premium voice packs (e.g., celebrity yoga guide narrators)

### Stream 2: Pod Monsters+ Subscription ($7.99/mo)
- Free: full workout tracking, capture mechanics, standard HealthKit integration
- Paid: deep analytics on HRV, Time Under Tension, sleep–monster growth correlations; studio-quality "Guided Audio Hunts" (Apple Fitness+ style sessions tied to the lore) that guarantee rare legendary encounters

### Stream 3: B2B Brand Partnerships (healthy geofencing)
- **Nike Run Club Raids:** Nike sponsors a weekend event; players hitting a 10k step threshold get an exclusive Nike-branded Aero Core egg. Nike pays for placement, users get free premium loot for exercising.
- **Studio partnerships:** Equinox, Barry's, and similar can sponsor in-app raids and exclusive monsters tied to attendance.

### Stream 4: Phygital Merch (NFC)
- Pod Monsters–branded gym apparel and water bottles with embedded NFC chips. Tap your phone to your real-life bottle before a workout for a 60-minute Hydration Bonus XP multiplier. Tap a branded wristband for a workout-specific buff.

### Explicitly cut from monetization
- **Nutrition scanning ("Diet Vision").** Dropped for two reasons. First, food-recognition gameplay creates disordered-eating risks the app shouldn't take on. Second, it's adjacent to existing pet-food-scanner work (Kiba) and would split focus. If brand partners want food tie-ins, gate them behind logged meals in a partner app, not visual judgment.

---

## 14. Hardware-Honest Scope — What to Cut

- **Facial expression tracking during meditation** — AirPod cams face outward. Can't see your face.
- **Eye/gaze tracking** — same reason. Use head stillness and reframe as "unwavering focus."
- **Full body posture scoring** — cameras can't see your spine. Use head carriage only.
- **Real-time lift form scoring via AirPods alone** — physically impossible. Use IMU for tempo and Apple Watch for rep count. Scope down expectations and keep the shield-crack mechanic honest.
- **AR monster overlays beside your weights during lifts** — phone is on the floor or in a locker. The hands-free pitch is the moat.
- **Co-op synchronized capture with timed gesture flicks** — sub-second cross-device gesture sync is a hard engineering problem. Mark v2+, not core loop.

---

## 15. Biome Detection Implementation

Every spawn condition in the app relies on knowing where the user is and what's around them. This section maps each biome type to its data sources, today's availability, and known edge cases. Most of this is buildable in Phase 0 without waiting for AP Pro 4.

### Water (oceans, rivers, lakes, urban water)

**Primary source: OpenStreetMap via Overpass API**
- Free, comprehensive, no auth required
- Relevant tags: `natural=water`, `natural=coastline`, `waterway=river|stream|canal|brook`, `amenity=fountain`, `harbour=yes`
- Query strategy: on workout start, fetch all water features within 500m of GPS coords; cache for the session
- Fallback: Apple MapKit water polygons (less tag granularity but better coverage in some regions)

**Tide data (oceans only): NOAA CO-OPS API**
- Free, public, US waters
- Endpoints for predictions and live water levels
- Worldwide tide gating in Phase 2+; evaluate StormGlass or WorldTides as commercial fallback

**Weather Exception (Puddle Fishing): WeatherKit**
- Native Apple API, no auth
- Trigger Tempest mode at moderate+ active precipitation

**Edge cases**
- GPS in dense urban areas can drift 20–50m; use a confidence radius rather than a point check
- Indoor pools and fish tanks: explicitly filtered out via OSM tags (`leisure=swimming_pool` indoors, no `harbour`)
- Frozen lakes in winter: keep accessible, label as ice variants (Phase 2)

### Green space (parks, trails, forests)

**Primary source: OpenStreetMap**
- Tags: `leisure=park|garden|nature_reserve`, `landuse=forest|grass|meadow`, `natural=wood`
- Same Overpass query pattern as water

**Edge case: tree-lined streets**
- Treat as "light green" rather than full park. Use OSM `natural=tree_row` or count individual tree nodes within radius.
- Brooklyn brownstone blocks are denser with trees than open-fields suburbs — design should reward urban greenery, not penalize it.

### Urban (concrete, streets, city)

**Primary source: default fallback**
- If no water, green, or gym detected → urban
- Refine using OSM `highway=primary|secondary|residential` density and `building=*` density for "deep urban" vs "suburban" sub-types

### Gym (strength training environment)

This is the hardest biome to detect reliably. Three layered approaches:

**Layer 1: User-tagged location (works today)**
- One-time setup: "Tag your gym" pins a GPS point or home gym address
- Future visits auto-trigger Forge spawns. Cleanest, most reliable signal.

**Layer 2: OSM POI detection**
- Tags: `leisure=fitness_centre`, `sport=fitness`, `amenity=gym`
- Good for chains (Equinox, Planet Fitness, LA Fitness). Spotty for boutique studios and CrossFit gyms.

**Layer 3: HealthKit workout type (works today)**
- When user starts a "Traditional Strength Training" or "Functional Strength Training" workout in HealthKit/Apple Watch, treat the session as a gym session regardless of location
- This is the cleanest user-declared signal

**Phase 1+ (AP Pro 4)**
- IR camera object recognition for racks, dumbbells, kettlebells, machines
- Layered on top of location-based detection, not replacing it

### Quiet indoor (meditation)

**Signals (combined):**
- GPS at logged home address (or any logged "meditation spot")
- Low ambient noise via Apple Watch or AirPod mic (sustained sub-threshold dB)
- Low movement via accelerometer
- HealthKit "Mindful Minutes" session active

Any 2 of 4 = quiet indoor confirmed. Don't require all four — that's brittle.

### Weather modifiers

**Primary source: WeatherKit (Apple)**
- Native, free, no auth
- Current conditions, precipitation type/intensity, humidity, temperature, cloud cover, UV index
- Refresh on session start and every 15 min during long sessions

**Modifiers we use:**
- Active rain → water variants spawn anywhere, Puddle Fishing unlocks
- High humidity → mist variants
- Temperature below 5°C → frost variants
- Sustained cloud cover → shadow variants (rare)

### Time-based modifiers

**Primary source: Core Location + native sunrise/sunset calculation**
- Compute sunrise/sunset for user's coords + date locally (no API needed)
- Define dawn (sunrise ± 30 min), day, dusk (sunset ± 30 min), night
- Lunar phase computable locally for Lunar variants

**Modifiers:**
- Dawn → Sunrise variants
- Dusk → Twilight variants
- Night → Nocturnal variants
- Full moon → Lunar variants

### Migration & seasonal data (Phase 2+)

For real-world ecological events that affect spawns:
- Salmon runs: NOAA Fisheries data, state fish & wildlife agencies
- Bird migrations: eBird (Cornell) data
- Cherry blossom bloom: National Park Service, regional tourism boards

This is a curated content layer, not real-time auto-detection. Designers ship event windows monthly.

### Battery & privacy considerations

**Battery**
- Significant Location Change API instead of continuous GPS when possible
- Geofence the user's logged home and gym for cheap detection
- Cache OSM query results aggressively — biomes don't move
- Refresh WeatherKit every 15 min, not every 30 seconds

**Privacy**
- All biome detection runs device-side after the initial OSM query
- OSM Overpass queries send coords but not user identity
- Explicit consent for "Always" vs "While Using App" location access
- Default to "While Using App" — biome only updates during active sessions
- HealthKit data never leaves device without explicit cloud-sync opt-in

### Offline & failure modes

- Cache the last successful biome detection for 24 hours
- If WeatherKit fails, treat as clear conditions
- If OSM fails, fall back to MapKit
- If all sources fail, default to "neutral" biome with common spawns — never block the user from playing

---

## 16. Build Phasing

### Phase 0 — MVP Prototyping (today, May 2026)
The full loop is testable now on existing hardware. Four hacks:

1. **Spatial audio + head tracking — works today.** Apple's `CMHeadphoneMotionManager` API on current AirPods Pro 2 supports the Sniff Mode audio compass and head-tracking mechanics. No new hardware needed.
2. **Gesture capture via Apple Watch — works today.** Apple Watch's AssistiveTouch accessibility API uses wrist accelerometers and optical sensors to detect pinch and clench. Pair the Watch with the app to act as the capture trigger — simulates what AirPods Pro 4 cameras will eventually do visually.
3. **Strength form prototype via TrueDepth — works today.** For gym mechanics, lean the iPhone against a water bottle and use the front-facing TrueDepth camera or the `Vision` framework to track squat depth and tempo, piping audio feedback to current AirPods.
4. **Investor pitch via Apple Vision Pro.** VisionOS already has downward IR cameras, skeletal tracking, and native pinch-and-flick recognition. Build the Habitat and gesture logic in VisionOS to demo the final UX. Pitch line: *"This exact tech is shrinking into earbuds this fall."*

Build the economy, monster taxonomy, geode loop, and retention layer here. Validate retention before betting on AP Pro 4.

**For asset pipeline, tooling choices, and Phase 0 cost tiers, see the companion document `pod-monsters-asset-pipeline.md`.** Short version: $263 in software gets you to a polished DIY demo; $500-1,000 with commissioned hero starters gets you to an investor pitch.

### Phase 1 — AP Pro 4 launch (late 2026)
Layer in the heads-up upgrades.
- Spatial audio Sniff Mode goes native
- Real gesture-throw capture via AirPod IR
- Biome scanning via IR cams
- Head stillness as a first-class signal
- Head carriage tracking for Posture XP drip
- Fishing v1: GPS water gate, cast/wait/bite/reel loop, Apple Watch haptic tug, basic bait economy

### Phase 2 — Depth
- iPhone-assisted form scoring for shield-crack mechanic
- Seasonal events and live ops
- Social features (trades, co-op walks)
- Hybrid evolution trees
- First B2B brand partnership pilots
- Fishing v2: Local Legends, The Big One, NOAA tide integration, Shore-Casting, Puddle Fishing

### Phase 3 — Multiplayer + Vision Pro
- Group raids and co-op captures (technically feasible once core loop is proven)
- Vision Pro habitat experience for power users
- NFC phygital merch line

---

## 17. Open Questions

- **Visual identity beyond Bioluminescent Geometry** — color palette, logo, UI typography
- **Privacy story** — IR cameras on earbuds will face scrutiny; data handling messaging matters
- **Coach layer depth** — how prescriptive should Tempo Whisper Coaching get? Programmed routines or freeform?
- **Accessibility** — what does the loop look like for users who can't walk long distances, can't lift heavy, or can't meditate in stillness? Wheelchair cadence detection? Seated meditation variants? This needs explicit design, not afterthought.
- **Water-access equity** — fishing relies on real water proximity. Coastal and lakeside users are fine; Phoenix, Vegas, Salt Lake, and other arid-region users may have no mapped water within reasonable distance. Urban fountains and Puddle Fishing help, but the gap is real. Options to evaluate: lower thresholds for what counts as "fishable" in water-scarce regions, travel-event mechanics that reward planned trips, or partner activations at indoor aquariums.
- **HealthKit-only fallback** — can the app deliver value to users without AP Pro 4? Phase 0 suggests yes, but the loop needs explicit gating.
- **Voice pack roster** — who's the launch narrator? Identifying the right voice talent matters for the premium feel.

---
