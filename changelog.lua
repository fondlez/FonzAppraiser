local A = FonzAppraiser

A.HELP_VERSION = [[Version 3.1.1 - 2024-11-16 |cffffffff
[*] Updated the detection method for money from personal loot.
[*] Workaround for bug on some servers where group loot messages duplicate items.

|rVersion 3.1.0 - 2024-11-02 |cffffffff
[+] Auctioneer Advanced Suite ("Auc-Advanced" addon) added into the Auctioneer 
pricing system.

|rVersion 3.0.0 - 2024-11-02 |cffffffff
[+] Ported to the WotLK 3.3.5a client.
[+] Auctionator pricing system for the WotLK 3.3.5a client added.
[+] TradeSkillMaster (TSM) pricing system for the WotLK 3.3.5a client added.
[*] Saved addon data is now the same format across all clients. Old data may not
be compatible. **IMPORTANT:** Move or delete old `FonzAppraiser.lua` files under 
your `WTF\...\SavedVariables` folders to avoid any issues.

|rVersion 2.1.2 - 2023-12-16 |cffffffff
[*] Fixed a bug in duration text order for minutes and seconds abbreviations.

|rVersion 2.1.1 - 2023-07-31 |cffffffff
[*] Fixed a bug in vendor value lookup for TBC items specifically.

|rVersion 2.1.0 - 2023-07-30 |cffffffff
[+] Most Valuable Item added to minimap tooltip.
[*] Fixed a TBC bug with the target progress bar not updating correctly after Target was changed.

|rVersion 2.0.0 - 2023-07-30 |cffffffff
[+] Ported to the TBC 2.4.3 client.
[+] Double and single quote support for Search tab filter values, e.g. slot="off hand".
[+] New notice sound options added.
[+] Auctionator pricing system added. Codes: A.AUA (auction) and DE.AUA (disenchant).
[+] New minimap button added. Shift left mouse click to move the minimap button.
[+] Show/Hide minimap button option in a new "General" Settings tab added.
[+] Value earned in past hour added to "Session Value" display of the Summary, Sessions tabs and minimap button tooltip.
[+] Confirm option added on making a new session to delete oldest session at maximum sessions.
[*] Raised the default notice thresholds due to item and gold inflation from the TBC expansion.
[*] Changed the default item notice sound from "Bloodlust" due to its presence as a combat game sound in TBC.
[*] Changed the default target notice sound from "levelup2" to "Achievement".
[*] Clicking the Clear Search button in the Search tab will now automatically do an empty search.
[*] Filter groups are now internally based on item id lists instead of item name, removing maintenance across locales.
[*] Added pricing system description to item tooltips.
[-] All Ace library dependencies. This should help porting the addon between expansions.
[-] Integrated Fubar support. Fubar support can be supplied from outside the main addon.
[-] Money Correct Fix. This fix was more unreliable than not having it.

|rVersion 1.0.0 - 2022-02-02 |cffffffff
[+] Initial public release.

|r]]
