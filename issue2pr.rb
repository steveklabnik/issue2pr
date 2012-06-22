require 'bundler'
Bundler.require
require 'net/http'
require 'net/https'
require 'uri'

DB = Sequel.connect(ENV['DATABASE_URL'] || 'sqlite://db/development.db')
Sequel::Model.plugin(:schema)

class User < Sequel::Model
 set_schema do
    primary_key :id
    
    integer :uid

    varchar :nickname, :empty => false
    varchar :name, :empty => false
    timestamp :created_at
  end

  create_table unless table_exists?
end


class Issue2Pr < Sinatra::Base

  use Rack::Session::Cookie

  use OmniAuth::Builder do
    provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET']
  end

  helpers do
    def current_user
      @current_user ||= User[session[:user_id]] if session[:user_id]
    end
  end

  get '/' do
    if current_user
      current_user.id.to_s + " ... " + session[:user_id].to_s 
      <<-HTML
      <h1>ZOMG</h1>
      <form action="/transmute" method="POST">
        User (like 'shoes'): <input type="text" name="user"><br />
        Repo (like 'shoes4'): <input type="text" name="repo"><br />
        Issue (like '1'): <input type="text" name="issue"><br />
        Head (like 'steveklabnik:master'): <input type="text" name="head"><br />
        Base (like 'master'): <input type="text" name="base"><br />
        <input type="submit"><br />
        The example names would turn issue #1 on shoes/shoes4 into a pull request, asking to merge steveklabnik:master into master.
      </form>
      HTML
    else
      "<a href='/auth/github'>Sign in with GitHub</a> : #{session[:user_id]}"
    end
  end

  post '/transmute' do
    json = %Q{{"issue":"#{params[:issue]}","head":"#{params[:head]}","base":"#{params[:base]}"}}
    uri = %Q{https://api.github.com/repos/#{params[:user]}/#{params[:repo]}/pulls?access_token=#{session[:token]}}

    uri = URI(uri)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    res = http.start do |http|
      req = Net::HTTP::Post.new(uri.request_uri)
      req["Content-type"] = "application/json"
      req["Accept"] = "application/json"
      req.body = json

      response = http.request req
    end

    puts res.code
    puts res.message
      
    redirect "/"
  end

  get '/auth/:name/callback' do
    auth = request.env['omniauth.auth']
    session[:token] = auth["credentials"]["token"]

    user = User.first(:uid => auth["uid"])
    unless user
      user = User.create(
        :uid => auth["uid"],
        :nickname => auth["info"]["nickname"], 
        :name => auth["info"]["name"],
        :created_at => Time.now)
    end

    session[:user_id] = user.id

    redirect '/'
  end

  get "/logout" do
    session[:token] = nil
    session[:user_id] = nil
    redirect '/'
  end

  get '/auth/failure' do
    flash[:notice] = params[:message] # if using sinatra-flash or rack-flash
    redirect '/'
  end
end
