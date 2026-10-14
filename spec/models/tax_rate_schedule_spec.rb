require "rails_helper"

RSpec.describe TaxRateSchedule do
  it "loads the current IRD brackets" do
    schedule = described_class.for(Date.new(2026, 10, 14))
    expect(schedule.effective_from).to eq(Date.new(2025, 4, 1))
    expect(schedule.brackets.size).to eq(5)
    expect(schedule.brackets[2].lower).to eq(53_500)   # each band starts where the last ended
    expect(schedule.brackets.last.upper).to be_nil      # top band has no limit
  end

  it "raises when no rates apply yet" do
    expect { described_class.for(Date.new(2020, 1, 1)) }.to raise_error(TaxRateSchedule::NotFound)
  end

  it "picks the latest schedule when rates change" do
    file = Tempfile.new(["rates", ".yml"])
    file.write(<<~YAML)
      - effective_from: "2025-04-01"
        brackets: [{ up_to: null, rate: "0.10" }]
      - effective_from: "2027-04-01"
        brackets: [{ up_to: null, rate: "0.20" }]
    YAML
    file.close

    expect(described_class.for(Date.new(2026, 1, 1), path: file.path).brackets.first.rate).to eq(BigDecimal("0.10"))
    expect(described_class.for(Date.new(2027, 5, 1), path: file.path).brackets.first.rate).to eq(BigDecimal("0.20"))
  end
end
