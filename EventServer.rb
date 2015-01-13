#!/usr/bin/env ruby

# Copyright (c) 2015, Göran Gustafsson. All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  Redistributions of source code must retain the above copyright notice, this
#  list of conditions and the following disclaimer.
#
#  Redistributions in binary form must reproduce the above copyright notice,
#  this list of conditions and the following disclaimer in the documentation
#  and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

###############################################################################
# Version: 1.0.3                                                              #
#     Web: https://github.com/ggustafsson/Event-Log-System                    #
#     Git: https://github.com/ggustafsson/Event-Log-System.git                #
#   Email: gustafsson.g@gmail.com                                             #
###############################################################################

log_port = 8080
log_file = "logfile.csv"

###############################################################################
# Do not change anything below this line unless you know what you are doing.  #
###############################################################################

require "date"
require "socket"

trap("INT") { puts; exit } # Hide Ruby's scary exit message.

color_normal = "\033[0m"
color_warning = "\033[1;31m"

log_server = TCPServer.new(log_port)
puts "EventServer started on port #{log_port}. Logging to '#{log_file}'."

loop do
  # Use threads so program can handle several connections at the same time.
  Thread.start(log_server.accept) do |socket|
    request = socket.gets
    time = Time.now.strftime("%Y-%m-%d %H:%M:%S")

    # Check if incoming command starts with "LOG ".
    if request.include?("LOG ")
      puts "#{time} - #{request}"

      message = request.split(" ")[1..-1].join(" ") # Remove the first word.
      # Append the incoming log message to file log_file.
      File.open(log_file, "a") do |file|
        file.puts message
      end

      socket.puts "ACK" # Send back acknowledge message.
    # Check if incoming command starts with "WARN ".
    elsif request.include?("WARN ")
      id = request.split(" ")[1] # Extract the device id.
      print "#{time} - #{color_warning}Warning received!#{color_normal} "
      puts "Unreported message(s) exist on #{id}."

      socket.puts "ACK" # Send back acknowledge message.
    # Check if incoming command is a normal HTTP GET command.
    elsif request.include?("GET / HTTP") or
          request.include?("GET /index.html HTTP")
      puts "#{time} - Request for log file received."

      # Respond with sending the file log_file or not found message.
      if File.exist?(log_file)
        File.open(log_file, "rb") do |file|
          socket.print "HTTP/1.1 200 OK\r\n" +
                       "Content-Type: text/plain\r\n" +
                       "Content-Length: #{file.size}\r\n" +
                       "Connection: close\r\n"
          socket.print "\r\n"
          IO.copy_stream(file, socket)
        end
      else
        response = "Log file not found!\n"
        socket.print "HTTP/1.1 404 Not Found\r\n" +
                     "Content-Type: text/plain\r\n" +
                     "Content-Length: #{response.size}\r\n" +
                     "Connection: close\r\n"
        socket.print "\r\n"
        socket.print response
      end
    end

    socket.close
  end
end
