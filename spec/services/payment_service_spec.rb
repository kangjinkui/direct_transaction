require "rails_helper"

RSpec.describe PaymentService, type: :service do
  let(:order) { create(:order, status: :confirmed, total_amount: 30_000) }

  describe "#report_transfer" do
    it "stores pending payment and moves order to payment_pending" do
      result = described_class.new(order).report_transfer(amount: 30_000, reference: "REF123")

      expect(result.status).to eq(:payment_pending)
      expect(order.reload.status).to eq("payment_pending")
      expect(result.payment.status).to eq("pending")
      expect(result.payment.amount).to eq(30_000)
      expect(result.payment.reference).to eq("REF123")
    end
  end

  describe "#verify!" do
    it "marks payment verified and completes the order" do
      service = described_class.new(order)
      service.report_transfer(amount: 30_000, reference: "REF123")

      result = service.verify!(verified_at: Time.current, admin_note: "확인 완료", verification_method: :phone_call)

      expect(result.status).to eq(:completed)
      expect(order.reload.status).to eq("completed")
      expect(result.payment.status).to eq("verified")
      expect(result.payment.admin_note).to eq("확인 완료")
      expect(result.payment.verification_method).to eq("phone_call")
      expect(result.payment.verified_at).to be_present
    end

    it "returns invalid_transition for wrong order state" do
      pending_order = create(:order, status: :pending)

      result = described_class.new(pending_order).verify!(verification_method: :phone_call)

      expect(result.status).to eq(:invalid_transition)
    end
  end
end
