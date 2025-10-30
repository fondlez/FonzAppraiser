local A = FonzAppraiser
local L = A.locale

A.module 'fa.filter'

local client = A.require 'util.client'
local util = A.requires(
  'util.string'
)

local groups_vanilla = {
  [L["herbalism"]] = {
    [8836] = true, -- Arthas' Tears
    [13468] = true, -- Black Lotus
    [8839] = true, -- Blindweed
    [19726] = true, -- Bloodvine
    [2450] = true, -- Briarthorn
    [2453] = true, -- Bruiseweed
    [13463] = true, -- Dreamfoil
    [2449] = true, -- Earthroot
    [3818] = true, -- Fadeleaf
    [4625] = true, -- Firebloom
    [8845] = true, -- Ghost Mushroom
    [13464] = true, -- Golden Sansam
    [3821] = true, -- Goldthorn
    [3369] = true, -- Grave Moss
    [8846] = true, -- Gromsblood
    [13467] = true, -- Icecap
    [3358] = true, -- Khadgar's Whisker
    [3356] = true, -- Kingsblood
    [3357] = true, -- Liferoot
    [785] = true, -- Mageroyal
    [13465] = true, -- Mountain Silversage
    [2447] = true, -- Peacebloom
    [13466] = true, -- Plaguebloom
    [8831] = true, -- Purple Lotus
    [765] = true, -- Silverleaf
    [3820] = true, -- Stranglekelp
    [8838] = true, -- Sungrass
    [2452] = true, -- Swiftthistle
    [3355] = true, -- Wild Steelbloom
    [8153] = true, -- Wildvine
    [3819] = true, -- Wintersbite
  },
  [L["mining"]] = {
    [7909] = true, -- Aquamarine
    [12363] = true, -- Arcane Crystal
    [12800] = true, -- Azerothian Diamond
    [11754] = true, -- Black Diamond
    [9262] = true, -- Black Vitriol
    [11382] = true, -- Blood of the Mountain
    [12361] = true, -- Blue Sapphire
    [3864] = true, -- Citrine
    [2836] = true, -- Coarse Stone
    [2770] = true, -- Copper Ore
    [11370] = true, -- Dark Iron Ore
    [12365] = true, -- Dense Stone
    [7067] = true, -- Elemental Earth
    [7076] = true, -- Essence of Earth
    [2776] = true, -- Gold Ore
    [2838] = true, -- Heavy Stone
    [12364] = true, -- Huge Emerald
    [2772] = true, -- Iron Ore
    [1529] = true, -- Jade
    [22203] = true, -- Large Obsidian Shard
    [12799] = true, -- Large Opal
    [1705] = true, -- Lesser Moonstone
    [774] = true, -- Malachite
    [3858] = true, -- Mithril Ore
    [1206] = true, -- Moss Agate
    [2835] = true, -- Rough Stone
    [1210] = true, -- Shadowgem
    [2775] = true, -- Silver Ore
    [22202] = true, -- Small Obsidian Shard
    [7912] = true, -- Solid Stone
    [19774] = true, -- Souldarite
    [7910] = true, -- Star Ruby
    [10620] = true, -- Thorium Ore
    [818] = true, -- Tigerseye
    [2771] = true, -- Tin Ore
    [7911] = true, -- Truesilver Ore
  },
  [L["skinning"]] = {
    [15416] = true, -- Black Dragonscale
    [7286] = true, -- Black Whelp Scale
    [15415] = true, -- Blue Dragonscale
    [12607] = true, -- Brilliant Chromatic Scale
    [15423] = true, -- Chimera Leather
    [17012] = true, -- Core Leather
    [6470] = true, -- Deviate Scale
    [15417] = true, -- Devilsaur Leather
    [20381] = true, -- Dreamscale
    [15422] = true, -- Frostsaber Leather
    [15412] = true, -- Green Dragonscale
    [7392] = true, -- Green Whelp Scale
    [4235] = true, -- Heavy Hide
    [4234] = true, -- Heavy Leather
    [15408] = true, -- Heavy Scorpid Scale
    [20501] = true, -- Heavy Silithid Carapace
    [783] = true, -- Light Hide
    [2318] = true, -- Light Leather
    [20500] = true, -- Light Silithid Carapace
    [4232] = true, -- Medium Hide
    [2319] = true, -- Medium Leather
    [6471] = true, -- Perfect Deviate Scale
    [19767] = true, -- Primal Bat Leather
    [19768] = true, -- Primal Tiger Leather
    [15414] = true, -- Red Dragonscale
    [7287] = true, -- Red Whelp Scale
    [8171] = true, -- Rugged Hide
    [8170] = true, -- Rugged Leather
    [2934] = true, -- Ruined Leather Scraps
    [15410] = true, -- Scale of Onyxia
    [8154] = true, -- Scorpid Scale
    [7428] = true, -- Shadowcat Hide
    [20498] = true, -- Silithid Chitin
    [8169] = true, -- Thick Hide
    [4304] = true, -- Thick Leather
    [8368] = true, -- Thick Wolfhide
    [8167] = true, -- Turtle Scale
    [15419] = true, -- Warbear Leather
    [8165] = true, -- Worn Dragonscale
  },
  [L["fishing"]] = {
    [13888] = true, -- Darkclaw Lobster
    [6522] = true, -- Deviate Fish
    [7070] = true, -- Elemental Water
    [7080] = true, -- Essence of Water
    [6359] = true, -- Firefin Snapper
    [13893] = true, -- Large Raw Mightfish
    [6358] = true, -- Oily Blackmouth
    [6291] = true, -- Raw Brilliant Smallfish
    [6308] = true, -- Raw Bristle Whisker Catfish
    [13754] = true, -- Raw Glossy Mightfish
    [21153] = true, -- Raw Greater Sagefish
    [6317] = true, -- Raw Loch Frenzy
    [6289] = true, -- Raw Longjaw Mud Snapper
    [8365] = true, -- Raw Mithril Head Trout
    [13759] = true, -- Raw Nightfin Snapper
    [6361] = true, -- Raw Rainbow Fin Albacore
    [13758] = true, -- Raw Redgill
    [6362] = true, -- Raw Rockscale Cod
    [21071] = true, -- Raw Sagefish
    [6303] = true, -- Raw Slitherskin Mackerel
    [4603] = true, -- Raw Spotted Yellowtail
    [13756] = true, -- Raw Summer Bass
    [13760] = true, -- Raw Sunscale Salmon
    [13889] = true, -- Raw Whitescale Salmon
    [13422] = true, -- Stonescale Eel
    [13755] = true, -- Winter Squid
    [7974] = true, -- Zesty Clam Meat
  },
}

