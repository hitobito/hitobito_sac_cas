# frozen_string_literal: true

#  Copyright (c) 2024, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

require "spec_helper"

describe SacCas::CustomContent do
  subject { CustomContent.get(Event::CourseParticipationMailer::REJECT_APPLIED_PARTICIPATION) }

  let(:output) do
    subject.body_with_values("event-name" => "Example|Event", "event-link" => "example.com/event")
  end

  def trim(string)
    string.gsub(/^ +|\n/, "")
  end

  context "#body_with_values" do
    it "replaces all placeholders and markdown tables" do
      subject.body =
        "This is a markdown table:<br>" \
        "| Name       | Link         |<br>" \
        "| ---------- | ------------ |<br>" \
        "| Event-Name | {event-name} |<br>" \
        "| Event-Link | {event-link} |<br>" \
        "Here is another one:<br>" \
        "| Name       | Link         |<br>" \
        "| ---------- | ------------ |<br>" \
        "| Event-Name | Eventus      |<br>"

      expect(output).to include(trim(
        "This is a markdown table:<br>\n" \
        "<table>\n" \
        "  <thead>\n" \
        "    <tr>\n" \
        "      <th>Name</th>\n" \
        "      <th>Link</th>\n" \
        "    </tr>\n" \
        "  </thead>\n" \
        "  <tbody>\n" \
        "    <tr>\n" \
        "      <td>Event-Name</td>\n" \
        "      <td>Example|Event</td>\n" \
        "    </tr>\n" \
        "    <tr>\n" \
        "      <td>Event-Link</td>\n" \
        "      <td>example.com/event</td>\n" \
        "    </tr>\n" \
        "  </tbody>\n" \
        "</table>\n" \
        "Here is another one:<br>\n" \
        "<table>\n" \
        "  <thead>\n" \
        "    <tr>\n" \
        "      <th>Name</th>\n" \
        "      <th>Link</th>\n" \
        "    </tr>\n" \
        "  </thead>\n" \
        "  <tbody>\n" \
        "    <tr>\n" \
        "      <td>Event-Name</td>\n" \
        "      <td>Eventus</td>\n" \
        "    </tr>\n" \
        "  </tbody>\n" \
        "</table>"
      ))
    end

    it "replaces markdown tables with empty fields" do
      subject.body =
        "| Name | Link |<br>" \
        "| - | - |<br>" \
        "| | {event-name} |<br>"

      expect(output).to include(trim(
        "<table>\n" \
        "  <thead>\n" \
        "    <tr>\n" \
        "      <th>Name</th>\n" \
        "      <th>Link</th>\n" \
        "    </tr>\n" \
        "  </thead>\n" \
        "  <tbody>\n" \
        "    <tr>\n" \
        "      <td></td>\n" \
        "      <td>Example|Event</td>\n" \
        "    </tr>\n" \
        "  </tbody>\n" \
        "</table>"
      ))
    end

    it "replaces markdown tables with single column" do
      subject.body =
        "| Link         |<br>" \
        "| ------------ |<br>" \
        "| {event-name} |<br>"

      expect(output).to include(trim(
        "<table>\n" \
        "  <thead>\n" \
        "    <tr>\n" \
        "      <th>Link</th>\n" \
        "    </tr>\n" \
        "  </thead>\n" \
        "  <tbody>\n" \
        "    <tr>\n" \
        "      <td>Example|Event</td>\n" \
        "    </tr>\n" \
        "  </tbody>\n" \
        "</table>"
      ))
    end

    it "partially replaces incomplete markdown tables" do
      subject.body =
        "| Name       | Link         |<br>" \
        "| ---------- | ------------ |<br>" \
        "| Event-Name | {event-name}<br>"

      expect(output).to include(trim(
        "<table>\n" \
        "  <thead>\n" \
        "    <tr>\n" \
        "      <th>Name</th>\n" \
        "      <th>Link</th>\n" \
        "    </tr>\n" \
        "  </thead>\n" \
        "  <tbody></tbody>\n" \
        "</table>\n" \
        "| Event-Name | Example|Event" \
      ))
    end

    it "doesn't replace markdown tables with missing header" do
      subject.body =
        "| Name       | Link         |<br>" \
        "| Event-Name | {event-name} |<br>"

      expect(output).to include("| Event-Name | Example|Event |")
      expect(output).not_to include("<table>")
    end
  end

  context ".init_section_specific_contents" do
    let(:group) { groups(:bluemlisalp) }

    it "initializes contents for section, keeping existing contents" do
      existing = group.custom_contents.create!(
        key: :event_tour_publication,
        label: "Tour: E-Mail Publi",
        subject: "Publikation der Tour",
        placeholders_optional: "recipient-first-name, recipient-last-name",
        body: "Tour wurde publiziert"
      )

      expect { CustomContent.init_section_specific_contents(group) }
        .to change { group.custom_contents.count }.by(15)

      # updated values
      expect(existing.reload.label).to eq("Tour: E-Mail Publikation")
      expect(existing.placeholders_optional.split("\n").size).to eq(1)
      # unchanged values
      expect(existing.subject).to eq("Publikation der Tour")
      expect(existing.body.body.to_s).to include("Tour wurde publiziert")

      created = group.custom_contents.find_by(key: :event_tour_subito_publication)
      expect(created.reload.label).to eq("Tour: E-Mail Publikation (Subito)")
      expect(created.placeholders_optional.split(",").size).to be >= 15
      expect(created.subject).to eq("Publikation der Subito-Tour {event-name}")
      br_count = created.body.body.to_s.split("<br>").size
      br2_count = created.body.body.to_s.split("<br><br>").size
      expect(br_count).to be >= 20
      expect(br2_count).to be < br_count
    end
  end
end
