#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'dalli'
require 'rack-cache'
require 'trello'

unless ENV['RACK_ENV'] == 'production'
  require 'dotenv/load'
end

configure do
  Trello.configure do |config|
    config.developer_public_key = ENV['TRELLO_DEVELOPER_PUBLIC_KEY']
    config.member_token = ENV['TRELLO_MEMBER_TOKEN']
  end
end

require File.expand_path('../facades/dashboard', __FILE__)
require File.expand_path('../facades/new_relic', __FILE__)

get '/' do
  cache_control :public, max_age: 1800

  @dashboard = Dashboard.new

  erb :index
end

get '/new-relic' do
  # cache_control :public, max_age: 1800

  @new_relic = NewRelic.new

  erb :new_relic
end
