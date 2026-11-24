# Pin npm packages by running ./bin/importmap

pin "application"
pin "confirm_dialog"
pin "@hotwired/turbo-rails", to: "turbo.min.js"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin_all_from "app/javascript/computed_rules", under: "computed_rules"
pin_all_from "app/javascript/modifier_rules", under: "modifier_rules"
pin_all_from "app/javascript/choice_effects", under: "choice_effects"
pin_all_from "app/javascript/map_editor", under: "map_editor"
pin_all_from "app/javascript/map_floors", under: "map_floors"
pin_all_from "app/javascript/map_edges", under: "map_edges"
