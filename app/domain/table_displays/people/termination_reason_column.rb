module TableDisplays::People
  class TerminationReasonColumn < TerminationColumn
    def value(terminated_role)
      return if terminated_role.nil?

      terminated_role.termination_reason_text
    end
  end
end
