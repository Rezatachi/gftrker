# Nourish Session Notes

Last updated: 2026-06-20

## Project

- App: `Nourish`
- Repo: `/Users/abrahambelayneh/GirlfriendCalorieTracker`
- Xcode project: `/Users/abrahambelayneh/GirlfriendCalorieTracker/Nourish.xcodeproj`
- Platform target priority: iOS 26
- Git baseline commit: `1166dc0 Initial Nourish MVP baseline`
- Current branch: `main`

## Product Direction

Nourish is now a chat-first calorie and protein tracker. Camera-first meal logging has been deprioritized.

Core user flow:

1. Open app.
2. See today calories and protein.
3. Type food in natural language.
4. Parser extracts foods and estimated nutrition.
5. User reviews/edits grams, calories, protein.
6. User confirms before anything is saved.

Important product rules:

- Never auto-save AI/parser results.
- Always show review first.
- Estimates must be editable.
- Speak to her as the user, not as a message from the partner.
- Keep UI premium, soft, polished, and efficient.

## Design Direction

Current visual direction:

- Cream, soft blue, pink, and warm pastel system.
- Previously tested matcha/yellow, but user disliked the “poo and pee” effect.
- Current palette is closer to a soft premium wellness app.
- Use native iOS tab bar/liquid glass where possible.
- Avoid double-layer custom tab bars.
- Hydration card was removed from Today; hourly notifications cover water reminders.

UI principles:

- Rounded cards.
- Soft shadows.
- Calm gradients.
- Large chat card at top of Today.
- SF fonts, not Playfair Display.
- No default-looking boring form/list screens unless heavily customized.

## Implemented Major Features

### Chat-Based Logging

- `TodayView` has chat card above calorie/protein card.
- Chat card is large and minimal.
- Preview chat bubble is low-opacity placeholder.
- Fullscreen chat logging exists in:
  - `Nourish/Views/Meals/FoodChatLogView.swift`
- Chat UI includes:
  - User/assistant bubbles.
  - Suggested chips.
  - Bottom input bar.
  - Parsed food review card.
  - Grams range slider.
  - Add to Today confirmation.

### Nutrition Tracking

- Calories and protein are shown on Today.
- Today card uses two separate progress rings:
  - Calories.
  - Protein.
- Meal/manual logging still exists.
- Food items persist through SwiftData.

### Hydration

- Owala/hydration card removed from Today.
- Water notifications added.
- Notifications are intended to remind her hourly to drink water.
- Important iOS behavior: scheduled local notifications can fire after app exit, but not all behavior is guaranteed if the user force-kills the app or disables notifications.

### Profile / Settings

Profile has parser settings:

- Prefer local parsing.
- Local AI drafts.
- Ollama URL.
- Ollama model.
- USDA catalog search.
- USDA API key.
- AI fallback.

Relevant file:

- `Nourish/Views/Profile/ProfileGoalsView.swift`

## Current Food Parsing Architecture

The app now has a multi-strategy parser pipeline.

Primary protocol:

- `Nourish/Services/FoodParsingService.swift`

Router:

- `Nourish/Services/FoodParsingRouter.swift`

Strategies:

- `RuleBasedFoodParsingService`
- `LocalFoodDatabaseParsingService`
- `OllamaFoodParsingService`
- `SmallModelFoodParsingService`
- `USDAFoodCatalogService`
- `OpenAIFoodParsingService`

Current intended order:

1. Try local/rule database for high-confidence matches.
2. If enabled, use Ollama to extract food entities.
3. If enabled, search USDA FoodData Central for broad catalog matches.
4. Optional OpenAI fallback only if explicitly enabled.

Important architecture principle:

- LLM/Ollama should extract foods and quantities.
- Nutrition should come from reliable nutrition data where possible.
- User corrections should be saved locally and used to improve future parsing.

## Ollama Integration

File:

- `Nourish/Services/OllamaFoodParsingService.swift`

Current status:

- Ollama service exists.
- It calls local Ollama `/api/generate`.
- It requests strict JSON.
- It extracts food entities.
- It maps entities back to the local food database where possible.
- It does not directly trust the LLM for calories/macros.

Known local setup:

- User has Ollama installed on Mac.
- Installed model verified:
  - `llama3.2:3b`
- Local test with Chinese text worked directly against Ollama:
  - Input: `我吃了一碗米饭，两个鸡蛋，还有一杯酸奶`
  - Ollama returned Rice, Eggs, Yogurt JSON.

Simulator vs device:

- iOS Simulator can use `http://localhost:11434`.
- Physical iPhone cannot use `localhost`; it points to the iPhone itself.
- For device testing, expose Ollama on the Mac LAN address and set Profile URL like:
  - `http://192.168.x.x:11434`
- May require configuring Ollama host binding, for example `0.0.0.0:11434`, but verify before relying on this.

## USDA FoodData Central Integration

File:

- `Nourish/Services/USDAFoodCatalogService.swift`

Current status:

