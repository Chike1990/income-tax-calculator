# NZ Income Tax Calculator for individual
The solution helps estimate a person's annual income tax by applying each IRD rate only to the part of their
income that falls inside that bracket.

## How to run it
```bash
bundle install
bundle exec rspec
bin/rails server
```

```bash
curl -s -X POST localhost:3000/tax_estimates \
  -H "Content-Type: application/json" -d '{"income":"59000"}'
```

```json
{
  "income": "59000.00",
  "tax": "9920.50",
  "rates_effective_from": "2025-04-01",
  "breakdown": [
    { "from": "0.00",     "to": "15600.00", "rate": "10.5%", "taxable_income": "15600.00", "tax": "1638.00" },
    { "from": "15600.00", "to": "53500.00", "rate": "17.5%", "taxable_income": "37900.00", "tax": "6632.50" },
    { "from": "53500.00", "to": "78100.00", "rate": "30.0%", "taxable_income": "5500.00",  "tax": "1650.00" }
  ]
}
```
Bad input returns `422` and says what was wrong: `income is required`,
`income can't be negative`, or `income must be an amount like 59000 or 59000.50`.

## Where to look (files)
Below are the major files in the order a request passes through them:
 - `app/controllers/tax_estimates_controller.rb` Takes care of thje HTTP. Cleans the input, and rejects what isn't an amount, and shapes the JSON.
 - `config/tax_rates.yml` The IRD brackets, with the date they take effect. This is file we want to edit when rates change.
 -  `app/models/tax_rate_schedule.rb` Reads that file and picks the schedule in force on a given date. Plain Ruby, not Active Record; nothing is stored.
 -  `app/services/income_tax_calculator.rb` The calculation. Takes brackets and an income, returns the tax and a line per bracket. 
 - `spec/services` mirrors the split approach and covers the maths, including the brief's five
cases, cents, and both sides of the bracket thresholds while `spec/models` covers picking the
right schedule when rates change. `spec/request` covers the endpoint.

## Assumptions I have worked with
I emailed these to Megan before starting and was told to go ahead with them.
1. **Interface**: an API is enough; no web UI in the time available. It returns a
   per-bracket breakdown so support person can walk a customer through the number.
2. **Input**: annual taxable income, after expenses. Cents accepted. Negatives are
   rejected rather than returning a negative tax, since a loss isn't a refund.
3. **Scope**: income tax only. ACC earners' levy, student loan and KiwiSaver are out,
   but each could be added later as its own component.
4. **Tax years**: current rates only (from 1 April 2025), held as data with an effective
   date so other years can be added without a code change. Annual tax is on total income.
5. **The current calculator**: confirmed it's hypothetical, so the tests target what the
   brief's table proves: each rate applied to its own bracket, not one rate on the lot.

## Design decisions
- **Used `BigDecimal` everywhere**, parsed from strings to money never touches `Float`.
- **Treated rates as data**, not code: `config/tax_rates.yml` as pa the IRD page, and each
  schedule carries the date it takes effect. A rate change would require just an edit.
- **Chose `POST` over `GET`**: someone's income shouldn't sit in a URL, a log, or browser history.
- **Money as strings** in the JSON. This because JSON numbers are floats and cents would drift and messs the calculation.
- No web UI for now.
- 