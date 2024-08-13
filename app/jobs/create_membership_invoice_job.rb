class CreateMembershipInvoiceJob < BaseJob
  self.parameters = [:external_invoice_id, :date, :discount, :new_entry]

  def initialize(external_invoice_id, date, discount, new_entry)
    @external_invoice_id = external_invoice_id
    @date = date
    @discount = discount
    @new_entry = new_entry
  end

  def perform
    if membership_invoice.is_a?(Invoices::Abacus::MembershipInvoice)
      subject_interface.transmit(subject)
      external_invoice.update!(total: membership_invoice.total)
      sales_order_interface.create(sales_order(membership_invoice))
    end
  rescue => e
    handle_invoice_generation_error(e.message)
    raise e
  end

  private

  def handle_invoice_generation_error(message)
    external_invoice.update!(state: :error)
    HitobitoLogEntry.create!(
      message: message,
      level: :error,
      category: "rechnungen",
      subject: external_invoice
    )
  end

  def sales_order(membership_invoice)
    @sales_order ||= Invoices::Abacus::SalesOrder.new(
      external_invoice.reload,
      membership_invoice.positions,
      membership_invoice.additional_user_fields
    )
  end

  def external_invoice = @external_invoice ||= ExternalInvoice.find(@external_invoice_id)

  def membership_invoice = @membership_invoice ||= external_invoice.build_membership_invoice(@discount, @new_entry, @date)

  def subject = @subject ||= Invoices::Abacus::Subject.new(person)

  def sales_order_interface = @sales_order_interface ||= Invoices::Abacus::SalesOrderInterface.new(client)

  def subject_interface = @subject_interface ||= Invoices::Abacus::SubjectInterface.new(client)

  def client = @client ||= Invoices::Abacus::Client.new

  def person = @person ||= Person.with_membership_years("people.*", @date.beginning_of_year).find(external_invoice.person.id)
end
