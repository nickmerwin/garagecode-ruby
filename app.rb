require 'sinatra'
require 'sinatra/activerecord'
require 'builder'
require 'twilio-ruby'
require 'haml'

configure :production do
  db = URI.parse ENV['DATABASE_URL']

  ActiveRecord::Base.establish_connection(
    :adapter => db.scheme == 'postgres' ? 'postgresql' : db.scheme,
    :host     => db.host,
    :username => db.user,
    :password => db.password,
    :database => db.path[1..-1],
    :encoding => 'utf8'
  )
end

configure :development do
  set :database, database: 'garage.db', adapter: 'sqlite3'
end

class Open < ActiveRecord::Base; end

post '/' do
  logger.info params
  response = Twilio::TwiML::VoiceResponse.new do |r|
    r.play url: 'https://mer.s3.amazonaws.com/answer.mp3'
    r.record action: '/recording', maxLength: 5, playBeep: true
  end
  response.to_s
end

post '/recording' do
  recording_url = params[:RecordingUrl] + '.mp3'

  account_sid = ENV['twillio_account_sid']
  auth_token = ENV['twillio_auth_token']

  # set up a client to talk to the Twilio REST API
  @client = Twilio::REST::Client.new account_sid, auth_token

  @client.messages.create(
    :from => '+13103214772',
    :to => '+12133042136',
    :body => recording_url
  )

  Open.create url: recording_url

  response = Twilio::TwiML::VoiceResponse.new do |r|
    r.play digits: '9999'
    r.hangup
  end

  response.to_s
end

get '/' do
  @opens = Open.all
  haml :index
end
