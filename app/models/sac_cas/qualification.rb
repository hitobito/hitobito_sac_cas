
module SacCas::Qualification
  extend ActiveSupport::Concern

  included do
    before_validation :set_finish_at, unless: :finish_at
  end

end
