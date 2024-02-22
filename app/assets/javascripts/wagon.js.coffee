-#  hitobito_pbs and licensed under the Affero General Public License version 3
-#  or later. See the COPYING file at the top-level directory or at
-#  https://github.com/hitobito/hitobito_sac_cas.

document.addEventListener 'click', (e) ->
  if e.target.dataset['association'] != 'housemates'
    return

  mates = document.querySelectorAll '.household .fields:not([style="display: none;"])'
  top_toolbar = document.querySelector '.btn-toolbar.top'

  toggle = (selector, active) ->
    buttons = Array.from(document.querySelectorAll(selector))
    buttons.forEach (button) ->
      if active
        button.type = 'submit'
        button.classList.remove 'd-none'
      else
        button.type = button
        button.classList.add 'd-none'

  if mates.length == 0
    toggle '.next-as-single', true
    toggle '.next-as-family', false
    top_toolbar.classList.add 'd-none'
  else
    toggle '.next-as-single', false
    toggle '.next-as-family', true
    top_toolbar.classList.remove 'd-none'
