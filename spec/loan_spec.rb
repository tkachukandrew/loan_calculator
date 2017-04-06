require 'rack/test'
require 'rspec'
require 'capybara'
require 'capybara/dsl'
require 'capybara/poltergeist'
require 'phantomjs'
require 'factory_girl'
require_relative '../loan'

Capybara.register_driver :poltergeist do |app|
    Capybara::Poltergeist::Driver.new(app, :phantomjs => Phantomjs.path)
end
Capybara.app = Loan

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app() Loan end
end

RSpec.configure do|c|
  c.include RSpecMixin
  c.include Capybara::DSL
  c.include FactoryGirl::Syntax::Methods
  c.before(:suite) do
    FactoryGirl.find_definitions
  end
end

FactoryGirl.define do
  factory StandardLoan do
    amount { 1 + rand(1000000) }
    months { 1 + rand(100) }
    percent   { 1 + rand(100) }
    initialize_with { new(amount, months, percent) }
  end

  factory AnnuityLoan do
    amount { 1 + rand(1000000) }
    months { 1 + rand(100) }
    percent   { 1 + rand(100) }
    initialize_with { new(amount, months, percent) }
  end
end

describe "open pages" do
  include Rack::Test::Methods

  context "GET root route" do
    it "must access home page" do
      get '/'
      expect(last_response).to be_ok
    end
  end

  context "GET result route" do
    it "must not get result without parameters" do
      get '/result'
      expect(last_response.body).to include("You have entered incorrect parameters for calculation.")
    end

    it "must get result with parameters" do
      get'/result', loan: attributes_for(StandardLoan)
      expect(last_response.body).to include("Your result")
    end

    it "must not get result with incorrect amount" do
      get'/result', loan: {amount: 0000, percent: 10, months: 100}
      expect(last_response.body).to include("You have entered incorrect parameters for calculation.")
    end

    it "must not get result with incorrect percent" do
      get'/result', loan: {amount: 10000, percent: 0, months: 100}
      expect(last_response.body).to include("You have entered incorrect parameters for calculation.")
    end

    it "must not get result with incorrect months" do
      get'/result', loan: {amount: 10000, percent: 10, months: 00}
      expect(last_response.body).to include("You have entered incorrect parameters for calculation.")
    end

    it "must not get result with incorrect parameters" do
      get'/result', loan: {amount: 0000, percent: 0, months: 00}
      expect(last_response.body).to include("You have entered incorrect parameters for calculation.")
    end
  end

  context "visit root and fill a form" do
    it "must get result filling correct parameters" do
      visit '/'
      fill_in 'loan[amount]', with: attributes_for(AnnuityLoan)[:amount]
      fill_in 'loan[percent]', with: attributes_for(AnnuityLoan)[:percent]
      fill_in 'loan[months]', with: attributes_for(AnnuityLoan)[:months]
      click_button 'Calculate'
      page.should have_content('Your result')
    end
  end

  context "calculaying one more time after previos one" do
    it "must get root route after previous calculation and clicking button" do
      visit '/'
      fill_in 'loan[amount]', with: attributes_for(AnnuityLoan)[:amount]
      fill_in 'loan[percent]', with: attributes_for(AnnuityLoan)[:percent]
      fill_in 'loan[months]', with: attributes_for(AnnuityLoan)[:months]
      click_button 'Calculate'
      click_link 'Calculate one more time'
      page.should have_content('Enter Information to Proceed')
    end
  end
end

describe "inner work" do
  include Rack::Test::Methods

  context "annuity loan created" do
    let(:loan) {build(AnnuityLoan)}
    let(:temp) { loan.calculate }
    it "must return a hash after calculation" do
      expect(temp.class.name).to eq('Hash')
    end
    it "must create a hash of months length" do
      expect(temp.length).to eq(loan.months)
    end
    it "must return a hash with value of percent_pay" do
      expect(temp[loan.months][:percent_pay]).to_not eq(nil)
    end
    it "must return a hash with value of left" do
      expect(temp[loan.months][:left]).to_not eq(nil)
    end
    it "must calculate monthly_pay" do
      expect(loan.monthly_pay).to eq(loan.sum * (loan.percent *
                                                (1 + loan.percent) **
                                                loan.months / ((1 +
                                                loan.percent) **
                                                loan.months - 1)))
    end
    it "must have equal amount and sum of loan payments" do
      total = 0
      temp.each do |key, value|
        total += (loan.monthly_pay - value[:percent_pay])
      end
      expect(total.round(2)).to eq(loan.sum)
    end
  end

  context "standard loan created" do
    let(:loan) {build(StandardLoan)}
    let(:temp) { loan.calculate }
    it "must return a hash after calculation" do
      expect(temp.class.name).to eq('Hash')
    end
    it "must create a hash of months length" do
      expect(temp.length).to eq(loan.months)
    end
    it "must return a hash with value of percent_pay" do
      expect(temp[loan.months][:percent_pay]).to_not eq(nil)
    end
    it "must return a hash with value of left" do
      expect(temp[loan.months][:left]).to_not eq(nil)
    end
    it "must calculate loan_pay" do
      expect(loan.loan_pay).to eq(loan.sum / loan.months)
    end
    it "must have equal amount and sum of loan payments" do
      total = loan.loan_pay * loan.months
      expect(total.round(2)).to eq(loan.sum)
    end
  end
end
