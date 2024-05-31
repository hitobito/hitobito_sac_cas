module Groups::SacRegistrationWizards
  def self.for(group)
    case group
    when ::Group::AboBasicLogin
      ::Wizards::SignupBasicLogin
    when ::Group::AboMagazin
      raise 'reimplement wizard as in SelfRegistration::AboMagazin'
    when ::Group::AboTourenPortal
      raise 'reimplement wizard as in SelfRegistration::AboTourenPortal'
    when ::Group::SektionsNeuanmeldungenNv, Group::SektionsNeuanmeldungenSektion
      ::Wizards::MembershipOnboarding
    else
      raise "no wizard for group #{group.class}"
    end
  end
end
