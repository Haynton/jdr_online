# The icons an option of a list may show on its card (a list declares them: icons, { option => key }): the emblems of
# the classes, of the backgrounds. Chosen among the icons of the app (shared/icons, Lucide), by a key the template
# writes; the page draws the partial of the key (CharacterSheets::OptionCardsHelper). A new icon: its partial, its line
module OptionIcons
  PARTIALS = {
    "castle" => "shared/icons/castle", "crown" => "shared/icons/crown", "dices" => "shared/icons/dices",
    "eye" => "shared/icons/eye", "flame" => "shared/icons/flame", "ghost" => "shared/icons/ghost",
    "hand" => "shared/icons/hand", "moon" => "shared/icons/moon", "moon_star" => "shared/icons/moon_star",
    "scroll_text" => "shared/icons/scroll_text", "shield" => "shared/icons/shield", "skull" => "shared/icons/skull",
    "sparkles" => "shared/icons/sparkles", "sun" => "shared/icons/sun", "swords" => "shared/icons/swords",
    "wand_sparkles" => "shared/icons/wand_sparkles"
  }.freeze

  def self.keys
    PARTIALS.keys
  end

  def self.partial(key)
    PARTIALS[key]
  end
end
