require 'bundler'
Bundler.require
require 'net/http'
require 'net/https'
require 'uri'

class Issue2Pr < Sinatra::Base

  enable :inline_templates

  use Rack::Session::Cookie

  use OmniAuth::Builder do
    provider :github, ENV['GITHUB_KEY'], ENV['GITHUB_SECRET'], scope: "repo"
  end

  get '/' do
    if session[:token]
      erb :form
    else
      erb :index
    end
  end

  post '/transmute' do
    params[:url] =~ /https:\/\/github.com\/(\w+)\/(\w+)\/issues\/(\d+)/
    json = %Q{{"issue":"#{$3}","head":"#{params[:head]}","base":"#{params[:base]}"}}
    uri = %Q{https://api.github.com/repos/#{$1}/#{$2}/pulls?access_token=#{session[:token]}}

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

    redirect "/"
  end

  get '/auth/:name/callback' do
    auth = request.env['omniauth.auth']
    session[:token] = auth["credentials"]["token"]

    redirect '/'
  end

  get "/logout" do
    session[:token] = nil
    redirect '/'
  end

  get '/auth/failure' do
    flash[:notice] = params[:message] # if using sinatra-flash or rack-flash
    redirect '/'
  end
end

__END__
@@ layout
<!doctype html >
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Issue to Pull Request</title>
  </head>
  <body>
    <%= yield %>
    <footer>A <a href="http://steveklabnik.com">@steveklabnik</a> joint.</footer>
  </body>
</html>

@@ index
<h1>Issue to Pull Request</h1>
<p>Ever wanted to add some commits that fix an Issue you had? Ever get mad that
you have to open a new Pull Request, comment that you're fixing that Issue,
make sure it's closed when you're done? Ugh!</p>
<p>Be chafed no longer. Simply give me the commits you'd like to add and a
link to an issue, and I'll make the magic happen.</p>
<h2>Let's do this</h2>
<p>
  First you've gotta <a href='/auth/github'>sign in with GitHub</a>.
</p>

<h3>How does it work?</h3>
<p>GitHub has this functionality in their API, but not their UI. So it's super
simple. It's also open source, you can check out <a href="https://github.com/steveklabnik/issue2pr">the source code to issue2pr on GitHub</a>.</p>

@@ form 

<h1>LET"S DO THIS</h1>
<form action="/transmute" method="POST">
  <label for="url">URL for the Issue (like 'https://github.com/steveklabnik/issue2pr/issues/1')</label><br />
  <input type="text" name="url" id="url"><br />
  <label for="head">Head (like 'steveklabnik:bugfix'):</label><br />
  <input type="text" name="head" id="head"><br />
  <label for="base">Base (like 'master'):</label><br />
  <input type="text" name="base" id="base"><br />
  <input type="submit"><br />
</form>
<p>The example names would turn issue #1 on steveklabnik/issue2pr into a pull request, asking to merge steveklabnik:bugfix into master.</p>

