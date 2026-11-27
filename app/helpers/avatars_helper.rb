# What a picker of an avatar shows and where it sends (shared/_avatar_picker): the account's, in Settings › Account,
# round like the avatar of the navigation; a character's, at the first step of its creation and on its page "Change",
# square like its picture on the sheet. Both send to the same address: PATCH a new picture, DELETE to remove it
module AvatarsHelper
  # The side of the square the page sends (avatar_cropper_controller.js): sharp up to 192 px on a fine screen
  AVATAR_OUTPUT_SIZE = 384

  # Round in the cropping window for an account, square for a character, as each is shown
  FRAME_SHAPE_CLASSES = { circle: "rounded-full", square: "rounded-2xl" }.freeze

  # Beside its buttons in the settings, above them in a narrow column (the page "Change" of a character), or a square
  # frame that is its own button (the step "Your hero" of the creation)
  PICKER_LAYOUT_CLASSES = { row: "flex items-center gap-4", column: "flex flex-col gap-3",
                            portrait: "flex flex-col items-start gap-3" }.freeze
  # What each layout draws beside the framing window (shared/_avatar_picker_body)
  PICKER_CONTROLS = { row: "shared/avatar_picker/controls", column: "shared/avatar_picker/controls",
                      portrait: "shared/avatar_picker/portrait" }.freeze
  # The layouts a character's picker may ask again when it sends a picture (Characters::AvatarsController)
  CHARACTER_PICKER_LAYOUTS = %i[column portrait].freeze

  # In the narrow column (128 px on a phone), the buttons keep their icon only: their name stays for screen readers
  # and in a tooltip
  PICKER_BUTTON_SIZES = { row: :compact, column: :compact_icon }.freeze
  PICKER_BUTTON_LABEL_CLASSES = { row: "", column: "sr-only" }.freeze

  def avatar_picker_button_classes(picker)
    button_classes(:secondary, size: PICKER_BUTTON_SIZES.fetch(picker[:layout]))
  end

  def avatar_picker_label_classes(picker)
    PICKER_BUTTON_LABEL_CLASSES.fetch(picker[:layout])
  end

  def account_avatar_picker(user, error: nil)
    { id: "account-avatar", url: settings_avatar_path, param: "user[avatar]", shape: :circle, layout: :row,
      attached: user.avatar.attached?, error: error,
      preview: render("shared/avatar", user: user, css_class: "size-20 text-xl") }
  end

  def character_avatar_picker(character, error: nil, layout: :column)
    { id: "character-avatar", url: character_avatar_address(character, layout), param: "character[avatar]",
      shape: :square, layout: layout, attached: character.avatar.attached?, error: error,
      preview: render("characters/avatar", character: character, css_class: "aspect-square w-full",
                                           icon_class: "size-10") }
  end

  # A draft by its table (it may not be saved yet: Characters::AvatarsController saves it), a complete one by itself.
  # The layout goes with it, for the picker the answer puts back
  def character_avatar_address(character, layout = :column)
    options = layout == :column ? {} : { layout: layout }
    if character.draft?
      game_table_character_avatar_path(character.game_table, options)
    else
      character_avatar_path(character, options)
    end
  end

  def avatar_choose_label(picker)
    t(picker[:attached] ? "shared.avatar_picker.change" : "shared.avatar_picker.choose")
  end
end
