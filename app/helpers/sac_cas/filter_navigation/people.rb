# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.
#
module SacCas::FilterNavigation::People

  def initialize(*args)
    super

    if group.root?
      member_list = Person::Filter::NeuanmeldungenList.new(group.layer_group, template.current_user)
      item(member_list.name, template.group_people_path, member_list.count)
    end
  end

end
