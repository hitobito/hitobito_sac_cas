module SacCas::LayoutHelper
  def render_sheets?
    if current_person&.basic_permissions_only? &&
        controller.is_a?(Event::ParticipationsController)
      return true
    end

    super
  end
end
