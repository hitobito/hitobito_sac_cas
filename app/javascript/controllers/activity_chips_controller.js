// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito_sac_cas and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito_sac_cas.

import { Controller } from "@hotwired/stimulus";

/*
  Companion controller for the Aktivitäten filter, attached alongside
  sac-cas--checkbox-filter on the same dropdown. Reveals an activity's
  linked technical-requirement chip while that activity is checked, and
  keeps each chip's hidden checkbox (which carries the actual
  technical_requirement_id[] form value) in sync with the chip's pressed
  state.

    data-controller="sac-cas--checkbox-filter sac-cas--activity-chips"
    data-sac-cas--activity-chips-target="activity"  (on every activity checkbox)
    data-sac-cas--activity-chips-target="chipRow"   (row to reveal, tagged with data-activity-id)
    data-sac-cas--activity-chips-target="chip"      (the toggle button inside a chip row)
    data-action="change->sac-cas--activity-chips#toggleActivity"  (on every activity checkbox)
    data-action="click->sac-cas--activity-chips#toggleChip"       (on every chip button)
*/
export default class extends Controller {
  static targets = ["activity", "chipRow", "chip"];

  connect() {
    this.activityTargets.forEach((activity) => this.syncChipRow(activity));
  }

  toggleActivity(event) {
    this.syncChipRow(event.target);
  }

  toggleChip(event) {
    const chip = event.currentTarget;
    const pressed = chip.getAttribute("aria-pressed") === "true";

    chip.setAttribute("aria-pressed", String(!pressed));
    chip.classList.toggle("active", !pressed);
    chip.querySelector('input[type="checkbox"]').checked = !pressed;
  }

  syncChipRow(activityCheckbox) {
    const row = this.chipRowTargets.find((candidate) => candidate.dataset.activityId === activityCheckbox.value);
    if (!row) return;

    row.hidden = !activityCheckbox.checked;
    if (!activityCheckbox.checked) {
      row.querySelectorAll('[data-sac-cas--activity-chips-target="chip"]').forEach((chip) => this.deactivateChip(chip));
    }
  }

  deactivateChip(chip) {
    chip.setAttribute("aria-pressed", "false");
    chip.classList.remove("active");
    chip.querySelector('input[type="checkbox"]').checked = false;
  }
}
