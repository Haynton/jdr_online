// Answers the data-turbo-confirm questions with the window of shared/_confirm_dialog instead of the browser's own.
// Turbo waits for the promise: true sends the form, false leaves things as they are.
// Without that window on the page (a visitor page), the browser asks as before
export function confirmWithDialog(question, form, submitter) {
  const dialog = document.getElementById("confirm-dialog")
  if (!dialog) return Promise.resolve(window.confirm(question))

  prepare(dialog, question, settingsFrom(form, submitter))
  dialog.returnValue = ""
  dialog.showModal()

  return new Promise((resolve) => {
    dialog.addEventListener("close", () => resolve(dialog.returnValue === "confirm"), { once: true })
  })
}

// The button that was clicked (delete the account) or its form (log out) says how to confirm
function settingsFrom(form, submitter) {
  const source = submitter?.dataset.confirmButton ? submitter : form
  return { label: source.dataset.confirmButton, variant: source.dataset.confirmVariant }
}

function prepare(dialog, question, { label, variant }) {
  const confirmButton = dialog.querySelector("[data-confirm-dialog-button]")
  dialog.querySelector("#confirm-dialog-question").textContent = question
  confirmButton.textContent = label || dialog.dataset.defaultLabel
  confirmButton.className = variant === "danger" ? dialog.dataset.dangerClasses : dialog.dataset.primaryClasses
  closeOnBackdropClick(dialog)
}

// A click on the backdrop reaches the <dialog> itself, a click inside lands on its content: it answers no
function closeOnBackdropClick(dialog) {
  if (dialog.dataset.backdropListening) return

  dialog.dataset.backdropListening = "true"
  dialog.addEventListener("click", (event) => {
    if (event.target === dialog) dialog.close("cancel")
  })
}
