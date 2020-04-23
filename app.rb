require 'sinatra'
require 'sinatra/activerecord'
require 'builder'
require 'twilio-ruby'
require 'haml'

set :database, ENV['DATABASE_URL'] || 'sqlite://garage.db'

class Open < ActiveRecord::Base; end

post '/' do
  logger.info params
  response = Twilio::TwiML::Response.new do |r|
    r.Play 'https://mer.s3.amazonaws.com/answer.mp3'
    r.Record action: '/recording', maxLength: 5, playBeep: true
  end
  response.text
end

post '/recording' do
  recording_url = params[:RecordingUrl] + '.mp3'

  account_sid = ENV['twillio_account_sid']
  auth_token = ENV['twillio_auth_token']

  # set up a client to talk to the Twilio REST API
  @client = Twilio::REST::Client.new account_sid, auth_token

  @client.account.sms.messages.create(
    :from => '+13103214772',
    :to => '+12133042136',
    :body => recording_url
  )

  Open.create url: recording_url

  response = Twilio::TwiML::Response.new do |r|
    r.Play 'http://nickmerwin.s3.amazonaws.com/9.wav', loop: 10
    r.Hangup
  end

  response.text
end

get '/' do
  @opens = Open.all
  haml :index
end
