# frozen_string_literal: true

#  Copyright (c) 2023, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

class Person::Filter::NeuanmeldungenList
  def initialize(layer_group, current_user)
    @layer_group = layer_group
    @current_user = current_user
  end

  def count
    Person::Filter::List.new(@layer_group,
      @current_user,
      filter_params).all_count
  end

  def name
    I18n.t("activerecord.attributes.role.class.kind.neuanmeldung.other")
  end

  def filter_params
    types = [
      Group::SektionsNeuanmeldungenNv::Neuanmeldung
    ]
    ids = types.collect(&:type_id).join(Person::Filter::Base::ID_URL_SEPARATOR)
    {
      name: name,
      range: "deep",
      filters: {role: {role_type_ids: ids}}
    }
  end
end
