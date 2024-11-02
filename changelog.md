# Changelog for "FonzAppraiser"

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.1.0] - 2024-11-02

### Added

- Auctioneer Advanced Suite ("Auc-Advanced" addon) added into the Auctioneer 
pricing system.

## [3.0.0] - 2024-11-02

### Added

- Ported to the WotLK 3.3.5a client.
- Auctionator pricing system for the WotLK 3.3.5a client added.
- TradeSkillMaster (TSM) pricing system for the WotLK 3.3.5a client added.

### Changed

- Saved addon data is now the same format across all clients. Old data may not
be compatible. **IMPORTANT:** Move or delete old `FonzAppraiser.lua` files under 
your `WTF\...\SavedVariables` folders to avoid any issues.

## [2.1.2] - 2023-12-16

### Fixed

- Fixed a bug in duration text order for minutes and seconds abbreviations.

## [2.1.1] - 2023-07-31

### Changed

- Fixed a bug in vendor value lookup for TBC items specifically.

## [2.1.0] - 2023-07-30

### Added

- Most Valuable Item added to minimap tooltip.

### Changed

- Fixed a TBC bug with the target progress bar not updating correctly after Target was changed.

## [2.0.0] - 2023-07-30

### Added

- Ported to the TBC 2.4.3 client.
- Double and single quote support for Search tab filter values, e.g. slot="off hand".
- New notice sound options added.
- Auctionator pricing system added. Codes: A.AUA (auction) and DE.AUA (disenchant).
- New minimap button added. Shift left mouse click to move the minimap button.
- Show/Hide minimap button option in a new "General" Settings tab added.
- Value earned in past hour added to "Session Value" display of the Summary, Sessions tabs and minimap button tooltip.
- Confirm option added on making a new session to delete oldest session at maximum sessions.

### Changed

- Raised the default notice thresholds due to item and gold inflation from the TBC expansion.
- Changed the default item notice sound from "Bloodlust" due to its presence as a combat game sound in TBC.
- Changed the default target notice sound from "levelup2" to "Achievement".
- Clicking the Clear Search button in the Search tab will now automatically do an empty search.
- Filter groups are now internally based on item id lists instead of item name, removing maintenance across locales.
- Added pricing system description to item tooltips.

### Removed

- All Ace library dependencies. This should help porting the addon between expansions.
- Integrated Fubar support. Fubar support can be supplied from outside the main addon.
- Money Correct Fix. This fix was more unreliable than not having it.

## [1.0.0] - 2022-02-02

### Added

- Initial public release.