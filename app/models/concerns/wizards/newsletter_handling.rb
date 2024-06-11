module Wizards
  module NewsletterHandling
    extend ActiveSupport::Concern

    def save!
      super
      exclude_from_mailing_list if mailing_list && optout_newsletter?
    end

    private

    def exclude_from_mailing_list
      mailing_list.subscriptions.create!(subscriber: person, excluded: true)
    end

    def mailing_list
      @mailing_list ||= MailingList.find_by(id: Group.root.sac_newsletter_mailing_list_id)
    end
  end
end
