#!/usr/bin/env ruby

require 'rubygems'
require 'bundler/setup'
require 'sinatra'
require 'dalli'
require 'rack-cache'
require 'trello'
require 'date'

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

  months = params[:months] || 3
  @summaries = (0..(months.to_i - 1)).collect{ |i| m = DateTime.now << i; NewRelic.new(OpenStruct.new(year: m.year, month: m.month)) }

  erb :new_relic
end
