def calculation
  table = Hash.new{ |hash, key| hash[key] = Hash.new{0} }
  (1..@months).each do |number|
    table[number][:percent_pay] = @amount * @percent
    yield
    table[number][:left] = @amount
  end
  return table
end

class StandardLoan
  attr_reader :loan_pay, :amount, :months, :percent, :sum

  def initialize(amount, months, percent)
    @amount = amount.to_f
    @sum = @amount
    @months = months.to_f
    @loan_pay = @amount / @months
    @percent = percent.to_f / 1200.0
  end

  def calculate
    calculation {@amount -= @loan_pay}
  end
end

class AnnuityLoan
  attr_reader :monthly_pay, :amount, :percent, :months, :coefficient, :sum

  def initialize(amount, months, percent)
    @amount = amount.to_f
    @sum = @amount
    @percent = percent.to_f / 1200.0
    @months = months.to_f
    @coefficient = @percent * (1 + @percent) ** @months / ((1 + @percent) **
                                                                @months - 1)
    @monthly_pay = @coefficient * @amount
  end

  def calculate
    calculation {@amount -= (@monthly_pay - @amount * @percent)}
  end
end
