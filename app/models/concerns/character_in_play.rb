# What a player's character has and spends during the game, in the game room (decision of 26 November): its hit points
# and the values the game master adjusts (CharacterVitals), what it wears (CharacterEquipment), its money
# (CharacterMoney), its death saving throws (CharacterDeathSaves), the resources of its class (CharacterResources), its
# spell slots (CharacterSpellSlots), its hit dice (CharacterHitDice) and the levels it gains (CharacterLevels), each
# read in what the template declares
module CharacterInPlay
  extend ActiveSupport::Concern

  included do
    include CharacterVitals
    include CharacterEquipment
    include CharacterMoney
    include CharacterDeathSaves
    include CharacterResources
    include CharacterSpellSlots
    include CharacterHitDice
    include CharacterWeaponMasteries
    include CharacterClassChoices
    include CharacterLevels
  end
end
