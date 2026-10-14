require "rails_helper"

RSpec.describe IncomeTaxCalculator do
  def bracket(lower, upper, rate)
    TaxRateSchedule::Bracket.new(lower: BigDecimal(lower), upper: upper && BigDecimal(upper), rate: BigDecimal(rate))
  end

  let(:brackets) do
    [bracket("0",      "15600",  "0.105"),
     bracket("15600",  "53500",  "0.175"),
     bracket("53500",  "78100",  "0.30"),
     bracket("78100",  "180000", "0.33"),
     bracket("180000", nil,      "0.39")]
  end
  subject(:calculator) { described_class.new(brackets) }

  def tax_for(amount) = calculator.call(BigDecimal(amount.to_s)).tax

  # The test cases from the brief
  {
    10_000  => "1050.00",
    35_000  => "5033.00",
    59_000  => "9920.50",
    100_000 => "22877.50",
    220_000 => "64877.50",
  }.each do |income, expected|
    it("taxes $#{income} as $#{expected}") { expect(tax_for(income)).to eq(BigDecimal(expected)) }
  end

  # a few new edge cases
  it("charges nothing on zero income")       { expect(tax_for(0)).to eq(0) }
  it("handles cents")                        { expect(tax_for("10000.10")).to eq(BigDecimal("1050.01")) }
  it("rejects negative income")              { expect { tax_for(-1) }.to raise_error(ArgumentError) }

  # The bracket edges checked on the breakdown too, since the total hides an empty band.
  { 53_500 => "8270.50", 78_100 => "15650.50" }.each do |income, expected|
    it("taxes $#{income} as $#{expected}") { expect(tax_for(income)).to eq(BigDecimal(expected)) }
  end

  it "stops at a threshold without opening the next band" do
    result = calculator.call(BigDecimal("15600"))
    expect(result.tax).to eq(BigDecimal("1638"))
    expect(result.lines.size).to eq(1) 
  end

  it "opens the next band one dollar past a threshold" do
    result = calculator.call(BigDecimal("15601"))
    expect(result.tax).to eq(BigDecimal("1638.18"))
    expect(result.lines.map(&:rate)).to eq([BigDecimal("0.105"), BigDecimal("0.175")])
  end

  it "charges 39% only on the dollars above the top threshold" do
    result = calculator.call(BigDecimal("180000"))
    expect(result.tax).to eq(BigDecimal("49277.50"))
    expect(result.lines.size).to eq(4)
    expect(tax_for(180_001)).to eq(BigDecimal("49277.89"))
  end

  it "returns a breakdown that adds up to the total" do
    result = calculator.call(BigDecimal("100000"))
    expect(result.lines.size).to eq(4)
    expect(result.lines.sum(&:tax)).to eq(result.tax)
  end
end