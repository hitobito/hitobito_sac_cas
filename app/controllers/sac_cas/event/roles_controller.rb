module SacCas::Event::RolesController
  extend ActiveSupport::Concern

  prepended do
    permitted_attrs << :self_employed
  end
end
