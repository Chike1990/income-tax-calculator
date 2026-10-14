require "rails_helper"

RSpec.describe "POST /tax_estimates", type: :request do
  def post_income(income) = post "/tax_estimates", params: { income: }, as: :json
  def json = response.parsed_body

  { 10_000 => "1050.00", 35_000 => "5033.00", 59_000 => "9920.50",
    100_000 => "22877.50", 220_000 => "64877.50" }.each do |income, expected|
    it "returns $#{expected} for $#{income}" do
      post_income(income)
      expect(response).to have_http_status(:ok)
      expect(json["tax"]).to eq(expected)
    end
  end

  it "accepts formatted input with cents" do
    post_income("$10,000.10")
    expect(json["tax"]).to eq("1050.01")
  end

  it "returns a per-band breakdown" do
    post_income(59_000)
    expect(json["rates_effective_from"]).to eq("2025-04-01")
    expect(json["breakdown"].map { |line| line["tax"] }).to eq(%w[1638.00 6632.50 1650.00])
    expect(json["breakdown"].map { |line| line["rate"] }).to eq(["10.5%", "17.5%", "30.0%"])
  end

  it "rejects negative income" do
    post_income(-1)
    expect(response).to have_http_status(:unprocessable_content)
    expect(json["error"]).to eq("income can't be negative")
  end

  it "rejects missing income" do
    post "/tax_estimates", params: {}, as: :json
    expect(response).to have_http_status(:unprocessable_content)
  end

  it "rejects non-numbers" do
    post_income("lots")
    expect(response).to have_http_status(:unprocessable_content)
  end
end