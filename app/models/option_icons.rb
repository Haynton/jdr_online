# The icons an option of a list may show on its card (a list declares them: icons, { option => key }): the emblems of
# the classes, of the backgrounds, of the species. Chosen among the icons of the app (shared/icons, Lucide), by a key
# the template writes; the page draws the partial of the key (CharacterSheets::OptionCardsHelper). A new icon: its
# partial, its line
module OptionIcons
  PARTIALS = {
    "axe" => "shared/icons/axe", "book_open" => "shared/icons/book_open", "castle" => "shared/icons/castle",
    "church" => "shared/icons/church", "cog" => "shared/icons/cog", "crown" => "shared/icons/crown",
    "dices" => "shared/icons/dices", "eye" => "shared/icons/eye", "flame" => "shared/icons/flame",
    "footprints" => "shared/icons/footprints", "ghost" => "shared/icons/ghost", "hand" => "shared/icons/hand",
    "leaf" => "shared/icons/leaf", "moon" => "shared/icons/moon", "moon_star" => "shared/icons/moon_star",
    "mountain" => "shared/icons/mountain", "pickaxe" => "shared/icons/pickaxe",
    "scroll_text" => "shared/icons/scroll_text", "shield" => "shared/icons/shield", "skull" => "shared/icons/skull",
    "sparkles" => "shared/icons/sparkles", "sun" => "shared/icons/sun", "swords" => "shared/icons/swords",
    "user_round" => "shared/icons/user_round", "venetian_mask" => "shared/icons/venetian_mask",
    "wand_sparkles" => "shared/icons/wand_sparkles", "wind" => "shared/icons/wind"
  }.freeze

  def self.keys
    PARTIALS.keys
  end

  def self.partial(key)
    PARTIALS[key]
  end
end
