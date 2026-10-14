# A set of tax brackets that applies from a given date. 
# Just plain ruby, no ActiveRecord or database involved. The data is loaded from config/tax_rates.yml.
class TaxRateSchedule
  Bracket = Data.define(:lower, :upper, :rate)   # upper nil = no limit
  class NotFound < StandardError; end

  DEFAULT_PATH = Rails.root.join("config/tax_rates.yml")

  attr_reader :effective_from, :brackets

  # The latest schedule that started on or before `date`
  def self.for(date, path: DEFAULT_PATH)
    schedules = YAML.load_file(path).map { |data| new(data) }
    schedules.select { |s| s.effective_from <= date }.max_by(&:effective_from) or
      raise NotFound, "No tax rates for #{date}"
  end

  def initialize(data)
    @effective_from = Date.parse(data.fetch("effective_from"))
    lower = BigDecimal("0")
    @brackets = data.fetch("brackets").map do |b|
      upper = b["up_to"] && BigDecimal(b["up_to"].to_s)
      bracket = Bracket.new(lower:, upper:, rate: BigDecimal(b.fetch("rate")))
      lower = upper
      bracket
    end
  end
end