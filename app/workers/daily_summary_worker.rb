class DailySummaryWorker
  include Sidekiq::Worker

  sidekiq_options queue: :default, retry: 1

  def perform(date_string = nil)
    date = date_string.present? ? Date.parse(date_string) : Date.current
    DailySummaryService.new(date:).deliver!
  end
end
