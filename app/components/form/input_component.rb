class Form::InputComponent < ViewComponent::Base
  attr_reader :form, :attribute, :input_type, :label, :placeholder, :required, :hint,
              :options, :include_blank, :html_options

  def initialize(form:, attribute:, input_type: :text, label: nil, placeholder: nil,
                 required: false, hint: nil, options: nil, include_blank: false, **html_options)
    @form = form
    @attribute = attribute
    @input_type = input_type
    @label = label
    @placeholder = placeholder
    @required = required
    @hint = hint
    @options = options
    @include_blank = include_blank
    @html_options = html_options
  end

  def input_css_classes
    classes = case input_type
              when :select
                ["select", "select-bordered", "w-full"]
              when :textarea
                ["textarea", "textarea-bordered", "w-full"]
              else
                ["input", "input-bordered", "w-full"]
              end
    classes << error_css_class if has_errors?
    classes << html_options[:class] if html_options[:class]
    classes.compact.join(" ")
  end

  def has_errors?
    form.object.errors[attribute].any?
  end

  def error_messages
    form.object.errors[attribute].join(", ")
  end

  def label_text
    text = label || attribute.to_s.humanize
    text += " *" if required
    text
  end

  def input_method
    return :text_area if input_type == :textarea
    return :select if input_type == :select

    field_method = "#{input_type}_field"
    form.respond_to?(field_method) ? field_method : :text_field
  end

  def error_css_class
    case input_type
    when :select
      "select-error"
    when :textarea
      "textarea-error"
    else
      "input-error"
    end
  end
end
