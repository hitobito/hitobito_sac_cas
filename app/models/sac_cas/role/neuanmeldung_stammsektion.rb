module SacCas::Role::NeuanmeldungStammsektion
  extend ActiveSupport::Concern

  included do
    after_commit :destroy_household, if: :family?, on: :destroy
  end

  def destroy_household
    Household.new(person).destroy
  end
end
