module SacCas::Event::RolesController
  extend ActiveSupport::Concern

  prepended do
    self.permitted_attrs << :self_employed
  end
end