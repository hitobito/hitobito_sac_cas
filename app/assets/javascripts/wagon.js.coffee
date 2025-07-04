-#  hitobito_pbs and licensed under the Affero General Public License version 3
-#  or later. See the COPYING file at the top-level directory or at
-#  https://github.com/hitobito/hitobito_sac_cas.

# We'd normally use stimulus but since this is very sac-specific behaviour
# and creating new stimulus controllers in wagons currently does not work we opted to use javascript
require './download_statistics.js'

-#  Handles conditional buttons when adding people to household during signup
document.addEventListener 'click', (e) ->
  if e.target.dataset['association'] not in ['housemates', 'members']
    return

  mates = document.querySelectorAll '.step-content.active .fields:not([style="display: none;"])'
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

    $('[data-forwarder-target=click]').click() # trigger aside reload
  else
    toggle '.next-as-single', false
    toggle '.next-as-family', true
    top_toolbar.classList.remove 'd-none'