local groups_tbc = {
  [L["herbalism"]] = {
    [22790] = true, -- Ancient Lichen
    [22710] = true, -- Bloodthistle
    [22786] = true, -- Dreaming Glory
    [22795] = true, -- Fel Blossom
    [22794] = true, -- Fel Lotus
    [22785] = true, -- Felweed
    [22788] = true, -- Flame Cap
    [22793] = true, -- Mana Thistle
    [22575] = true, -- Mote of Life
    [22576] = true, -- Mote of Mana
    [35229] = true, -- Nether Residue
    [22791] = true, -- Netherbloom
    [32468] = true, -- Netherdust Pollen
    [32506] = true, -- Netherwing Egg
    [22797] = true, -- Nightmare Seed
    [22792] = true, -- Nightmare Vine
    [22787] = true, -- Ragveil
    [25813] = true, -- Small Mushroom
    [29453] = true, -- Sporeggar Mushroom
    [22789] = true, -- Terocone
    [24401] = true, -- Unidentified Plant Parts
    [27859] = true, -- Zangar Caps
  },
  [L["mining"]] = {
    [23425] = true, -- Adamantite Ore
    [23117] = true, -- Azure Moonstone
    [23077] = true, -- Blood Garnet
    [32227] = true, -- Crimson Spinel
    [23440] = true, -- Dawnstone
    [23079] = true, -- Deep Peridot
    [32228] = true, -- Empyrean Sapphire
    [23427] = true, -- Eternium Ore
    [23424] = true, -- Fel Iron Ore
    [21929] = true, -- Flame Spessarite
    [23112] = true, -- Golden Draenite
    [23426] = true, -- Khorium Ore
    [32229] = true, -- Lionseye
    [23436] = true, -- Living Ruby
    [22573] = true, -- Mote of Earth
    [22574] = true, -- Mote of Fire
    [35229] = true, -- Nether Residue
    [32464] = true, -- Nethercite Ore
    [32506] = true, -- Netherwing Egg
    [23441] = true, -- Nightseye
    [23439] = true, -- Noble Topaz
    [32231] = true, -- Pyrestone
    [32249] = true, -- Seaspray Emerald
    [23107] = true, -- Shadow Draenite
    [32230] = true, -- Shadowsong Amethyst
    [23438] = true, -- Star of Elune
    [23437] = true, -- Talasite
    [22634] = true, -- Underlight Ore
  },
  [L["skinning"]] = {
    [29539] = true, -- Cobra Scales
    [25699] = true, -- Crystal Infused Leather
    [25707] = true, -- Fel Hide
    [25700] = true, -- Fel Scales
    [21887] = true, -- Knothide Leather
    [25649] = true, -- Knothide Leather Scraps
    [23677] = true, -- Moongraze Buck Hide
    [29548] = true, -- Nether Dragonscales
    [35229] = true, -- Nether Residue
    [32470] = true, -- Nethermine Flayer Hide
    [25708] = true, -- Thick Clefthoof Leather
    [29547] = true, -- Wind Scales
  },
  [L["fishing"]] = {
    [34864] = true, -- Baby Crocolisk
    [27422] = true, -- Barbed Gill Trout
    [34865] = true, -- Blackfin Darter
    [35286] = true, -- Bloated Giant Sunfish
    [33823] = true, -- Bloodfin Catfish
    [33824] = true, -- Crescent-Tail Skullfish
    [27513] = true, -- Curious Crate
    [27516] = true, -- Enormous Barbed Gill Trout
    [23424] = true, -- Fel Iron Ore
    [27435] = true, -- Figluster's Mudfish
    [27439] = true, -- Furious Crawdad
    [34866] = true, -- Giant Freshwater Shrimp
    [35285] = true, -- Giant Sunfish
    [27438] = true, -- Golden Darter
    [27481] = true, -- Heavy Supply Crate
    [27515] = true, -- Huge Spotted Feltail
    [27437] = true, -- Icefin Bluefish
    [27511] = true, -- Inscribed Scrollcase
    [24476] = true, -- Jaggal Clam
    [25649] = true, -- Knothide Leather Scraps
    [34867] = true, -- Monstrous Felblood Snapper
    [22578] = true, -- Mote of Water
    --[[
    [21877] = true, -- Netherweave Cloth
    [27499] = true, -- Scroll of Intellect V
    [27500] = true, -- Scroll of Protection V
    [27502] = true, -- Scroll of Stamina V
    [27503] = true, -- Scroll of Strength V
    --]]
    [27425] = true, -- Spotted Feltail
    [34868] = true, -- World's Largest Mudfish
    [27429] = true, -- Zangarian Sporefish
  },
}

