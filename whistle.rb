#!/usr/bin/env ruby

require "yaml"
require "twitter"

class Whistle
  def initialize
    # checking username
    if ARGV.empty?
      @log_file.puts "[ ERROR ] : #{Time.now} Username not specified."
      exit 1
    else
      @user_name = ARGV[0]
    end

    # daemon wakeup time
    @wakeup_time = Time.now

    # terminate flag
    @term = false

    # path to pid file
    @pid_path = "./whistle.pid"

    # open log file
    @log_file = File.open("./whistle.log", "w")

    # load configuration
    @client = Twitter::REST::Client.new
    config = YAML.load_file("./config.yml")
    config.each do |key, val|
      @client.send("#{key}=", val)
    end

    # customizable set of options
    @options = {
      :include_rts => false,
      :exclude_replies => true,
      :count => 10
    }
  end

  def run
    begin
      @log_file.puts "[ START ] #{Time.now}"
      daemonize
      set_trap
      listen
      @log_file.puts "[ STOP ] #{Time.now}"
      @log_file.close
    rescue => e
      @log_file.puts "[ ERROR ] : #{Time.now} #{self.class.name}.run #{e}"
      exit 1
    end
  end

  def daemonize
    begin
      Process.daemon(true, true)
      open_pid_file
    rescue => e
      @log_file.puts "[ ERROR ] : #{Time.now} #{self.class.name}.daemonize #{e}"
      exit 1
    end
  end

  def open_pid_file
    begin
      File.open(@pid_path, "w") {|f| f.puts Process.pid} if @pid_path
    rescue => e
      @log_file.puts "[ ERROR ] : #{Time.now} #{self.class.name}.open_pid_file #{e}"
      exit 1
    end
  end

  def set_trap
    begin
      Signal.trap(:INT)   { @term = true }
      Signal.trap(:TERM)  { @term = true }
    rescue => e
      @log_file.puts "[ ERROR ] : #{Time.now} #{self.class.name}.set_trap #{e}"
      exit 1
    end
  end

  def listen
    begin
      loop do
        break if @term
        sleep 60
        @client.user_timeline(@user_name, @options).each do |tweet|
          next if @wakeup_time > tweet.created_at
          text = tweet.text
          if text.start_with?("whistle:")
            shutdown if text.include?("shutdown") and !(text.include?("reboot"))
            reboot if text.include?("reboot") and !(text.include?("shutdown"))
          end
        end
      end
    rescue => e
      @log_file.puts "[ ERROR ] : #{Time.now} #{self.class.name}.listen #{e}"
      exit 1
    end
  end

  def shutdown
    begin
      result = system("sync && shutdown -h +1")
      if result
        @log_file.puts "[ INFO ] : #{Time.now} shutdown succeeded."
        @client.update("@#{@user_name} whistle-daemon: shutdown succeeded! [#{Time.now}]")
      else
        @log_file.puts "[ INFO ] : #{Time.now} shutdown failed."
        @client.update("@#{@user_name} whistle-daemon: shutdown failed! [#{Time.now}]")
      end
    rescue => e
      @log_file.puts "[ ERROR ] : #{Time.now} #{self.class.name}.shutdown #{e}"
      exit 1
    end
  end

  def reboot
    begin
      result = system("sync && shutdown -r +1")
      if result
        @log_file.puts "[ INFO ] : #{Time.now} reboot succeeded."
        @client.update("@#{@user_name} whistle-daemon: reboot succeeded! [#{Time.now}]")
      else
        @log_file.puts "[ INFO ] : #{Time.now} reboot failed."
        @client.update("@#{@user_name} whistle-daemon: reboot failed! [#{Time.now}]")
      end
    rescue => e
      @log_file.puts "[ ERROR ] : #{Time.now} #{self.class.name}.reboot #{e}"
      exit 1
    end
  end
end

whistle = Whistle.new
whistle.run

