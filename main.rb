require 'rubygems'
require 'sinatra'

set :sessions, true

get '/' do 
  "Hello world!! Good!!"
end

get '/first_sample' do 
  redirect '/'
end

get '/my_template' do 
  erb :my_template
end

get '/nested_template' do 
  erb :"users/nested_template"
end

get '/bootstrap' do 
  erb :bootstrap
end



