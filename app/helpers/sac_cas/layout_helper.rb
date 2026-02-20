module SacCas::LayoutHelper
  def render_sheets?
    return true if current_person&.basic_permissions_only? && controller.is_a?(Event::ParticipationsController)

    super
  end
end
