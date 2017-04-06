require 'sinatra'
require_relative 'classes'

class Loan < Sinatra::Application
  get '/' do
    erb :index
  end

  get '/result' do
    if params.empty? || params[:loan][:amount].empty? |
                                  params[:loan][:months].empty? ||
                                  params[:loan][:percent].empty? ||
                                  params[:loan][:amount].to_f == 0.0 ||
                                  params[:loan][:months].to_f == 0.0 ||
                                  params[:loan][:percent].to_f == 0.0
      erb :error
    else
      if params[:loan][:type] == 'Standard'
        @loan = StandardLoan.new(params[:loan][:amount].to_f,
                                  params[:loan][:months].to_f,
                                  params[:loan][:percent].to_f)
      else
        @loan = AnnuityLoan.new(params[:loan][:amount].to_f,
                                params[:loan][:months].to_f,
                                params[:loan][:percent].to_f)
      end
      @hash = @loan.calculate
      erb :result
    end
  end

  run! if app_file == $0
end
