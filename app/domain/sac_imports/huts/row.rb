module SacImports::Huts
  class Row
    attr_reader :row, :csv_report, :output

    def initialize(row, csv_report:, output: $stdout)
      @row = row
      @csv_report = csv_report
      @output = output
    end

    def can_process?
      false
    end

    def related_navision_id = row[:related_navision_id].to_s.sub(/^[0]*/, "")

    def contact_navision_id = row[:contact_navision_id].to_s.sub(/^[0]*/, "")
  end
end
