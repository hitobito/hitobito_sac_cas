// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito_sac_cas.

import { Controller } from "@hotwired/stimulus";

/*
  Powers a dropdown filter built from plain checkboxes: keeps the trigger
  button's selected-count badge (and accessible label) in sync, and lets a
  "Zurücksetzen" link clear just this filter and re-submit the form.

  Optionally supports one level of parent/child nesting - wrap each group in
  a <fieldset> and tag the group's own checkbox as a "parent" target - to
  let a parent checkbox select/clear all its children, with indeterminate
  feedback while only some are checked. Filters without any parent target
  (a plain flat checkbox list) simply skip that behaviour.

    data-controller="sac-cas--checkbox-filter"
    data-sac-cas--checkbox-filter-target="option"   (on every real filter value checkbox)
    data-sac-cas--checkbox-filter-target="parent"   (on a group's own checkbox, optional)
    data-sac-cas--checkbox-filter-target="counter"  (badge showing the selected count)
    data-sac-cas--checkbox-filter-target="resetLink"
    data-action="change->sac-cas--checkbox-filter#toggleOption"  (on every option)
    data-action="change->sac-cas--checkbox-filter#toggleParent"  (on every parent)
    data-action="click->sac-cas--checkbox-filter#reset"          (on the reset link)
*/
export default class extends Controller {
  static targets = ["option", "parent", "counter", "resetLink"];

  connect() {
    this.parentTargets.forEach((parent) => this.refreshParent(parent.closest("fieldset")));
    this.updateCounter();
  }

  toggleOption(event) {
    this.refreshParent(event.target.closest("fieldset"));
    this.updateCounter();
  }

  toggleParent(event) {
    const parent = event.target;
    const checked = parent.checked;

    this.optionsIn(parent.closest("fieldset")).forEach((option) => {
      option.checked = checked;
      option.dispatchEvent(new Event("change", {bubbles: true}));
    });
    // Dispatching "change" above re-enters toggleOption for each option,
    // which recomputes (and can overwrite) this parent's own checked/
    // indeterminate state via refreshParent - restore the intended state
    // now that every option has its final value.
    parent.checked = checked;
    parent.indeterminate = false;
    this.updateCounter();
  }

  reset() {
    this.optionTargets.forEach((option) => {
      option.checked = false;
      option.dispatchEvent(new Event("change", {bubbles: true}));
    });
    this.parentTargets.forEach((parent) => this.refreshParent(parent.closest("fieldset")));
    this.updateCounter();
    this.element.closest("form").requestSubmit();
  }

  refreshParent(fieldset) {
    if (!fieldset) return;

    const parent = this.parentTargets.find((candidate) => fieldset.contains(candidate));
    const options = this.optionsIn(fieldset);
    if (!parent || options.length === 0) return;

    const checkedCount = options.filter((option) => option.checked).length;
    parent.checked = checkedCount === options.length;
    parent.indeterminate = checkedCount > 0 && checkedCount < options.length;
  }

  optionsIn(fieldset) {
    return this.optionTargets.filter((option) => fieldset.contains(option));
  }

  updateCounter() {
    const count = this.optionTargets.filter((option) => option.checked).length;

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = count;
      this.counterTarget.classList.toggle("d-none", count === 0);
    }
    if (this.hasResetLinkTarget) this.resetLinkTarget.classList.toggle("d-none", count === 0);
  }
}
