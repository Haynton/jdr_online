# A field where a username is typed, with usernames suggested by the server while typing
# (username_suggestions_controller.js, in a <datalist>): inviting a player to a table, adding a friend
module UsernameSuggestionsHelper
  # minimum_length: 0 asks as soon as the field gets the focus (the friends of the game master, suggested first)
  def username_suggestions_data(url, minimum_length: UsernameSuggester::MINIMUM_TYPED_LENGTH)
    { controller: "username-suggestions",
      username_suggestions_url_value: url,
      username_suggestions_minimum_length_value: minimum_length }
  end

  # autocomplete off: the browser's own memory of typed values would mix with the suggestions of the app
  def username_suggestions_input_options(list_id)
    { autocomplete: "off", list: list_id,
      data: { username_suggestions_target: "input",
              action: "focus->username-suggestions#suggest input->username-suggestions#suggest" } }
  end
end
