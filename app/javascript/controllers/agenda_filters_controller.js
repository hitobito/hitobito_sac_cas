// Copyright (c) 2026, Hitobito AG. This file is part of
// hitobito and licensed under the Affero General Public License version 3
// or later. See the COPYING file at the top-level directory or at
// https://github.com/hitobito/hitobito_sac_cas.

import { Controller } from "@hotwired/stimulus";

/*
  Resets every filter field in the form to its true blank state (not the
  server-rendered value the page loaded with) and re-submits, so the results
  turbo frame refreshes with an unfiltered list. A field can opt out of
  blanking via data-reset-value, e.g. the since date field resets to today
  rather than to empty (see agenda/_date_filters).

    data-controller="agenda-filters"
    data-action="click->agenda-filters#reset"
*/
export default class extends Controller {
  reset() {
    this.element.querySelectorAll('input[type="text"]').forEach((input) => {
      input.value = input.dataset.resetValue || "";
    });
    this.element.querySelectorAll('input[type="radio"]').forEach((radio) => {
      radio.checked = radio.value === "0";
    });
    this.element.querySelectorAll("select[data-controller~='tom-select']").forEach((select) => {
      if (select.tomselect) select.tomselect.clear();
    });
    this.element.requestSubmit();
  }
}
