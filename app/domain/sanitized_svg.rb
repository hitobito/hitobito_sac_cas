# frozen_string_literal: true

#  Copyright (c) 2026, Schweizer Alpen-Club. This file is part of
#  hitobito_sac_cas and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_sac_cas.

# An uploaded svg, sanitized for XSS issues so that it can be inlined into a page.
#
# Inlining is the only way to display an uploaded svg at all: Active Storage
# never serves one by URL other than as a download (it is in
# ActiveStorage.content_types_to_serve_as_binary, because an svg fetched by URL
# is a document that may run scripts).
class SanitizedSvg
  XMLNS = "http://www.w3.org/2000/svg"
  CURRENT_COLOR = "currentColor"

  SAFE_ELEMENTS = %w[svg g title desc path circle ellipse line polyline polygon rect].freeze

  SAFE_ATTRIBUTES = %w[
    viewBox preserveAspectRatio transform
    d points x y x1 y1 x2 y2 cx cy r rx ry width height
    fill fill-rule fill-opacity clip-rule opacity
    stroke stroke-width stroke-linecap stroke-linejoin stroke-miterlimit
    stroke-dasharray stroke-dashoffset stroke-opacity
  ].freeze

  COLOR_ATTRIBUTES = %w[fill stroke].freeze

  # A paint that names something defined elsewhere in the document, typically a
  # gradient. Those definitions do not survive, see ELEMENTS, and a shape whose
  # paint points at a missing one is not painted at all, so it falls back to the
  # surrounding colour.
  REFERENCE = /\Aurl\(/

  def initialize(data)
    @data = data
  end

  def to_svg(**attributes)
    root = document.root
    return unless root&.name == "svg"

    sanitize(root)
    root["xmlns"] = XMLNS
    root["fill"] ||= CURRENT_COLOR
    root["focusable"] = "false" # prevent focus in old Edge versions
    attributes.each { |name, value| root[name.to_s] = value.to_s if value.present? }
    root.to_xml
  end

  private

  # Namespaces are dropped so that traversal and the xmlns written back in
  # #to_svg are the same for every upload.
  def document
    @document ||= Nokogiri::XML(@data, &:nonet).tap(&:remove_namespaces!)
  end

  def sanitize(element)
    element.element_children.each do |child|
      SAFE_ELEMENTS.include?(child.name) ? sanitize(child) : child.remove
    end

    element.attribute_nodes.each { |attribute| sanitize_attribute(element, attribute) }
  end

  def sanitize_attribute(element, attribute)
    if SAFE_ATTRIBUTES.exclude?(attribute.name)
      attribute.remove
    elsif COLOR_ATTRIBUTES.include?(attribute.name) && attribute.value.match?(REFERENCE)
      element[attribute.name] = CURRENT_COLOR
    end
  end
end
