require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
BLACKJACK_BETTING_AMOUNT = 500

helpers do
  def hand_sum(cards) 
    aux = cards.map{|value| value[1]} 
    sum = 0

    aux.each  do |v|
      if v == 'ace'
        sum += 11
      else
        sum += v.to_i == 0? 10 : v.to_i
      end
    end   

    aux.select{|v| v == 'ace'}.count.times do
      if sum > BLACKJACK_AMOUNT 
        sum -= 10
      end
    end
    sum
  end

  def card_image(card)
    card_name = card[0] + '_' + card[1] + '.jpg'
    route = "<img src= '/images/cards/#{card_name}' class = 'card_image'>"
    route
  end

  def win(msg)
    session[:amount] += session[:player_bet]
    @winner = "<strong>#{session[:player_name]} wins!! </strong> #{msg} <br/> #{session[:player_name]} has #{session[:amount]} chips!"
    @show_buttons = false
    @play_again = true
  end

  def lose(msg)
    session[:amount] -= session[:player_bet]
    @show_buttons = false
    msg = "<strong>#{session[:player_name]} lose... </strong> #{msg}"

    if session[:amount] > 0 
      msg += "<br/> #{session[:player_name]}'s chip amount is #{session[:amount]}"
      @play_again = true
    else
      msg += "<br/> #{session[:player_name]} has no more chips to bet with, sorry..."
    end
    @loser = msg
  end

  def tie(msg)
    @winner = "<strong>Tie game!!</strong> <br/>  #{session[:player_name]}'s chip amount is still #{session[:amount]}#{msg}"
    @show_buttons = false
    @play_again = true
  end

  def check_int(str)
    Integer(foo) rescue nil
  end
end

#End of helpers


before do
  @show_buttons = true
end

get '/' do 
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do 
  erb :new_player
end

post '/new_player' do 
  if params[:player_name].empty?
    @error = "Name is required."
    halt erb(:new_player)
  end
  session[:player_name] = params[:player_name]
  session[:amount] = BLACKJACK_BETTING_AMOUNT

  redirect '/player_bet' 
end

get '/player_bet' do
  erb :player_bet
end 
  
post '/player_bet' do
  if params[:bet].empty? 
    @error = "Please enter a bet."
  elsif params[:bet].to_i  > session[:amount] 
    @error = "The bet can not exceed player's chip amount."
  elsif check_int(params[:bet]) == nil
    @error =  "Please, type only numbers."
  end

  session[:player_bet] = params[:bet].to_i

  redirect '/game'
end 

get '/game' do 
  session[:turn] = session[:player_name]

  suits = ["spades", "clubs", "diamonds", "hearts"]
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'jack', 'queen', 'king', 'ace']
  
  session[:deck] = suits.product(values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []

  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  total = hand_sum(session[:player_cards])

  if total == BLACKJACK_AMOUNT
    win("#{session[:player_name]} hit blackjack!!!")    
  elsif total > BLACKJACK_AMOUNT 
    lose("#{session[:player_name]}'s hand total is #{total}, bigger than 21.")
  end
  erb :game, layout: false
end 

post '/game/player/stay' do
  redirect '/game/dealer_turn'
end 

get '/game/dealer_turn' do
  session[:turn] = "dealer"
  
  @winner= "#{session[:player_name]} has chosen to stay."

  @show_buttons = false

  total = hand_sum(session[:dealer_cards]) 

  if total == BLACKJACK_AMOUNT
    lose("Dealer hit blackjack.")
  elsif total > BLACKJACK_AMOUNT
    win("Dealer is busted. Dealer's total is #{total}, bigger than 21")
  elsif total > DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @dealer_turn  = true
  end
  
  erb :game, layout: false
end

post '/game/player/dealer_turn/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer_turn'
end

get '/game/compare' do
  dealer_total = hand_sum(session[:dealer_cards]) 
  player_total = hand_sum(session[:player_cards]) 
  
  if player_total > dealer_total
    win("#{session[:player_name]}'s total is #{player_total}, and dealer's total is #{dealer_total}")
  elsif player_total < dealer_total
    lose("#{session[:player_name]}'s total is #{player_total}, and dealer's total is #{dealer_total}.")
  else
    tie("#{session[:player_name]}'s total is #{player_total}, and dealer's total is #{dealer_total}.") 
  end

  erb :game, layout: false
end

get '/game_over' do
  erb :game_over
end