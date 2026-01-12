class People::Membership::InvoiceSectionFeeForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :section_id, :integer
  attribute :fee, :integer, default: 0

  attr_reader :section

  def initialize(section, attrs = {})
    super(attrs)
    @section = section
  end

  def fee_type = :number
end
