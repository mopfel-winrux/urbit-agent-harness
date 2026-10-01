export async function chooseOption(control, value) {
  control = control.and(control.page().getByRole('combobox'))
  await control.click()
  const list = control.page().locator(`[id=${JSON.stringify(await control.getAttribute('aria-controls'))}]`)
  await list.locator(`[role="option"][data-value=${JSON.stringify(String(value))}]`).click()
}