- Optional USDA search service exists.
- It does not hardcode an API key.
- API key is entered in Profile settings.
- It performs remote USDA search and maps best result into `ParsedFoodItem`.
- It extracts:
  - Calories.
  - Protein.
  - Carbs.
  - Fat.
- It estimates grams using parsed quantity and serving fallbacks.

Current limitation:

- It currently picks a best match automatically.
- Better UX would show 3-5 USDA candidates and let her choose before saving.

Important note:

- A TrieMap over all USDA foods is not useful unless we download/index a large catalog locally.
- Current better MVP path is remote USDA search plus local correction memory.

## Local Food Database

File:

- `Nourish/Data/LocalFoodDatabase.swift`

This has been expanded with:

- Greek yogurt.
- Yogurt.
- Mochi.
- Protein bars.
- Chicken.
- Salmon.
- Eggs.
- Rice.
- Pasta.
- Avocado.
- Banana.
- Apple.
- Oatmeal.
- Granola.
- Peanut butter.
- Salad.
- Sweet potato.
- Tofu.
- Steak.
- Turkey.
- Cottage cheese.
- Protein shake.
- Milk.
- Almond milk.
- Matcha.
- Coffee.
- Broccoli.
- Toast.
- Oikos protein yogurt.
- Siggi's skyr.
- Yogurt bowl.
- Built bar.
- Barebells.
- Protein chips.
- Overnight oats.
- Smoothie/acai bowl.
- Protein pancakes.
- Egg bites.
- Avocado toast.
- Oat milk.
- Iced latte.
- Oat milk latte.
- Vanilla latte.
- Chicken rice bowl.
- Burrito bowl.
- Poke bowl.
- Sushi roll.
- Caesar salad.
- Turkey sandwich.
- Burger.
- Fries.
- Pad Thai.

Chinese aliases were added for many basic foods.

## Quantity Parser

File:

- `Nourish/Utilities/QuantityParser.swift`

Current status:

- Supports English number words.
- Supports some Chinese numbers and quantity units.
- Supports Chinese separators/punctuation.
- Parses phrases like:
  - `a cup of yogurt`
  - `3 mochi`
  - `two eggs`
  - `一碗米饭`
  - `两个鸡蛋`
  - `一杯酸奶`

Known limitation:

- Complex restaurant meals and ambiguous dishes still need better catalog lookup and user correction memory.

## Data Model Changes

Files:

- `Nourish/Models/Meal.swift`
- `Nourish/Models/FoodItem.swift`

Added AppSettings fields:

- `localLLMEnabled`
- `ollamaBaseURL`
- `ollamaModel`
- `usdaSearchEnabled`
- `usdaAPIKey`

Added food log source:

- `.localLLM = "Local AI draft"`
- `.usda = "USDA match"`

## Build Command

Always run this before saying implementation work is done:

```bash
/bin/zsh -lc "DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild -project /Users/abrahambelayneh/GirlfriendCalorieTracker/Nourish.xcodeproj -scheme Nourish -configuration Debug -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build"
```

Last known result after USDA/Ollama/Pad Thai/Chinese parsing work:

- `BUILD SUCCEEDED`

## Git Status At Time Of Notes

There are uncommitted changes after the baseline commit.

Modified:

- `Nourish.xcodeproj/project.pbxproj`
- `Nourish/Data/LocalFoodDatabase.swift`
- `Nourish/Models/FoodItem.swift`
- `Nourish/Models/Meal.swift`
- `Nourish/Services/FoodParsingRouter.swift`
- `Nourish/Utilities/QuantityParser.swift`
- `Nourish/Views/Meals/FoodChatLogView.swift`
- `Nourish/Views/Profile/ProfileGoalsView.swift`

Untracked:

- `Nourish/Services/OllamaFoodParsingService.swift`
- `Nourish/Services/USDAFoodCatalogService.swift`
- `session.md`

Do not commit unless the user asks.

## User's Latest Architecture Idea

User proposed:

> Run a USDA Food API that generates all possible foods. Ollama extracts food phrase. We have an immense search catalog that is not saved locally. Find the best match, perhaps using a TrieMap. User confirms and we save correction.

Recommended interpretation:

- Do not download/store the entire USDA catalog locally for MVP.
- Do not build TrieMap over remote data unless we introduce a local indexed cache.
- Use Ollama for multilingual/entity extraction.
- Use USDA search API for catalog lookup.
- Show multiple candidate matches.
- Save confirmed corrections locally.
- Use corrections before Ollama/USDA next time.

Recommended next implementation:

1. Add `FoodCorrection` SwiftData model.
2. Add `FoodCorrectionStore` or service.
3. Before remote search, check corrections by normalized phrase.
4. After user confirms a parsed USDA result, save correction:
   - original phrase.
   - chosen canonical food name.
   - USDA FDC id if available.
   - typical grams.
   - calories/protein/carbs/fat per 100g or selected serving.
   - lastUsedAt.
   - useCount.
5. Modify USDA service to return multiple candidates.
6. Modify review UI to allow candidate switching.
7. Add parser debug/source label in review card:
   - Local.
   - Ollama extracted.
   - USDA matched.
   - Needs review.

## Suggested Near-Term Roadmap

