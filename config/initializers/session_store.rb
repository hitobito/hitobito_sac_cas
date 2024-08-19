# Copied from core
#
# We set the same_site: :lax option to allow interaction for links from sac website
Hitobito::Application.config.session_store :active_record_store, same_site: :lax
