// Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito_sac_cas

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["checkbox"];

  toggle(event) {
    if (event.target.checked) {
      this.checkPrevious(event.target);
    } else {
      this.uncheckFollowing(event.target);
    }
  }

  checkPrevious(checkbox) {
    let after = false;
    this.checkboxTargets.forEach((box) => {
      if (box == checkbox) after = true;
      if (!after && !box.disabled) {
        box.checked = true;
      }
    });
  }

  uncheckFollowing(checkbox) {
    let after = false;
    this.checkboxTargets.forEach((box) => {
      if (after && !box.disabled) {
        box.checked = false;
      }
      if (box == checkbox) after = true;
    });
  }
}
