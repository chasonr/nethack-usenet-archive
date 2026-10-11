#!/usr/bin/env ruby

require 'fileutils'
require 'set'
require 'time'

# Describes salient information about a single Usenet message
class Message
  attr_reader :headers      # A Hash, mapping header types to contents
  attr_reader :raw_headers  # Text of headers as received
  attr_reader :text         # Text of message
  attr_reader :date         # A Time object giving the date header
  attr_reader :message_id   # The message ID
  attr_reader :references   # The References header as an array
  attr_reader :thread       # Links to other messages in the thread
  attr_reader :newsgroups   # The Newsgroups header as an array
  attr_accessor :seen       # A flag used by the flood-fill to identify threads

  def initialize
    @header = true
    @headers = {}
    @raw_headers = []
    @text = []
    @thread = Set.new
    @newsgroups = Set.new
    seen = false
  end

  # Add the next line from the mbox file
  def add_line(line)
    if line == "" and @header then
      @header = false
    elsif @header then
      @raw_headers << line
    else
      @text << line
    end
  end

  # Call this at the end of the message
  def finish
    # Join continued header lines and process into a Hash
    header = nil
    @raw_headers.each do |line|
      if header and line =~ /^[ \t]/ then
        header += line
      else
        process_header(header) if header
        header = line
      end
    end
    process_header(header) if header

    # Message-ID header
    @message_id = headers['message-id']

    # References header
    refstr = headers['references']
    if refstr.nil? then
      @references = []
    else
      @references = refstr.strip.split(/\s+/)
    end

    # Date header
    datestr = headers['date']
    @date = nil
    if datestr.nil? then
      puts "Message #{message_id} has no Date header; using placeholder"
      @date = ::Time.rfc2822("01 Jan 1970 00:00:00 +0000")
    else
      begin
        @date = ::Time.parse(datestr)
      rescue ArgumentError
        puts "Message #{message_id} #{datestr} date failed generic parsing, using placeholder"
        @date = ::Time.rfc2822("01 Jan 1970 00:00:00 +0000")
      end
    end

    # Newsgroups header
    groupsstr = headers['newsgroups']
    if groupsstr then
      groups = groupsstr.strip.split(/\s*,\s*/)
      groups.each {|g| @newsgroups << g}
    end
  end

  # Establish a quarantine period for the great Hipcrime attack of 2007-8
  @@begin_quarantine = Time.new(2007, 8, 12, 0, 0, 0)
  @@end_quarantine = Time.new(2008, 2, 7, 0, 0, 0)
  def quarantine
    @@begin_quarantine <= date && date <= @@end_quarantine
  end

private
  # Call this when a header line is complete
  def process_header(header)
    rec = header.split(':', 2)
    name = rec[0].strip.downcase
    value = rec[1]
    if value then
      value = value.strip
    else
      puts "header #{rec[0]} has no value"
    end
    @headers[name] = value
  end
end

# To identify threads
def flood_fill(msg, thread)
  return if msg.seen
  msg.seen = true
  thread << msg
  msg.thread.each do |msg2|
    flood_fill(msg2, thread)
  end
end

from_google = /^From -?[0-9]+$/
from_giganews = /^From [A-Za-z0-9]+ [A-Z][a-z][a-z] [A-Z][a-z][a-z] [0-9]{1,2} [0-9]{1,2}:[0-9]{1,2}:[0-9]{1,2} [0-9]{4}$/

# Read the messages
messages = {}
ARGV.each do |mbox|
  STDERR.puts "mbox=#{mbox}"
  msg = nil
  from = nil
  File.foreach(mbox, encoding: 'ASCII-8BIT') do |line|
    line.chomp!
    if from.nil? then
      if line =~ from_google then
        from = from_google
      elsif line =~ from_giganews then
        from = from_giganews
      else
        next
      end
    end
    if line =~ from then
      if msg then
        msg.finish
        messages[msg.message_id] = msg
      end
      msg = Message.new
    else
      msg.add_line(line)
    end
  end
  if msg then
    msg.finish
    messages[msg.message_id] = msg
  end
end

# Target groups for each message
groups = %w@
    comp.sources.games.bugs
    comp.sources.games
    net.games.hack
    net.sources.games
    net.sources
    rec.games.hack
    rec.games.roguelike.nethack
@

# Map each message to others in its thread
messages.each do |id, msg|
  msg.references.each do |ref|
    refmsg = messages[ref]
    next if refmsg.nil?
    refmsg.thread << msg
    msg.thread << refmsg
  end
end

# Identify threads
threads = []
messages.each do |id, msg|
  msg.seen = false
end
messages.each do |id, msg|
  next if msg.seen
  thread = Set.new
  flood_fill(msg, thread)
  thread = thread.to_a.sort {|a, b| a.date <=> b.date}
  threads << thread
end

threads.sort! {|a, b| a[0].date <=> b[0].date}

# Arrange into groups and threads
messages.each do |id, msg|
  msg.seen = false
end
groups.each do |grp|
  puts "Group: #{grp}"
  thrnum = 0
  msgnum = 0
  threads.each do |thread|
    ok = false
    thread.each do |msg|
      if msg.newsgroups.member?(grp) then
        ok = true
        break
      end
    end
    if ok then
      if thread.size == 1 then
        dir = File.join(grp, "single")
      else
        thrnum += 1
        dir = File.join(grp, "%s" % thrnum)
      end
      thread.each do |msg|
        msgnum += 1
        if msg.quarantine then
          dir2 = File.join(dir, "quarantine")
        else
          dir2 = dir
        end
        FileUtils.mkdir_p(dir2)
        path = File.join(dir2, "%s" % msgnum)
        File.open(path, "w", encoding: "ASCII-8BIT") do |fp|
          fp.write(msg.raw_headers.join("\n"))
          fp.write("\n\n")
          fp.write(msg.text.join("\n"))
          fp.write("\n")
        end
        msg.seen = true
      end
    end
  end
end
