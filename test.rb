#!/usr/bin/env ruby

#require "yaml"
#require "twitter"
#
#class Whistle
#  def initialize
#    @user_name = "tdkn_"
#
#    @wakeup_time = Time.now - 10000
#
#    @client = Twitter::REST::Client.new
#
#    config = YAML.load_file("config.yml")
#    config.each do |key, val|
#      @client.send("#{key}=", val)
#    end
#
#    @options = {
#      :include_rts => false,
#      :exclude_replies => true,
#      :count => 10
#    }
#
#    puts "wakeup_time : #{@wakeup_time}"
#  end
#
#  def print_tweet
#    @client.user_timeline(@user_name, @options).each do |tweet|
#      puts "text : #{tweet.text}"
#      puts "created_at : #{tweet.created_at}"
#      puts (@wakeup_time < tweet.created_at) ? "execute" : "drop"
#      puts "-----"
#    end
#  end
#end
#
#whistle = Whistle.new
#whistle.print_tweet

result = system("ls -al whistle > /dev/null")
puts "failed" if !result
puts "success" if result

