class CardComponent < ViewComponent::Base
  attr_reader :compact, :bordered, :html_options

  renders_one :header
  renders_one :body
  renders_one :footer

  def initialize(compact: false, bordered: true, **html_options)
    @compact = compact
    @bordered = bordered
    @html_options = html_options
  end

  def css_classes
    classes = ["card", "bg-base-100"]
    classes << "card-compact" if compact
    classes << "card-bordered" if bordered
    classes << "shadow-lg"
    classes << html_options[:class] if html_options[:class]
    classes.compact.join(" ")
  end
end
