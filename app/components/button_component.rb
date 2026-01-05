class ButtonComponent < ViewComponent::Base
  attr_reader :variant, :size, :disabled, :loading, :type, :html_options

  VARIANTS = {
    primary: "btn-primary",
    secondary: "btn-secondary",
    danger: "btn-error",
    ghost: "btn-ghost",
    link: "btn-link"
  }.freeze

  SIZES = {
    xs: "btn-xs",
    sm: "btn-sm",
    md: "",
    lg: "btn-lg"
  }.freeze

  def initialize(variant: :primary, size: :md, disabled: false, loading: false, type: "button", **html_options)
    @variant = variant
    @size = size
    @disabled = disabled
    @loading = loading
    @type = type
    @html_options = html_options
  end

  def css_classes
    classes = ["btn", VARIANTS[variant], SIZES[size]]
    classes << "btn-disabled" if disabled
    classes << "loading" if loading
    classes << html_options[:class] if html_options[:class]
    classes.compact.join(" ")
  end

  def button_attributes
    attrs = html_options.except(:class).merge(
      type: type,
      class: css_classes
    )
    attrs[:disabled] = true if disabled || loading
    attrs[:aria] = (attrs[:aria] || {}).merge(
      disabled: (disabled || loading),
      busy: loading
    )
    attrs
  end
end
