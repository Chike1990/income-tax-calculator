class TaxEstimatesController < ApplicationController
  class InvalidIncome < StandardError; end

  AMOUNT = /\A\d+(\.\d{1,2})?\z/   # digits, optionally up to 2 decimal places

  rescue_from InvalidIncome do |error|
    render json: { error: error.message }, status: :unprocessable_content
  end

  def create
    income   = parse_income(params[:income])
    schedule = TaxRateSchedule.for(Date.current)
    result   = IncomeTaxCalculator.new(schedule.brackets).call(income)

    render json: {
      income: money(result.income),
      tax: money(result.tax),
      rates_effective_from: schedule.effective_from.iso8601,
      breakdown: result.lines.map do |line|
        { from: money(line.lower),
          to: line.upper && money(line.upper),
          rate: percentage(line.rate),
          taxable_income: money(line.taxable_income),
          tax: money(line.tax) }
      end
    }
  end

  private

  def parse_income(raw)
    cleaned = raw.to_s.delete(",$ ")
    raise InvalidIncome, "income is required" if cleaned.empty?
    raise InvalidIncome, "income can't be negative" if cleaned.start_with?("-")
    raise InvalidIncome, "income must be an amount like 59000 or 59000.50" unless AMOUNT.match?(cleaned)
    BigDecimal(cleaned)
  end

  # Money is returned as a string ("9920.50") because JSON numbers are floats
  def money(amount)
    ActiveSupport::NumberHelper.number_to_rounded(amount, precision: 2)
  end


  def percentage(rate)
    ActiveSupport::NumberHelper.number_to_percentage(rate * 100, precision: 1)
  end
end
