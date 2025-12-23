# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2024-12-23

### Added

#### Core Engine & Systems
- **GameManager**: Central game state management system
- **SceneManager**: Scene transition and lifecycle management
- **InputManager**: Unified input handling across platforms
- **AssetManager**: Resource loading and caching
- **EventBus**: Global event system for decoupled communication
- **SaveSystem**: Comprehensive save/load with manager and helper utilities
- **EconomySystem**: Currency and resource management
- **RPG Systems**: Inventory, items, and stat management with modifiers
- **Optimization Modules**: Battery saver, memory manager, performance monitor
- **Device Capability**: Dynamic quality settings based on device specs

#### UI Components (HUD)
- **Design System**:
  - `MGColors`: Regional themes (India, Africa, SEA, LATAM) + semantic colors
  - `MGTextStyles`: Typography system with HUD-specific styles
  - `MGSpacing`: Consistent spacing values and widgets
  - `MGTheme`: Dark mode support and theme management

- **UI Components**:
  - `MGButton`: Primary, secondary, and custom action buttons
  - `MGIconButton`: Small, medium, large icon buttons
  - `MGResourceBar`: Resource display with icon and value
  - `MGLinearProgress`: Customizable progress bars
  - `MGCard`, `MGModal`, `MGDialog`: Container and overlay widgets
  - `MGLoading`, `MGError`: Loading and error states
  - `MGOfflineIndicator`: Network status indicator
  - `VirtualJoystick`: Touch-based game controls

- **Accessibility**:
  - Colorblind modes and high contrast themes
  - Screen reader support
  - Haptic feedback manager
  - Adjustable timing and touch settings

- **Layout & Navigation**:
  - Adaptive layouts for tablets and foldables
  - Safe area handling for notches/cutouts
  - Screen orientation management
  - Game scaffold with standard structure

#### Features & Game Systems
- **Battle System**: Turn-based combat with entities, skills, buffs
- **Crafting System**: Recipe management and crafting queues
- **Deck System**: Card-based gameplay with deck manager
- **Idle System**: Offline calculator and resource generators
- **Puzzle System**: Grid manager and match solver for match-3 games
- **Progression**: Achievements, prestige, and upgrade managers
- **Quest System**: Daily quests and weekly challenges
- **Statistics**: Comprehensive stats tracking

#### Monetization & Services
- **Analytics Manager**: Event tracking with Firebase integration
- **Remote Config**: Dynamic configuration management
- **Ad Manager**: Frequency-controlled ad display
- **IAP Manager**: In-app purchases with P2W guard
- **Product Registry**: Centralized product management
- **Audio Manager**: Sound effects and music playback

#### Documentation & Examples
- **Example App**: Comprehensive showcase of all components
- **UI Usage Guide**: Component API reference and usage patterns
- **Monetization Guide**: Integration guide for ads and IAP
- **Test Suite**: Unit, widget, and integration tests
- **README**: Complete documentation with quick start guide

### Changed
- Migrated from 0.1.0 to 1.0.0 (stable release)
- Consolidated UI exports into `mg_ui.dart` all-in-one import
- Standardized component API across all widgets

### Integration Statistics
- **40+ games** using mg_common_game UI components
- **95%+ adoption rate** for core design system (Colors, Spacing, Typography)
- **85%+ adoption rate** for HUD components
- Supports **Portrait and Landscape** orientations
- Covers **3 UI complexity tiers** (Simple, Medium, Complex)

## [0.1.0] - 2024-11-01

### Added
- Initial project setup
- Basic HUD components (buttons, resource bars)
- Color system and typography
- Basic theme support

---

[1.0.0]: https://github.com/monthly-games/mg-common-game/compare/v0.1.0...v1.0.0
[0.1.0]: https://github.com/monthly-games/mg-common-game/releases/tag/v0.1.0