local groups_wotlk = {
  [L["herbalism"]] = {
    [36903] = true, -- Adder's Tongue
    [37704] = true, -- Crystallized Life
    [37921] = true, -- Deadnettle
    [39970] = true, -- Fire Leaf
    [36908] = true, -- Frost Lotus
    [36901] = true, -- Goldclover
    [36906] = true, -- Icethorn
    [36905] = true, -- Lichbloom
    [36907] = true, -- Talandra's Rose
    [36904] = true, -- Tiger Lily
  },
  [L["mining"]] = {
    [36921] = true, -- Autumn's Glow
    [36917] = true, -- Bloodstone
    [36923] = true, -- Chalcedony
    [36909] = true, -- Cobalt Ore
    [37700] = true, -- Crystallized Air
    [37701] = true, -- Crystallized Earth
    [37702] = true, -- Crystallized Fire
    [37703] = true, -- Crystallized Shadow
    [37705] = true, -- Crystallized Water
    [36932] = true, -- Dark Jade
    [35624] = true, -- Eternal Earth
    [35627] = true, -- Eternal Shadow
    [36933] = true, -- Forest Emerald
    [36929] = true, -- Huge Citrine
    [36930] = true, -- Monarch Topaz
    [36912] = true, -- Saronite Ore
    [36918] = true, -- Scarlet Ruby
    [36926] = true, -- Shadow Crystal
    [36924] = true, -- Sky Sapphire
    [36920] = true, -- Sun Crystal
    [36910] = true, -- Titanium Ore
    [36927] = true, -- Twilight Opal
  },
  [L["skinning"]] = {
    [44128] = true, -- Artic Fur
    [38558] = true, -- Nerubian Chitin
    [33568] = true, -- Borean Leather
    [38557] = true, -- Icy Dragonscale
    [38561] = true, -- Jormungar Scale
    [33567] = true, -- Borean Leather Scraps
  },
  [L["fishing"]] = {
    [41812] = true, -- Barrelhead Goby
    [41808] = true, -- Bonescale Snapper
    [41805] = true, -- Borean Man O' War
    [41800] = true, -- Deep Sea Monsterbelly
    [41807] = true, -- Dragonfin Angelfish
    [41810] = true, -- Fangtooth Herring
    [41809] = true, -- Glacial Salmon
    [41814] = true, -- Glassfin Minnow
    [41802] = true, -- Imperial Manta Ray
    [41801] = true, -- Moonglow Cuttlefish
    [41806] = true, -- Mussleback Sculpin
    [41813] = true, -- Nettlefish
    [40199] = true, -- Pygmy Suckerfish
    [41803] = true, -- Rockfin Grouper
    [44703] = true, -- Dark Herring
    [44505] = true, -- Duskbringer
    [46109] = true, -- Sea Turtle
    [45909] = true, -- Giant Darkwater Clam
    [43647] = true, -- Shimmering Minnow
    [43752] = true, -- Magic Eater
    [43652] = true, -- Slippery Eel
    [43571] = true, -- Sewer Carp
    [36781] = true, -- Darkwater Clam
    [43646] = true, -- Fountain Goldfish
    [44475] = true, -- Reinforced Crate
    [43698] = true, -- Giant Sewer Rat
  },
}

local content = client.content
do
  local groups = groups_vanilla
  
  if content.expansion >= content.TBC then
    for k in pairs(groups_tbc) do
      local group = groups[k]
      for l in pairs(groups_tbc[k]) do
        group[l] = true
      end
    end
  end
  
  if content.expansion >= content.WOTLK then
    for k in pairs(groups_wotlk) do
      local group = groups[k]
      for l in pairs(groups_wotlk[k]) do
        group[l] = true
      end
    end
  end
  
  M.filter_groups = groups
end

function M.isFilterGroup(str)
  return util.uniqueKeySearch(filter_groups, str, util.strStartsWith)
end

function M.getFilterGroup(str)
  local name = isFilterGroup(str)
  return name and filter_groups[name]
end
