# Personalized Efficiency Roadmap

## Purpose

Make Nourish feel like a fast, premium, personalized nutrition ritual for the user. The next phase should reduce taps, make daily tracking feel more emotionally specific, and lay the groundwork for subtle horse, ceramic, and custom animation motifs without making the app childish or visually noisy.

## Product Principles

- Speak directly to the user: use "you" and "your", not third-person language.
- Prioritize speed: common actions should be one tap or two taps.
- Keep AI/photo features assistive: suggestions never auto-log.
- Use motifs subtly: horses, ceramics, and premium objects should feel like tasteful details, not decoration overload.
- Make progress feel gentle: consistency over perfection.
- Design for future animation: build reusable state changes and components that can later receive custom motion.

## Phase 1: Efficiency-First Logging

### Goals

- Let the user log common meals quickly.
- Reduce repetitive typing.
- Make hydration logging reversible.
- Create reusable building blocks for meal templates and recent foods.

### Features

#### Quick-Add Favorite Meals

User story:
- As a user, I want to save meals I eat often so I can log them again quickly.

Requirements:
- Add a `MealTemplate` SwiftData model.
- A template should include name, meal type, optional photo reference, and food item templates.
- Add "Save as favorite" from `MealDetailView`.
- Add a "Quick add" section on `TodayView`.
- Tapping a template creates a new `Meal` for today with copied food items.

Data model:
- `MealTemplate`
  - `id: UUID`
  - `name: String`
  - `mealTypeRawValue: String`
  - `createdAt: Date`
  - `updatedAt: Date`
  - `useCount: Int`
  - `foodItems: [FoodItemTemplate]`
- `FoodItemTemplate`
  - `id: UUID`
  - `name: String`
  - `servingSize: String`
  - `quantity: Double`
  - `estimatedCalories: Int`
  - `protein: Double`
  - `carbs: Double`
  - `fat: Double`

Acceptance criteria:
- User can save an existing meal as a favorite.
- Favorite meal appears on Today.
- Tapping favorite meal logs a new meal for today.
- New logged meal is editable and independent from the template.

#### Repeat Yesterday's Breakfast/Lunch

User story:
- As a user, I want to repeat yesterday's common meal without rebuilding it.

Requirements:
- On `TodayView`, show a compact suggestion card when yesterday has meals.
- Suggestions should prioritize breakfast, lunch, and most repeated meal type.
- Tapping suggestion duplicates the meal for today.

Acceptance criteria:
- If yesterday has breakfast, Today shows "Repeat yesterday's breakfast".
- Duplicated meal has today's date.
- Duplicated food items preserve calories and macros.

#### Common Protein Shortcuts

User story:
- As a user, I want to add common protein sources quickly.

Requirements:
- Add a "Protein shortcuts" section inside `AddMealView`.
- Start with local static defaults:
  - Greek yogurt
  - Eggs
  - Chicken breast
  - Salmon
  - Protein shake
  - Cottage cheese
- Each shortcut should prefill a `FoodDraft`.

Acceptance criteria:
- Protein shortcuts add editable draft items.
- Shortcut items do not save until the meal is saved.
- User can remove or edit shortcut drafts.

#### Recent Foods Picker

User story:
- As a user, I want recent foods available while logging so I do not retype.

Requirements:
- Query recent `FoodItem`s from logged meals.
- Deduplicate by normalized food name and serving size.
- Show the most recent 8 in `AddMealView`.
- Tapping a recent food adds an editable draft.

Acceptance criteria:
- Recent foods appear after at least one meal is logged.
- Duplicates are collapsed.
- Tapping recent food does not auto-save.

#### One-Tap Water With Undo

User story:
- As a user, I want water logging to be instant and reversible.

Requirements:
- Replace "Add a glass" with a stronger one-tap button.
- After adding water, show an inline "Undo" affordance for a few seconds.
- Undo deletes the most recently added water entry.

Acceptance criteria:
- Tapping adds one glass immediately.
- Undo appears after tap.
- Undo removes only the last water entry added from that action.
- Changing water goal does not affect current count.

#### Save Meal As Template

User story:
- As a user, I want to convert a meal I just created into a reusable favorite.

Requirements:
- Add a polished "Save as favorite" button to `MealDetailView`.
- If a template already exists with the same name, ask whether to replace or create another.

Acceptance criteria:
- Template persists after restart.
- Template does not mutate when the original meal changes.

## Phase 2: Personalized Home Copy

### Goals

- Make the home screen feel like it is speaking to the user.
- Use personalization settings and motif toggles.
- Keep copy useful, not overly cute.

### Requirements

- Replace generic home copy with a `PersonalizedCopyService`.
- Inputs:
  - `partnerName`
  - `favoriteBottleName`
  - `themeVariant`
  - `horseMotifEnabled`
  - time of day
  - current progress state
- Output:
  - header phrase
  - hydration prompt
  - calorie card title
  - insight card copy

### Candidate Copy

