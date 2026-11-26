# The money of a character (decision of 26 November: the five coins of the SRD, added or taken out by its player in
# the inventory of the game room, given by the game master): the number fields its template marks as a coin
# (currency: true), found by what they declare, never by their key. A coin never goes below 0 nor above the max of its
# field
module CharacterMoney
  extend ActiveSupport::Concern

  # The most of a coin without a max of its own
  MONEY_LIMIT = 1_000_000

  def currency_fields
    sheet_fields.select { |field| field["type"] == "number" && field["currency"] }
  end

  def currency_field(key)
    currency_fields.find { |field| field["key"] == key }
  end

  def coins_of(field)
    sheet.to_h[field["key"]].to_i
  end

  # amount: added when positive, taken out when negative. The error, nil once changed (not saved here)
  def change_money(field, amount)
    total = coins_of(field) + amount
    return :not_enough if total.negative?
    return :too_much if total > (field["max"] || MONEY_LIMIT)

    self.sheet = sheet.to_h.merge(field["key"] => total)
    nil
  end
end
