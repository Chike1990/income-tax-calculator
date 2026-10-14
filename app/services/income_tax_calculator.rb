# Progressive income tax: each rate applies only to the slice of income inside its band.
class IncomeTaxCalculator
  Line   = Data.define(:lower, :upper, :rate, :taxable_income, :tax)
  Result = Data.define(:income, :tax, :lines)

  def initialize(brackets)
    @brackets = brackets
  end

  def call(income)
    raise ArgumentError, "income can't be negative" if income.negative?

    lines = @brackets.filter_map do |b|
      top = b.upper ? [income, b.upper].min : income
      taxable_income = top - b.lower
      next unless taxable_income.positive?
      Line.new(lower: b.lower, upper: b.upper, rate: b.rate, taxable_income:, tax: taxable_income * b.rate)
    end

    Result.new(income:, tax: lines.sum(BigDecimal("0"), &:tax).round(2, :half_up), lines:)
  end
end