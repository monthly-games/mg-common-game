# Widget Tests for mg_common_game

This directory contains comprehensive widget tests for the UI components in the mg_common_game library.

## Test Structure

```
test/widgets/
├── gacha/
│   └── gacha_pull_animation_test.dart    # Gacha system widget tests
├── battlepass/
│   └── battlepass_tier_list_test.dart    # Battle pass widget tests
├── buttons/
│   └── mg_button_test.dart               # Button widget tests
├── hud/
│   └── currency_display_test.dart        # HUD currency display tests
└── README.md                             # This file
```

## Running Tests

### Run all widget tests
```bash
cd d:/mg-games/repos/mg-common-game
flutter test test/widgets/
```

### Run specific test file
```bash
# Gacha tests
flutter test test/widgets/gacha/gacha_pull_animation_test.dart

# Battle pass tests
flutter test test/widgets/battlepass/battlepass_tier_list_test.dart

# Button tests
flutter test test/widgets/buttons/mg_button_test.dart

# Currency display tests
flutter test test/widgets/hud/currency_display_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage test/widgets/
```

## Test Coverage

### Gacha Widgets (`gacha_pull_animation_test.dart`)

#### GachaPullAnimation
- ✓ Widget rendering with results
- ✓ Reveal animation sequence
- ✓ Transition through all items
- ✓ Results grid display after animation
- ✓ onComplete callback functionality
- ✓ Single result handling
- ✓ Rarity badge display

#### GachaPullButton
- ✓ Label and cost rendering
- ✓ onPressed callback
- ✓ Disabled state behavior
- ✓ Loading indicator display
- ✓ Loading state interaction blocking
- ✓ Custom currency icon

#### GachaPityIndicator
- ✓ Current pulls and pity info display
- ✓ Remaining pulls calculation
- ✓ Soft pity indicator activation
- ✓ Soft pity indicator hiding
- ✓ Progress bar rendering
- ✓ Zero pulls edge case
- ✓ Hard pity edge case

### Battle Pass Widgets (`battlepass_tier_list_test.dart`)

#### BattlePassTierList
- ✓ Tier list rendering
- ✓ Tier level display
- ✓ Unlocked state handling
- ✓ Free reward claiming
- ✓ Claimed state display
- ✓ Premium locked state
- ✓ Premium reward claiming
- ✓ Empty tiers handling

#### BattlePassHeader
- ✓ Season information display
- ✓ Level and EXP display
- ✓ Premium badge visibility
- ✓ Purchase button visibility
- ✓ Purchase button hiding when premium
- ✓ onPurchasePremium callback
- ✓ Progress bar rendering
- ✓ Low remaining days warning

#### BattlePassMissionList
- ✓ Mission list rendering
- ✓ Progress display
- ✓ Claim button for completed missions
- ✓ onClaimMission callback
- ✓ Claimed state display
- ✓ EXP reward display
- ✓ Progress bar for each mission
- ✓ Empty missions handling
- ✓ Mission type icons display

### Button Widgets (`mg_button_test.dart`)

#### MGButton
- ✓ Label rendering
- ✓ onPressed callback
- ✓ Disabled state behavior
- ✓ Loading indicator display
- ✓ Icon display
- ✓ Primary button style
- ✓ Secondary button style
- ✓ Text button style
- ✓ Button size variations (small, medium, large)
- ✓ Custom width application
- ✓ Custom colors
- ✓ Semantic label support
- ✓ Accessibility touch area adaptation

#### MGIconButton
- ✓ Icon rendering
- ✓ onPressed callback
- ✓ Disabled state behavior
- ✓ Tooltip display
- ✓ Custom color application
- ✓ Background color application
- ✓ Button size variations
- ✓ Semantic label support
- ✓ Accessibility touch area adaptation

#### MGFloatingButton
- ✓ Icon rendering
- ✓ onPressed callback
- ✓ Mini size rendering
- ✓ Extended FAB with label
- ✓ Custom colors
- ✓ Tooltip display
- ✓ Semantic label support

### HUD Widgets (`currency_display_test.dart`)

#### CurrencyDisplay
- ✓ Amount and icon rendering
- ✓ Large amount formatting (K suffix)
- ✓ Million amount formatting (M suffix)
- ✓ onTap callback
- ✓ Add icon visibility
- ✓ Custom icon color
- ✓ Compact mode rendering
- ✓ Zero amount handling
- ✓ Negative amount handling

#### Factory Constructors
- ✓ CurrencyDisplay.gold
- ✓ CurrencyDisplay.gems
- ✓ CurrencyDisplay.energy
- ✓ CurrencyDisplay.crystals
- ✓ CurrencyDisplay.tokens

#### Animation
- ✓ Amount change animation
- ✓ Animation disable option

#### Formatting Edge Cases
- ✓ Exactly 1000 formatting
- ✓ Exactly 1000000 formatting
- ✓ 999 without suffix
- ✓ 999999 with K suffix

## Test Patterns Used

### Widget Testing
- **Pump and Settle**: Used for animations and asynchronous UI updates
- **Finder**: Used to locate widgets by type, text, icon, or semantic label
- **Tap Gestures**: Used to test user interactions
- **Callback Verification**: Used to ensure callbacks are triggered correctly

### State Testing
- **Initial State**: Verify widgets render correctly on first build
- **State Transitions**: Test state changes (enabled/disabled, loading, etc.)
- **User Interactions**: Test tap, scroll, and other gestures
- **Edge Cases**: Test boundary conditions and unusual inputs

### Accessibility Testing
- **Semantic Labels**: Ensure screen readers can identify elements
- **Touch Area Sizing**: Verify buttons meet minimum touch target sizes
- **Accessibility Provider**: Test integration with accessibility settings

## Test Dependencies

The tests use the following packages (from `pubspec.yaml`):
- `flutter_test`: Flutter's testing framework
- `mocktail`: Mock object creation (available but not used in these tests)

## Best Practices Followed

1. **Descriptive Test Names**: Each test clearly describes what it tests
2. **Arrange-Act-Assert**: Tests follow AAA pattern for clarity
3. **Test Isolation**: Each test is independent and doesn't rely on others
4. **setUp/tearDown**: Used for common test setup when needed
5. **Edge Case Coverage**: Tests cover normal cases, edge cases, and error conditions
6. **No Golden Tests**: As requested, golden tests are excluded due to environment dependencies

## Notes

- **No API Mocking**: Tests use real widget implementations without mocking HTTP calls (widgets don't make API calls directly)
- **Accessibility Context**: Tests wrap widgets in `MGAccessibilityProvider` when needed for button tests
- **Material App Wrapper**: All widgets are wrapped in `MaterialApp` for proper context
- **Animation Testing**: Uses `pumpAndSettle()` to wait for animations to complete

## Future Improvements

Potential additions for more comprehensive testing:
- Integration tests for complete user flows
- Performance benchmarking tests
- Accessibility audit tests
- Localization tests for Korean text
- Platform-specific behavior tests (iOS vs Android)
