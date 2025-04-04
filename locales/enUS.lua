FonzAppraiser_Locale_Data = {}
FonzAppraiser_Locale_Data.code = GetLocale() or "enUS"
FonzAppraiser_Locale_Data["enUS"] = {  
  ------------------
  -- TRANSLATIONS --
  ------------------
  
  [" (stopped)"] = true,
  ["$ | <number> | name <number> <string> | del <number>" .. " | [number] top [1-10] | [number] hot [1-10] | [number] all" .. " | [number] loot | list | purge | search <string>"] = true,
  ["%d exceeds number of possible sessions."] = true,
  ["%d is lower than the number of existing sessions. " .. "Oldest sessions will be deleted."] = true,
  ["%d loots"] = true,
  ["%s Money - %s: %s"] = true,
  ["%s count: %d"] = true,
  ["%s value: %s"] = true,
  ["(%s / hour) "] = true,
  [", %d items"] = true,
  [", %s value"] = true,
  ["<empty>"] = true,
  ["<invalid>"] = true,
  ["<money> or |cffffff7f%s|r"] = true,
  ["<number: channel number> <string: message to channel>."] = true,
  ["<number:1-10>"] = true,
  ["<number>"] = true,
  ["<string: character name> <string: message to whisper>."] = true,
  ["<string>"] = true,
  ["All Items [%s]:"] = true,
  ["All sessions deleted."] = true,
  ["All"] = true,
  ["All: "] = true,
  ["Any sound playable with WoW PlaySoundFile() or PlaySound() " .. "(<string>)."] = true,
  ["Auctionator: auction median"] = true,
  ["Auctionator: auction"] = true,
  ["Auctionator: disenchant"] = true,
  ["Auctioneer: buyout"] = true,
  ["Auctioneer: min"] = true,
  ["Auctioneer: minimum suggested price"] = true,
  ["Bag value (reverse)"] = true,
  ["Bag value"] = true,
  ["Change maximum number of sessions "] = true,
  ["Channel"] = true,
  ["Clear"] = true,
  ["Click to rename session"] = true,
  ["Click to set session value target"] = true,
  ["Config"] = true,
  ["Count"] = true,
  ["Credits"] = true,
  ["Currency: %s"] = true,
  ["Currency:"] = true,
  ["Current session stopped."] = true,
  ["Delete ALL Sessions: are you sure?"] = true,
  ["Delete ALL sessions"] = true,
  ["Delete Selected"] = true,
  ["Delete oldest session after maximum sessions"] = true,
  ["Delete selected sessions"] = true,
  ["Delete"] = true,
  ["Description"] = true,
  ["Detail of session%s:"] = true,
  ["Disable output"] = true,
  ["Duration: %s"] = true,
  ["Earned above threshold ({threshold}) : {money}"] = true,
  ["Enable chat output"] = true,
  ["Enable money correction"] = true,
  ["Filter item lists by minimum rarity"] = true,
  ["Found %d results."] = true,
  ["General"] = true,
  ["Group"] = true,
  ["Guild"] = true,
  ["Help"] = true,
  ["Hide minimap icon"] = true,
  ["Hot Items [%s]:"] = true,
  ["Hot Items%s:"] = true,
  ["Hot item {item} - threshold ({threshold}) : total value {value}" .." ({count}x)"] = true,
  ["Hot item"] = true, 
  ["Hot"] = true,
  ["Hot: "] = true,
  ["Hourly:"] = true,
  ["Ignore Soulbound"] = true,
  ["Ignore soulbound items"] = true,
  ["Increasing maximum number of sessions to %d."] = true,
  ["Invalid argument"] = true,
  ["Item Pricing"] = true,
  ["Item Quality"] = true,
  ["Item value threshold"] = true,
  ["Item"] = true,
  ["Items [%s]:"] = true,
  ["Items"] = true,
  ["Items%s:"] = true,
  ["List items of %s rarity or better"] = true,
  ["Lists sessions"] = true,
  ["Maximum number of sessions is already %d."] = true,
  ["Maximum sessions number"] = true,
  ["Maximum sessions. Delete oldest session?"] = true,
  ["Min:"] = true,
  ["Money threshold"] = true,
  ["Money"] = true,
  ["Most Valuable Item"] = true,
  ["New Session"] = true,
  ["New session started!"] = true,
  ["No sessions found."] = true,
  ["Notice Item"] = true,
  ["Notice Money"] = true,
  ["Notice Threshold"] = true,
  ["Notice valuable loot"] = true,
  ["Notice"] = true,
  ["Notice:"] = true,
  ["Notify Method"] = true,
  ["Notify by sound"] = true,
  ["Notify by whisper"] = true,
  ["Notify channel"] = true,
  ["Notify group"] = true,
  ["Notify guild"] = true,    
  ["Notify methods for %s"] = true,
  ["Notify methods for Notices"] = true,
  ["Notify system chat"] = true,
  ["Notify"] = true,
  ["Notify:"] = true,
  ["Off"] = true,
  ["Okay"] = true,
  ["On"] = true,
  ["Poor | Uncommon | Common | Rare | Epic | <number:0-4>"] = true,
  ["Price:"] = true,
  ["Pricing system for the value of items"] = true,
  ["Pricing system"] = true,
  ["Pricing:"] = true,
  ["Progress:"] = true,
  ["Purge All"] = true,
  ["Purge all sessions"] = true,
  ["Purge"] = true,
  ["Reduce maximum number of sessions (destructive)?"] = true,
  ["Rename Session"] = true,
  ["Renamed session [%d] to %s."] = true,
  ["Results: %d loots, %d items, %s value"] = true,
  ["Results:"] = true,
  ["Return to defaults"] = true,
  ["Search Filters:"] = true,
  ["Search loot from all sessions"] = true,
  ["Search sessions"] = true,
  ["Search"] = true,
  ["Session Value:"] = true,
  ["Session start"] = true,
  ["Session stop"] = true,
  ["Session"] = true,
  ["Sessions list"] = true,
  ["Sessions purge"] = true,
  ["Sessions"] = true,
  ["Sessions:"] = true,
  ["Set minimum value to trigger notice"] = true,
  ["Setting for each type of notify method"] = true,
  ["Settings"] = true,
  ["Show minimap button"] = true,
  ["Show"] = true,
  ["Shows detail of sessions"] = true,
  ["Shows the configuration window"] = true,
  ["Shows the help window"] = true,
  ["Shows the main window"] = true,
  ["Sound"] = true,
  ["Start Session"] = true,
  ["Start:"] = true,
  ["Starts a session"] = true,
  ["Stops and terminates a session"] = true,
  ["Summary"] = true,
  ["System chat message (<string>)."] = true,
  ["System"] = true,
  ["TSM: disenchant value"] = true,
  ["TSM: market value"] = true,
  ["TSM: minimum buyout"] = true,
  ["Target for total value notices, e.g. %s"] = true,
  ["Target of {threshold} achieved: {value}!"] = true,
  ["Target"] = true,
  ["Target:"] = true,
  ["Threshold for item value notices, e.g. %s"] = true,
  ["Threshold for money notices, e.g. %s"] = true,
  ["Threshold: %s"] = true,
  ["Toggle whether to ignore soulbound items"] = true,
  ["Toggles whether to show chat output"] = true,
  ["Top: "] = true,
  ["Total value target"] = true,
  ["Total value: %s"] = true,
  ["Total: %s"] = true,
  ["Type:"] = true,
  ["Unknown keyword"] = true,
  ["Value of non-soulbound items in bags (reverse)"] = true,
  ["Value of non-soulbound items in bags"] = true,
  ["Value"] = true,
  ["Vendor"] = true,
  ["Version History"] = true,
  ["When:"] = true,
  ["Whisper"] = true,
  ["Zone: %s"] = true,
  ["Zone:"] = true,
  ["addon"] = true,
  ["aux-addon: daily"] = true,
  ["aux-addon: disenchant value"] = true,
  ["aux-addon: tooltip daily"] = true,
  ["aux-addon: tooltip value"] = true,
  ["aux-addon: value"] = true,
  ["channel"] = true,
  ["correction"] = true,
  ["error"] = true,
  ["fishing"] = true,
  ["group"] = true,
  ["guild"] = true,
  ["herbalism"] = true,
  ["is currently set to"] = true,
  ["mining"] = true,
  ["shared"] = true,
  ["skinning"] = true,
  ["solo"] = true,
  ["sound"] = true,
  ["system"] = true,
  ["whisper"] = true,
  ["|cffffff7f%s|r to reset or |cffffff7f%s|r to disable. Format: %s"] = true,
  ['"Gold Per Hour": %s'] = true,
  ['Session [%d] "%s" deleted.'] = true,
  ['Session deleted: "%s"'] = true,
    
  --------------------------------------------------------------------------------
  
  ------------
  -- TOKENS --
  ------------
  
  -- Currency names. Also used for currency abbreviations.
  -- This group can be translated, i.e. replace "true" with the key translation.
  COPPER = true,
  SILVER = true,
  GOLD = true,

  -- Keybinds
  BINDING_NAME_FA_SHOWMAIN = "Show main window",
  BINDING_NAME_FA_STARTSESSION = "Start a new session",
  BINDING_NAME_FA_STOPSESSION = "Stop current session",

  -- Addon commands
  SLASHCMD_LONG = "/appraiser",
  SLASHCMD_SHORT = "/fa",

  SLASHCMD_BAG_VALUE1 = "/value",
  SLASHCMD_BAG_VALUE2 = "/bvalue",

  SLASHCMD_BAG_REVERSE_VALUE1 = "/rvalue",
  SLASHCMD_BAG_REVERSE_VALUE2 = "/rbvalue",

  -- Help text
  HELP_DESCRIPTION = 
[[<html><body>
<h1>FonzAppraiser</h1>
<br/>
<p>FonzAppraiser is an addon for World of Warcraft (1.12, 2.4.3, 3.3.5 clients) 
to track the value of personal loot. It tracks item and money loot from corpses 
and ground loot from gathering nodes, that is herbalism, mining and skinning.
</p>
<br/>
<p>It obtains value from several pricing systems. The following pricing systems 
are currently supported: vendor/merchant sale, "aux-addon", "Auctioneer",
Auctionator (TBC+), TradeSkillMaster/TSM (WotLK) addons.</p>
<br/>
<p>The addon supports keybinds to show main menu, start session and 
stop session - so you can use it as a timer too.</p>
<br/>
<h2>General Slash Commands:</h2>
<h3>/fa show</h3><p> - show the main window.</p>
<h3>/fa start</h3><p> - start a new session (stops any previous session).</p>
<h3>/fa stop</h3><p> - stop the current session.</p>
<h3>/fa config</h3><p> - show the configuration window.</p>
<h3>/fa help</h3><p> - show this help window.</p>
<h3>/fa enable</h3><p> - toggle whether to show chat output for each loot.</p>
<h3>/value</h3><p> - list value of bag items in chat (valuable at the bottom).
</p>
<h3>/rvalue</h3><p> - list value of bag items in chat (valuable at the top).</p>
<br/>
<h2>Advanced Slash Commands:</h2>
<h3>/fa search &lt;filters&gt;</h3><p> - search all loots for items matching 
filters.</p>
<h3>/fa purge</h3><p> - delete all sessions (warning: instant delete, no 
confirmation).</p>
<h3>/fa maxsessions &lt;number&gt;</h3><p> - change maximum number of sessions 
(5 by default).</p>
<h3>/fa pricing &lt;string&gt;</h3><p> - set the pricing system.</p>
<br/>
<h2>Search Filters:</h2>
<p>The basic search looks for item links or parts (aka. substring) of an item 
name:</p>
<br/>
<p>    dream</p>
<br/>
<p>matches all loots with with "dream" in their name, e.g. dreamfoil herb.</p>
<br/>
<p>More precise or flexible searches can use search filters. Search filter 
syntax:</p>
<br/>
<p>filter1=value1/filter2=value2/.../filtern=valuen</p>
<br/>
<p>Examples:</p>
<p>    lmin=51/lmax=60/rarity=rare</p>
<br/>
<p>matches all items of minimum level 51 to 60 that are blue (rare)</p>
<br/>
<p>    slot=finger/quality=uncommon</p>
<br/>
<p>matches all rings with rarity uncommon or better</p>
<br/>
<p>List of possible search filters:</p>
<h3>count</h3><p> = &lt;number: count of items in a loot&gt;</p>
<h3>from</h3><p> =  &lt;date: loots starting from date, e.g. 2022-01-01&gt;</p>
<h3>group</h3><p> = "herbalism" | "mining" | "skinning" | "fishing"</p>
<h3>id</h3><p> = &lt;number: item id, e.g. 18401&gt;</p>
<h3>level</h3><p> = &lt;number: exact item level [1-63]&gt;</p>
<h3>lmax</h3><p> = &lt;number: maximum item level [1-63]&gt;</p>
<h3>lmin</h3><p> = &lt;number: minimum item level [1-63]&gt;</p>
<h3>name</h3><p> = &lt;string: item name substring, e.g. dreamfoil&gt;</p>
<h3>quality</h3><p> = &lt;string: minimum item rarity substring, 
e.g. uncommon&gt;</p>
<h3>rarity</h3><p> = &lt;string: item rarity substring, e.g. rare&gt;</p>
<h3>session</h3><p> = &lt;number: session number [1-10]&gt;</p>
<h3>since</h3><p> = &lt;duration: loots since duration ago, 
e.g. 4d 10h 7m 10s&gt;</p>
<h3>slot</h3><p> = &lt;string: armor or weapon slot (same as auction house), 
e.g. head&gt;</p>
<h3>subtype</h3><p> = &lt;string: item subtype (same as auction house), 
e.g. alchemy&gt;</p>
<h3>to</h3><p> = &lt;date: loots up to date, e.g. 2022-01-01&gt;</p>
<h3>type</h3><p> = &lt;string: item type (same as auction house), 
e.g. recipe&gt;</p>
<h3>until</h3><p> = &lt;duration: loots until duration ago, 
e.g. 4d 10h 7m 10s&gt;</p>
<h3>value</h3><p> = &lt;money: minimum money value, e.g. 1g 3s 2c or 10302 
&gt;</p>
<h3>zone</h3><p> = &lt;string: zone name substring, e.g. winter&gt;</p>
<br/>
<p>All search filter names can be shortened to any unique starting string.
 Most string values can use substrings. So, instead of typing, `group=herbalism`
 you could type `g=herb` to show all loots containing herbs.</p>
<br/>
<h2>Options - Notify Chat Fields:</h2>
<p>{zone}, {threshold}, {item}, {money}, {value}, {count}, {pricing}</p>
<br/>
<p>These can be used inside notify chat messages like this example for Item:
</p>
<br/>
<p>"Got {count}x {item} worth {value} ({pricing}) while in {zone}!" (minus the 
quotes)</p>
<br/>
<h2>Known Issues:</h2>
<h3>[*] notify guild</h3><p> - some servers restrict guild chat messaging from 
addons and perhaps other types of chat messages.</p>
<br/>
</body></html>]],
  HELP_CREDITS =
[[<html><body>

<h1>FonzAppraiser by fondlez</h1>
<br/>
<p>The original idea and implementation for this addon were by fondlez.</p>
<br/>
<p>Ever leveled to max level on a fresh, but low population server and are now faced
with the daunting task of finding the initial gold to do ... anything? This
addon was written because I thought tracking my progress towards specific goals 
would be a lot more fun! I hope you find the same or even find other uses for
it.</p>
<br/>
<h2>Special Credits:</h2>
<br/>
<h3>Shagu</h3><p> - probably the most prolific addon author in the vanilla
community! A special thank you, especially for the data mined vendor
prices and Search bar interface. Embedded license included.</p>
<h3>shirsig</h3><p> - the author best known for Mail, Postal and Aux inspired
me to cleaner code with his very different coding style.</p>
<h3>Roadblock</h3><p> - the author of Interruptor and vanilla backport of the 
amazing Possessions addon inspired me to make my first graphical addon with 
Fubar support.</p>
<br/>
<h2>Other Addons:</h2>
<br/>
<h3>CT_ExpenseHistory</h3><p> - the addon that inspired the tabbed dialog
interface. This was originally written back in 2006 or earlier!</p>
<h3>LootAppraiser Classic</h3><p> - thank you to ProfitzTV and co. for enabling
me to put a name to the idea for the addon and a basic look-n-feel for their
popular WoW Classic addon.</p>
<br/>
</body></html>]],
}