# The registry of what a creation step may do beside asking fields (a setting of the step set to true in
# character_fields.creation_steps: "chooses_spells": true), fourth piece of the template editor (see CLAUDE.md). Each
# behavior is a class of app/models/creation_step_behaviors that says what it adds to the form of its step and to its
# block of the summary, and what it does when a step is saved: on its own step it keeps what was picked, on the other
# steps it drops what the class picked there no longer offers. A new behavior: its class, its line in ALL
module CreationStepBehaviors
  ALL = [
    CreationStepBehaviors::ChoosesEquipment, CreationStepBehaviors::ChoosesSpells,
    CreationStepBehaviors::ChoosesWeaponMasteries
  ].freeze

  def self.all
    @all ||= ALL.map(&:new)
  end

  def self.keys
    all.map(&:key)
  end

  # The behaviors a declared step turns on ({ "chooses_spells" => true })
  def self.of(declared_step)
    all.select { |behavior| declared_step[behavior.key] == true }
  end
end
