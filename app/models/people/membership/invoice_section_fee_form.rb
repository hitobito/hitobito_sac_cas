class People::Membership::InvoiceSectionFeeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :section_id, :integer
  attribute :fee, :decimal

  validates :fee, presence: true

  attr_reader :section

  def initialize(section, attrs = {})
    super(attrs)
    @section = section
    self.section_id = section.id
  end

  def fee_type = :number
end
