// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import { Turbo } from "@hotwired/turbo-rails"
import "controllers"
import { confirmWithDialog } from "confirm_dialog"

// Every data-turbo-confirm question opens our own window (shared/_confirm_dialog), not the browser's
Turbo.config.forms.confirm = confirmWithDialog
