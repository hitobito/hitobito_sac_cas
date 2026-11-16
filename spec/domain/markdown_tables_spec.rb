# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe MarkdownTables do
  let(:output) { described_class.new(body.html_safe).to_html }

  def table(header, *rows)
    head = header.map { "<th>#{_1}</th>" }.join
    body = rows.map { |row| "<tr>#{row.map { "<td>#{_1}</td>" }.join}</tr>" }.join
    "<table><thead><tr>#{head}</tr></thead><tbody>#{body}</tbody></table>"
  end

  context "with rows separated by line breaks" do
    let(:body) { "<div>Intro<br>| A | B |<br>| --- | --- |<br>| x | y |<br>Outro</div>" }

    it "replaces only the rows" do
      expect(output).to eq "<div>Intro<br>#{table(%w[A B], %w[x y])}Outro</div>"
    end
  end

  context "with rows in separate blocks" do
    let(:body) do
      "<div>Intro</div>" \
        "<div>| | |</div>" \
        "<div>| ------------- | ------------- |</div>" \
        "<div>| Anmeldung bearbeiten:&nbsp; | {application-url} |</div>" \
        "<div>| Kursinformationen: | {event-details} |<br><br></div>" \
        "<div>Grüsse</div>"
    end

    it "renders a single table" do
      expect(output).to eq "<div>Intro</div><div>" +
        table(["", ""], ["Anmeldung bearbeiten:&nbsp;", "{application-url}"],
          ["Kursinformationen:", "{event-details}"]) +
        "<br></div><div>Grüsse</div>"
    end
  end

  context "with whitespace between blocks" do
    let(:body) { "<div>| A | B |</div>\n  <div>| --- | --- |</div>\n<div>| x | y |</div>" }

    it "renders a single table" do
      expect(output).to eq "<div>#{table(%w[A B], %w[x y])}</div>"
    end
  end

  context "with rows mixing line breaks and blocks" do
    let(:body) { "<div>| A | B |<br>| --- | --- |</div><div>| x | y |<br>| z | w |</div>" }

    it "renders a single table" do
      expect(output).to eq "<div>#{table(%w[A B], %w[x y], %w[z w])}</div>"
    end
  end

  context "with last row at the end of a block" do
    let(:body) { "<div>| A | B |<br>| --- | --- |<br>| x | y |</div>" }

    it "includes the last row" do
      expect(output).to eq "<div>#{table(%w[A B], %w[x y])}</div>"
    end
  end

  context "with line break inside formatting before the table" do
    let(:body) { "<div><strong>Kontaktperson<br></strong>| A | B |<br>| --- | --- |<br>| x | y |<br></div>" }

    it "renders the table" do
      expect(output).to eq "<div><strong>Kontaktperson<br></strong>#{table(%w[A B], %w[x y])}</div>"
    end
  end

  context "with spaces after the last pipe of a row" do
    let(:body) { "<div>| A | B | <br>| --- | --- |&nbsp;<br>| x | y |</div><div>| z | w | </div>" }

    it "renders all rows" do
      expect(output).to eq "<div>#{table(%w[A B], %w[x y], %w[z w])}</div>"
    end
  end

  context "with block ending in a pipe followed by a block without row" do
    let(:body) { "<div>Wahl: ja | nein |</div><div>Weiter</div>" }

    it "keeps the blocks separate" do
      expect(output).to eq body
    end
  end

  context "with empty cells" do
    let(:body) { "<div>| A | B |<br>| - | - |<br>| | y |<br></div>" }

    it "renders empty cells" do
      expect(output).to eq "<div>#{table(%w[A B], ["", "y"])}</div>"
    end
  end

  context "with single column" do
    let(:body) { "<div>| A |<br>| --- |<br>| x |<br></div>" }

    it "renders the table" do
      expect(output).to eq "<div>#{table(%w[A], %w[x])}</div>"
    end
  end

  context "with column alignment" do
    let(:body) { "<div>| L | C | R |<br>| :--- | :---: | ---: |<br>| x | y | z |<br></div>" }

    it "aligns the cells" do
      expect(output).to include(
        '<th style="text-align: left">L</th><th style="text-align: center">C</th>' \
          '<th style="text-align: right">R</th>',
        '<td style="text-align: left">x</td><td style="text-align: center">y</td>' \
          '<td style="text-align: right">z</td>'
      )
    end
  end

  context "with two tables" do
    let(:body) { "<div>| A |<br>| - |<br>| x |<br>Text<br>| B |<br>| - |<br>| y |<br></div>" }

    it "renders both" do
      expect(output).to eq "<div>#{table(%w[A], %w[x])}Text<br>#{table(%w[B], %w[y])}</div>"
    end
  end

  context "with row lacking the closing pipe" do
    let(:body) { "<div>| A | B |<br>| --- | --- |<br>| x | y<br></div>" }

    it "ends the table before that row" do
      expect(output).to eq "<div>#{table(%w[A B])}| x | y<br></div>"
    end
  end

  context "with formatted cell" do
    let(:body) { "<div>| A | B |<br>| --- | --- |<br>| x | y |<br>| <strong>z</strong> | w |<br></div>" }

    it "ends the table before that row" do
      expect(output).to eq "<div>#{table(%w[A B], %w[x y])}| <strong>z</strong> | w |<br></div>"
    end
  end

  context "with formatted header cell" do
    let(:body) { "<div>| <strong>A</strong> | B |<br>| --- | --- |<br>| x | y |<br></div>" }

    it "renders no table" do
      expect(output).to eq body
    end
  end

  context "with header row formatted as heading" do
    let(:body) { "<h1>| A | B |</h1><div>| --- | --- |</div><div>| x | y |</div>" }

    it "renders no table" do
      expect(output).to eq "<h1>| A | B |</h1><div>| --- | --- |<br>| x | y |</div>"
    end
  end

  context "with pipe rows lacking a delimiter row" do
    let(:body) { "<div>| not |<br>| a table |</div>" }

    it "keeps the text as is" do
      expect(output).to eq body
    end
  end

  context "with pipes in running text" do
    let(:body) do
      "<div>Siehe <a href=\"https://www.sac-cas.ch/de/inside/\">SAC Inside | Schweizer Alpen-Club SAC</a>" \
        "<br>Wahl: ja | nein |<br>| --- | --- |</div>"
    end

    it "keeps the text as is" do
      expect(output).to eq body
    end
  end
end
