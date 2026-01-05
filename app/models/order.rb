class Order < ApplicationRecord
  include AASM

  attr_accessor :status_changed_by

  belongs_to :user
  belongs_to :farmer
  has_many :order_items, dependent: :destroy
  has_many :products, through: :order_items
  has_one :payment, dependent: :destroy
  has_many :order_transition_tokens, dependent: :destroy
  has_many :order_approval_tokens, dependent: :destroy

  enum :status,
       {
         pending: "pending",
         farmer_review: "farmer_review",
         confirmed: "confirmed",
         payment_pending: "payment_pending",
         completed: "completed",
         cancelled: "cancelled",
         rejected: "rejected"
       },
       default: :pending,
       validate: true

  validates :order_number, presence: true, uniqueness: true
  validates :total_amount, numericality: { greater_than_or_equal_to: 0 }
  validates :shipping_name, :shipping_phone, :shipping_address, presence: true

  before_validation :assign_order_number, on: :create
  before_validation :assign_timeout_at, on: :create
  before_update :record_status_change, if: :will_save_change_to_status?
  after_commit :enqueue_auto_processing, on: :create

  scope :recent, -> { order(created_at: :desc) }

  aasm column: :status, enum: true do
    state :pending, initial: true
    state :farmer_review, :confirmed, :payment_pending, :completed, :cancelled, :rejected

    event :submit_for_review do
      transitions from: :pending, to: :farmer_review
    end

    event :confirm_order do
      transitions from: :farmer_review, to: :confirmed
    end

    event :await_payment do
      transitions from: :confirmed, to: :payment_pending
    end

    event :complete_order do
      transitions from: :payment_pending, to: :completed
    end

    event :cancel_order do
      transitions from: %i[pending farmer_review confirmed payment_pending], to: :cancelled, after: :mark_cancelled_at
    end

    event :reject_order do
      transitions from: %i[pending farmer_review], to: :rejected
    end
  end

  def with_idempotency(token)
    raise ArgumentError, "token required" if token.blank?

    OrderTransitionToken.transaction do
      existing = order_transition_tokens.lock.find_by(token:)
      return :duplicate if existing

      order_transition_tokens.create!(token:, processed_at: Time.current)
      yield if block_given?
      :applied
    end
  end

  private

  def assign_order_number
    self.order_number ||= "ORD-#{Time.current.strftime('%Y%m%d')}-#{SecureRandom.hex(3).upcase}"
  end

  def assign_timeout_at
    self.timeout_at ||= 24.hours.from_now
  end

  def record_status_change
    self.status_history ||= []
    event_time = Time.current
    actor = status_changed_by

    status_history << {
      status: status,
      at: event_time,
      by_id: actor&.id,
      by_type: actor&.class&.name
    }

    self.last_status_changed_at = event_time
    self.last_status_changed_by_id = actor&.id
    self.last_status_changed_by_type = actor&.class&.name
  end

  def mark_cancelled_at
    self.cancelled_at ||= Time.current
  end

  def enqueue_auto_processing
    return unless farmer&.approval_mode == "auto"

    OrderAutoProcessWorker.perform_async(id)
  rescue StandardError => e
    Rails.logger.warn("[Order] Failed to enqueue auto processing for order #{id}: #{e.message}")
  end
end