### Step 1: Correction Memory

This is the highest-leverage next step.

Add local SwiftData correction memory so the app learns her repeated foods without bloating the database.

### Step 2: USDA Candidate Review

Instead of silently choosing one USDA result, show candidate choices in the review card.

### Step 3: Parser Observability

Add friendly debug labels or logs:

- Which parser ran.
- Whether Ollama failed.
- Whether USDA returned no match.
- Confidence score.

This will make debugging “Pad Thai did not work” and Chinese input much faster.

### Step 4: Device Ollama Setup

If testing on physical iPhone:

- Configure Mac Ollama to bind on LAN.
- Set Profile Ollama URL to Mac LAN IP.
- Confirm iPhone can reach it.

### Step 5: Commit

Once the current pipeline builds and works in-app, commit the parser architecture as a safe restore point.

## Key Open Questions

- Should USDA search be enabled by default once an API key is present?
- Should Ollama run before USDA or only extract phrases for USDA?
- Should user corrections be local-only or eventually shared via Supabase?
- Should Supabase store only corrections and favorites, not full logs?

Recommended answer for now:

- Local SwiftData logs and corrections first.
- USDA optional with API key.
- Ollama optional for extraction.
- Supabase later only if cross-device sync or shared correction memory becomes necessary.

## June 23, 2026: Provider-Specific Serving Ranges

Completed the next serving-estimate accuracy pass.

Changes:

- USDA now decodes branded `servingSize`, `servingSizeUnit`, and
  `householdServingFullText`.
- USDA FNDDS/Foundation results now use `foodMeasures` gram weights instead of
  generic cup/bowl/plate assumptions.
- Equivalent USDA household measures across candidates contribute neighboring
  gram weights to the suggested range.
- Open Food Facts now decodes serving size, serving quantity/unit, and package
  quantity/unit.
- Open Food Facts accepts numeric fields encoded as either JSON numbers or
  strings and retries bounded `429`/`5xx` failures.
- Nutritionix ranges now use serving units and nearby `alt_measures` instead of
  a fixed `0.82x...1.25x` range.
- Quantity parsing now recognizes package/count units including bottle, can,
  jar, packet, bag, fillet, roll, cookie, cracker, shot, glass, and portion.
- Missing provider portions use a low-confidence unit fallback. Provider
  metadata always takes priority when available.

Verified live:

- USDA `1/4 cup granola` -> `28g [23-32g]`, `130 cal`.
- Open Food Facts `2 granola bars` -> `42g [34-50g]`, `190 cal`.
- Full unsigned iOS build: `BUILD SUCCEEDED`.

Recommended next matcher step:

- Preserve the top 3 provider candidates per phrase and expose candidate
  switching in the review flow.
- Record accepted/rejected candidate IDs in correction memory so ranking can
  learn from actual choices rather than only corrected nutrition values.

## June 23, 2026: Personal-Team Signing Configuration

Debug and Release now use different correction-memory capabilities:

- Debug has no iCloud entitlement, so it can be signed by a free Apple personal
  development team and installed on a device.
- Debug correction memory is disabled and does not save corrections locally.
- Release retains `Nourish/Nourish.entitlements` and uses the CloudKit-backed
  correction store for paid Apple Developer Program/TestFlight builds.
- TestFlight still requires a paid Apple Developer Program team with the
  `iCloud.com.abrahambelayneh.nourish` container enabled.
- Xcode automatic provisioning generated the personal-team Debug profile and a
  signed generic iOS Debug build completed successfully.
- The signed Debug app contains only `application-identifier`,
  `com.apple.developer.team-identifier`, and `get-task-allow`; it contains no
  iCloud entitlement.
- An unsigned Release build also completed successfully.

## June 24, 2026: Candidate Review and Matcher Evaluation

Completed roadmap items 1-4:

- A food phrase now produces one selected item with up to three candidates,
  rather than emitting alternatives as additional eaten foods.
- Local matches, USDA foods, Open Food Facts products, and Nutritionix results
  carry stable candidate/provider IDs.
- USDA and Open Food Facts return their top three ranked candidates.
- The review card has an alternate-match menu. Selecting a candidate updates
  name, serving, gram range, calories, macros, confidence, source, and provider
  metadata together.
- CloudKit correction records persist the accepted candidate ID, provider ID,
  provider data type, brand, and rejected candidate IDs.
- Correction-memory retrieval selects one best saved correction instead of
  emitting every historical correction as a food.
- Fixed `half avocado` normalization and unsegmented Chinese phrase matching.
- Added `Tools/MatcherEvaluation` with 50 representative chat messages and
  metrics for extraction accuracy, food-match accuracy, and gram MAPE.
- Added `docs/qa/food-matcher-regression.md` for physical-device regression.

Evaluation:

- Baseline: 79.2% extraction, 88.2% food matching, 1.6% gram MAPE.
- Current: 100% extraction, 100% food matching, 0.8% gram MAPE.
- Live USDA candidate count: 3 with stable FDC IDs.
- Live Open Food Facts candidate count: 3 with stable barcodes.
