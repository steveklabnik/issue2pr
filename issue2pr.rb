require 'bundler'
Bundler.require
require 'net/http'
require 'net/https'
require 'uri'

require 'sinatra/flash'

class Issue2Pr < Sinatra::Base

  enable :inline_templates

  use Rack::Session::Cookie
  register Sinatra::Flash

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

    response = nil
    res = http.start do |http|
      req = Net::HTTP::Post.new(uri.request_uri)
      req["Content-type"] = "application/json"
      req["Accept"] = "application/json"
      req.body = json

      response = http.request req
    end

    if response.code = '201'
      flash[:success] = "Awesome! Check out <a href='#{params[:url]}'>Issue #{$3}</a> and it should be a Pull Request now!"
    else
      flash[:error] = "There was some kind of error. Sorry!"
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
    flash[:error] = params[:message] # if using sinatra-flash or rack-flash
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
    <link rel="stylesheet" type="text/css" href="bootstrap.min.css" />
    <link href="bootstrap-responsive.css" rel="stylesheet">
    <link href="docs.css" rel="stylesheet">
  </head>
  <body>
    <div class="container">
      <header class="jumbotron subhead" id="overview">
        <h1>Issue2Pr</h1>
        <p class="lead">Turn your Issues into Pull Requests</p>
      </header>
      <% flash.each do |type, message| %>
        <div class="row">
          <div class="span12">
	          <div class="alert alert-<%= type%>">
              <p><%= message %></p>
            </div>
          </div>
        </div>
      <% end %>
      <%= yield %>
    </div>
    <footer class="footer"><p class="pull-right">A <a href="http://steveklabnik.com">@steveklabnik</a> joint.</p></footer>
  </body>
</html>

@@ index
<section>
  <div class="page-header">
    <h1>About</h1>
  </div>

  <div class="row">
    <div class="span12">
      <p>Ever wanted to add some commits that fix an Issue you had? Ever get mad that
      you have to open a new Pull Request, comment that you're fixing that Issue,
      make sure it's closed when you're done? Ugh!</p>
      <p>Be chafed no longer. Simply give me the commits you'd like to add and a
      link to an issue, and I'll make the magic happen.</p>
    </div>
  </div>
</section>
<section>
  <div class="page-header">
    <h1>Let's do this</h1>
  </div>

  <div class="row">
    <div class="span12">
      <p>
        First you've gotta <a href='/auth/github'>sign in with GitHub</a>.
      </p>
    </div>
  </div>
</section>

<section>
  <div class="page-header">
    <h1>How does it work?</h1>
  </div>

  <div class="row">
    <div class="span12">
      <p>GitHub has this functionality in their API, but not their UI. So it's super
      simple. It's also open source, you can check out <a href="https://github.com/steveklabnik/issue2pr">the source code to issue2pr on GitHub</a>.</p>
    </div>
  </div>
</section>

@@ form

<section>
  <div class="page-header">
    <h1>LET"S DO THIS</h1>
  </div>

  <div class="row">
    <div class="span12">
      <form action="/transmute" method="POST">
        <div class="control-group">
          <label class="control-label" for="url">Issue URL</label>
          <div class="controls">
            <input type="text" class="input-xlarge" id="url" name="url">
            <p class="help-block">like 'https://github.com/steveklabnik/issue2pr/issues/1'</p>
          </div>
        </div>
        <div class="control-group">
          <label class="control-label" for="head">HEAD</label>
          <div class="controls">
            <input type="text" class="input-xlarge" id="head" name="head">
            <p class="help-block">like 'steveklabnik:bugfix', this is probably a feature branch</p>
          </div>
        </div>
        <div class="control-group">
          <label class="control-label" for="base">Base</label>
          <div class="controls">
            <input type="text" class="input-xlarge" id="base" name="base">
            <p class="help-block">like 'master'</p>
          </div>
        </div>
        <div class="form-actions">
          <button type="submit" class="btn btn-primary">Transmute!</button>
        </div>
      </form>
      <p>The example names would turn issue #1 on steveklabnik/issue2pr into a pull request, asking to merge steveklabnik:bugfix into master.</p>
    </div>
  </div>
</section>

