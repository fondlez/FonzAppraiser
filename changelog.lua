local A = FonzAppraiser

A.HELP_VERSION = [[Version 2.1.0 - 2023-07-30 |cffffffff
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
