require "rails_helper"

RSpec.describe BadgeComponent, type: :component do
  it "defines colors for all order statuses" do
    statuses = %i[pending farmer_review confirmed payment_pending completed cancelled rejected]

    statuses.each do |status|
      config = described_class::STATUS_CONFIG[status]
      expect(config).not_to be_nil
      expect(config[:color]).to be_present
    end
  end
end
