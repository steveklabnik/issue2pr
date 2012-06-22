require 'sinatra'
require 'rack-flash'
require 'omniauth'

use Rack::Session::Cookie
use OmniAuth::Builder do
  provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
end

get '/' do
  <<-HTML
    <a href='/auth/github'>Sign in with GitHub</a>
  HTML
end

post '/auth/:name/callback' do
  auth = request.env['omniauth.auth']
  # do whatever you want with the information!
  #
end

get '/auth/failure' do
  flash[:notice] = params[:message] # if using sinatra-flash or rack-flash
  redirect '/'
end