General:
- "Small log, strong rhythm"
- "Protein before chaos"
- "A calm check-in"
- "Fuel the day simply"

Horse motif enabled:
- "Morning ride fuel?"
- "Stable rhythm"
- "Fueled like a show horse"
- "Strong legs, steady fuel"

Ceramic / premium ritual:
- "Ceramic bowl energy"
- "A pretty little reset"
- "Nice things, steady habits"
- "Soft ritual, strong body"

Hydration:
- "`{BottleName}` check"
- "One sip closer"
- "Hydration, but make it easy"

Acceptance criteria:
- Home copy uses direct-address language.
- Hydration prompt uses favorite bottle name.
- Horse motif changes some copy but does not dominate the UI.
- Copy remains short enough for small screens.

## Phase 3: Horse + Ceramics Visual Motifs

### Goals

- Add personal visual flavor without making the app feel novelty-themed.
- Prepare for future custom assets.

### Requirements

#### Motif System

- Create a `MotifStyle` helper driven by `AppSettings`.
- It should expose:
  - accent symbol
  - empty state symbol
  - progress language
  - optional background texture style

#### Ceramics Treatment

- Add a reusable `CeramicSurface` component.
- Visual direction:
  - off-white base
  - low-opacity speckles
  - soft glaze gradient
  - rounded, bowl-like shapes

Potential implementation:
- SwiftUI `Canvas` or repeated tiny circles for speckles.
- Reusable overlay modifier: `.ceramicTexture()`.

#### Horse Motif

- Use `figure.equestrian.sports` for now.
- Later custom assets:
  - hoof sparkle
  - horse-tail flourish
  - stable arch curve

Acceptance criteria:
- Motifs are optional.
- Turning horse motif off returns copy/icons to generic wellness language.
- Ceramic surfaces look premium and subtle.

## Phase 4: Custom Animation Foundation

### Goals

- Define the animation moments now so future custom animation work fits the architecture.

### Animation Moments

#### Water Droplet Bounce

Trigger:
- Add one glass.

Behavior:
- New droplet scales from 0.7 to 1.12 to 1.0.
- Button gives soft spring feedback.

#### Calorie Ring Spring

Trigger:
- Add or delete meal.

Behavior:
- Ring animates with spring.
- If daily calorie target is reached, show a subtle shimmer.

#### Horse/Hoofer Sparkle

Trigger:
- Complete protein goal or hydration goal when horse motif is enabled.

Behavior:
- Small sparkle particles near card corner.
- No loud confetti.

#### Ceramic Glaze Shimmer

Trigger:
- Save meal.

Behavior:
- Soft moving highlight across card.
- Should feel like light over glaze.

#### Camera Button Expansion

Trigger:
- Tap center camera tab or photo log CTA.

Behavior:
- Camera circle expands into `AddMealView`.
- This can be implemented later with matched geometry.

Implementation requirements:
- Add `AnimationTokens` constants.
- Avoid hardcoded animation curves throughout views.
- Prefer reusable modifiers for shimmer, bounce, and save confirmation.

Acceptance criteria:
- Initial implementation can be minimal.
- Motion must be subtle and fast.
- Animations should never block logging.

## Phase 5: Data Model Hardening

### Goals

- Make future iteration safer.
- Avoid runtime crashes from schema changes.
- Support templates, recent foods, and personalization cleanly.

### Requirements

#### Migration Strategy

Current MVP approach:
- New settings fields should be optional with computed defaults.
- Destructive reset remains available in Profile.

Next hardening step:
- Add versioned migration plan when template models are introduced.

#### Timestamps

Add where useful:
- `Meal.createdAt`
- `Meal.updatedAt`
- `FoodItem.createdAt`
- `MealTemplate.createdAt`
- `MealTemplate.updatedAt`

#### Daily Notes

User story:
- As a user, I want to add a small note about how the day felt.

Potential fields:
- `DailyNote`
  - `id`
  - `date`
  - `note`
  - `energyLevel`
  - `createdAt`
  - `updatedAt`

Acceptance criteria:
- Notes are optional.
- Notes do not clutter the main logging flow.

## Recommended Build Order

1. One-tap water with undo.
2. Personalized home copy service.
3. Common protein shortcuts in `AddMealView`.
4. Recent foods picker in `AddMealView`.
5. Meal templates and quick-add favorite meals.
6. Repeat yesterday's meal suggestions.
7. Ceramic surface component.
8. Horse motif copy/icon integration.
9. Animation tokens and first bounce animation.
10. Data model timestamps and migration plan.

## Immediate Next Implementation Ticket

### Ticket: One-Tap Water With Undo

Scope:
- Update `TodayView` hydration card.
- Store the last added `WaterEntry` in view state.
- Show inline undo button for a short period.
- Animate droplet update with spring.

Why first:
- It is low-risk.
- It directly improves efficiency.
- It creates the first interaction pattern for future delightful motion.

Acceptance criteria:
- Add water is one tap.
- Undo removes the last glass.
- Undo disappears after a short delay.
- Changing water goal only changes denominator/max.

