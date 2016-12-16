require 'rails_helper'

RSpec.describe Common, :type => :model do

  after do
    # Set currency back to normal
    Settings.currency = "usd"
    Rails.cache.delete("rails_settings_cached:currency")
  end

  def build_common(**kwargs)
    kwargs[:series] = Series.new(value: "A") unless kwargs.has_key? :series

    common = Common.new(name: "A Customer", identification: "123456789Z", **kwargs)
    common.set_amounts
    common
  end

  def new_common
    tax1 = Tax.new(value: 10)
    tax2 = Tax.new(value: 40)
    item1 = Item.new(quantity: 1, unitary_cost: 0.09, taxes: [tax1])
    item2 = Item.new(quantity: 1, unitary_cost: 0.09, taxes: [tax1, tax2])

    build_common(items: [item1, item2])
  end

  it "is not valid without a series" do
    c = build_common(series: nil)
    expect(c).not_to be_valid
    expect(c.errors.messages.has_key? :series).to be true
  end

  it "is not valid with bad e-mails" do
    c = build_common(email: "paquito")

    expect(c).not_to be_valid
    expect(c.errors.messages.length).to eq 1
    expect(c.errors.messages.has_key? :email).to be true

    c.email = "paquito@example"

    expect(c).not_to be_valid
    expect(c.errors.messages.length).to eq 1
    expect(c.errors.messages.has_key? :email).to be true
  end

  it "round total taxes according to currency" do
    c = new_common
    expect(c.tax_amount).to eq 0.06

    # BHD Bahrain Dinar has 3 decimals
    Settings.currency = "bhd"
    Rails.cache.delete("rails_settings_cached:currency")
    expect(c.tax_amount).to eq 0.054
  end

  it "has right totals after set_amounts" do
    c = new_common
    c.set_amounts
    expect(c.gross_amount).to eq 0.24
    expect(c.net_amount).to eq 0.18

    # BHD Bahrain Dinar has 3 decimals
    Settings.currency = "bhd"
    Rails.cache.delete("rails_settings_cached:currency")
    c.set_amounts
    expect(c.gross_amount).to eq 0.234
    expect(c.net_amount).to eq 0.18
  end

end
