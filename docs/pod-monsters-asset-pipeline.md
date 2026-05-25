# Pod Monsters — Asset Pipeline & Tooling

Companion document to the main Pod Monsters concept doc. Covers the asset strategy, implementation path for 2D-in-AR, recommended tools, and realistic cost tiers for Phase 0 prototyping.

---

## 1. Asset Strategy Summary

Full 3D AR assets are the steepest cost ramp in the project (estimated $100-250K for a respectable v1 roster). To avoid that trap while preserving aesthetic ambition, Pod Monsters ships with a layered asset strategy:

**Phase 0 (today, May 2026):** No in-AR monsters at all. The Hunt loop reveals monsters purely through spatial audio and gesture. Visible reveal happens in the iPhone Habitat as 2D pixel/illustrated art after capture. Aligns with the Golden Rule — the Habitat is iPhone-based, never specified as AR.

**Phase 1 (late 2026, AP Pro 4 launch):** 2D-in-AR via ARKit + SpriteKit. Monsters appear as 2D sprites anchored in 3D space, billboarded to face the camera. Maintains aesthetic consistency with the 2D companion world.

**Phase 2 (post-revenue):** Hero monsters (3 starters + ~10 legendaries) upgraded to procedural 3D geometry using a Monument Valley-style aesthetic. Common monsters stay 2D billboards. Most users see their favorites in full 3D.

This collapses the asset budget from six figures to under $1,000 for a presentable Phase 0 demo.

---

## 2. The 2D-in-AR Implementation Path

The good news: Apple has a native, documented framework for exactly this.

### ARSKView (ARKit + SpriteKit)
- 2D SpriteKit content placed into 3D AR space
- Billboarding: sprites automatically face the camera as the user moves around them
- Particle effects via SpriteKit emitters (perfect for bioluminescent glow)
- Well-trodden — tutorials and sample code going back to 2018
- Works on every ARKit-capable iPhone

### Pipeline (per monster)
1. Generate sprite in PixelLab (32x32 or 64x64 base resolution)
2. Refine in Aseprite (cleanup, palette match, animation frames)
3. Import as `SKSpriteNode` in Xcode
4. Anchor in AR space via ARKit (`ARSKView` or `RealityView` with SpriteKit overlay)
5. Add `SKEmitterNode` for glow/particles
6. Set billboard constraint for camera-facing behavior

### RealityKit 4 alternative
- Apple's newer framework, supports SpriteKit overlays natively
- Better rendering, more spatial audio integration
- Slightly steeper learning curve
- Recommended for Phase 1+, when porting to Vision Pro becomes relevant

---

## 3. Tech Stack Decision

Pod Monsters' core mechanics (AirPods motion APIs, HealthKit, ARKit, SpriteKit, WeatherKit) are all native-first Apple frameworks. Bridging them through React Native adds engineering complexity without product benefit.

### Recommendation: Full Swift Native
- Single codebase, native performance, full framework access
- Steeper learning curve coming from Expo/React Native, but the curve is worth it
- Cannot reasonably ship Pod Monsters as a cross-platform app — the hardware story is iOS-only by design

### Alternatives (not recommended for Pod Monsters specifically)
- **Bare React Native + native modules:** possible but requires wrapping ARKit, SpriteKit, CMHeadphoneMotionManager, HealthKit individually. Most of your time will be on bridge code, not product.
- **Swift native for AR/AirPods + RN for everything else:** dual codebase complexity. Only justified if shared logic with Kiba is significant, which it isn't.

The Swift native call is the bigger architectural decision than the asset pipeline. Once made, it shapes the next year of the build.

---

## 4. Recommended Tools

### Pixel art generation
- **PixelLab.ai** ($12/month) — purpose-built for game pixel art. Sprite generation, one-click animation, skeleton-based animation, 4/8-directional rotation, tilesets, environments, UI elements. Understands grid sizes (16x16, 32x32, 64x64). Daily driver.
- **Sprite AI** (sprite-ai.art, free tier + paid) — fast generation with built-in editor. Good for rapid variation pulls.
- **PixelGlow** (pay-per-image, no subscription) — FLUX-based, good for concept exploration before committing to designs.

### Pixel art refinement
- **Aseprite** ($20 one-time) — industry-standard pixel editor. Animation timeline, onion skinning, palette management, tilemaps, Lua scripting. Lifetime license.
- **Piskel** (free) — browser-based pixel editor. Acceptable for absolute zero-budget start, but Aseprite is worth the $20.

### AR mockup (no code required)
- **Reality Composer Pro** (free with Xcode) — Apple's drag-and-drop AR scene editor. Mock the Habitat layout without writing Swift. Exports to USDZ. Underrated for non-coder pitching.

### Native development
- **Xcode** (free, Mac required) — Apple's IDE
- **Swift Playgrounds** (free) — lightweight prototyping environment
- **Apple Developer Program** ($99/year) — required for App Store distribution, WeatherKit access, TestFlight

