require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17

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
    @win = "<strong>#{session[:player_name]} wins!!</strong> #{msg}"
    @show_buttons = false
    @play_again = true
  end

  def lose(msg)
    @win = "<strong>#{session[:player_name]} lose... Sorry...</strong> #{msg}"
    @show_buttons = false
    @play_again = true
  end

  def tie(msg)
    @win = "<strong>Tie game!!</strong> #{msg}"
    @show_buttons = false
    @play_again = true
  end
end

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
  erb :game
end 

post '/game/player/stay' do
  redirect '/game/dealer_turn'
end 

get '/game/dealer_turn' do
  session[:turn] = "dealer"
  
  @win= "#{session[:player_name]} has chosen to stay."

  @show_buttons = false

  total = hand_sum(session[:dealer_cards]) 

  if total == BLACKJACK_AMOUNT
    lose("Dealer hit blackjack.")
  elsif total > BLACKJACK_AMOUNT
    win("Dealer is busted, he's total is #{total}, bigger than 21")
  elsif total > DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @dealer_turn  = true
  end
  
  erb :game
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

  erb :game
end

get '/game_over' do
  erb :game_over
end