### APIs & services
- **OpenStreetMap Overpass API** (free, no auth) — biome detection
- **WeatherKit** (free with Apple Dev) — weather and precipitation data
- **NOAA Tide API** (free, public) — US tide data for ocean fishing
- **HealthKit** (free, native) — workout, HR, HRV, sleep data
- **CloudKit** (free with Apple Dev at reasonable scale) — backend storage

---

## 5. Cost Tiers for Phase 0

### Baseline software cost
| Item | Cost | Frequency |
|---|---|---|
| PixelLab.ai | $12 | Monthly |
| Aseprite | $20 | One-time |
| Apple Developer Program | $99 | Annual |
| **Total year one** | **$263** | |
| **Total ongoing** | **$243/yr** | |

### Tier 1 — Solo / DIY ($263 total)
- Generate all assets via PixelLab, refine in Aseprite yourself
- ~3 starters + 15-20 common monsters + tilesets for one hub town
- 2-3 weekends of art direction time
- Enough for a polished Phase 0 demo

### Tier 1.5 — Solo + commissioned heroes ($500-1,000 total)
- Tier 1 plus $300-600 on Fiverr/Upwork for cleaner versions of the three starters
- Hero monsters get the human polish; commons stay AI-generated
- **Probably the sweet spot for an investor pitch demo**

### Tier 2 — Hybrid freelance ($1,500-3,500 total)
- DIY most assets
- Commission 3-5 hero sprites at $75-200 each from freelance pixel artists
- Three starters + 1-2 legendaries get the human treatment

### Tier 3 — Full freelance pipeline ($8,000-15,000 total)
- Hire one pixel artist on contract for 2-3 months at $3-5K/month
- ~50 monsters fully designed and animated
- Only justified after early traction or funding

---

## 6. What Not to Spend Money on Yet

- 3D modeling tools or 3D artists (deferred to Phase 2)
- Unity Pro, Unreal, or other game engine licenses (Apple native stack is free)
- Sound design (use SF Symbols sounds + Freesound.org for v1)
- Backend infrastructure beyond CloudKit
- Custom font licensing (SF Pro is free and premium)
- Marketing or branding services
- Trademark filing (premature until product validates)
- LLC formation (premature for prototype phase)

The fitness apps that fail run out of money before finding product-market fit, not because their art wasn't polished enough.

---

## 7. Suggested Month-One Workflow

A realistic plan to go from concept doc to demo video in four weeks, working part-time.

### Week 1: Visual identity
- Subscribe to PixelLab, install Aseprite
- Generate 50+ monster variations across the three factions
- Refine the three starters (Zephyr, Basalt, Lumina) in Aseprite
- Establish the Bioluminescent Geometry pixel aesthetic — palette, glow style, particle direction

### Week 2: World assets
- Generate hub town tileset in PixelLab
- Build one explorable scene in the 2D companion world
- Mock 5-10 common monsters for the Habitat

### Week 3: AR mockup
- Install Xcode, learn Reality Composer Pro basics
- Build the Habitat layout in Reality Composer Pro
- Place 2D sprites as anchors
- Screen-record walking around the Habitat on iPhone

### Week 4: Pitch deck
- Stitch assets + 2D world scene + AR Habitat recording into a 90-second video
- Write a one-pager summarizing the concept (or link to the main concept doc)
- Optional: post to indie dev forums for early feedback

This is the *vision deck*, not the app. Month two starts the actual Swift work, by which point you'll know if the concept resonates with anyone besides you.

---

## 8. Workflow Notes

### The AI-first pipeline
The modern indie workflow: generate 20 variations with AI, pick the best 1-3, refine in Aseprite. AI handles the first draft, human handles the final polish. For Pod Monsters, the starters and legendaries get manual artist passes; everything else uses the AI-first pipeline.

### Aseprite is non-negotiable for polish
PixelLab outputs are good but not always grid-aligned, palette-consistent, or animation-ready. Aseprite is where they become usable. Budget time to learn it — it's the most-used tool in indie pixel art for a reason.

### Time cost is real
A weekend of PixelLab + Aseprite work is realistic if you have prior pixel art experience. If you don't, budget 2-3 weekends for the learning curve. The skills compound across future projects.

### License hygiene
PixelLab allows commercial use of generated assets but prohibits training new models with them. Standard terms. Save the license confirmation in your project folder for due diligence purposes if you ever raise.

---

## 9. Decision Log

| Decision | Rationale |
|---|---|
| Defer all in-AR 3D monsters to Phase 2 | Asset cost vs. validated demand. The Hunt loop doesn't need visible AR monsters. |
| Use 2D pixel art across Habitat + companion world | Aesthetic consistency, cost efficiency, GPU efficiency. |
| Ship Phase 1 in-AR monsters as 2D billboards via ARSKView | Native Apple framework, well-documented, fraction of 3D cost. |
| Full Swift native stack | Native-first Apple frameworks. React Native bridge adds complexity without benefit. |
| PixelLab + Aseprite as the asset pipeline | Best fit for game-ready sprites with manual polish. |
| Tier 1.5 budget ($500-1,000) for Phase 0 demo | Validates concept before larger spend. |

---
