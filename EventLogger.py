#!/usr/bin/env python3

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
# Version: 1.0                                                                #
#     Web: https://github.com/ggustafsson/Event-Log-System                    #
#     Git: https://github.com/ggustafsson/Event-Log-System.git                #
#   Email: gustafsson.g@gmail.com                                             #
###############################################################################

device_id = 1
log_server = "172.20.10.2"
log_port = 8080
log_file = "logfile.csv"
log_file_unsent = "logfile_unsent.csv"
check_interval = 0.5 # How many seconds should we wait after each check?

###############################################################################
# Do not change anything below this line except the event check section.      #
###############################################################################

import RPi.GPIO as GPIO # Extra module that control Raspberry Pi GPIO channels.
import socket
import sys
import time
from datetime import datetime
from os import path

unsent_messages = 0 # Indicates if there are unsent messages. On/off.
color_normal = "\033[0m"
color_warning = "\033[1;31m"

###############################################################################
# Modify this code to check for your specific event!                          #
###############################################################################
gpio_pin = 5
gpio_state_previous = 1 # HIGH is the default start state used.

GPIO.setmode(GPIO.BCM) # Use Broadcom board layout. Alternative is BOARD.
GPIO.setup(gpio_pin, GPIO.IN) # Set pin _gpio_pin_ as input type.

def event_check():
    global gpio_pin
    global gpio_state_previous

    gpio_state_current = GPIO.input(gpio_pin) # Save current state.
    log_message = "None" # Optional message sent with the log message.

    # Check if current state is HIGH and previous was LOW. Equals triggered.
    if gpio_state_current == 1 and gpio_state_previous == 0:
        log_event(log_message)

    gpio_state_previous = gpio_state_current # Save current state for next run.
###############################################################################
# End of custom code.                                                         #
###############################################################################

def log_event(log_message):
    global device_id
    global unsent_messages

    now = datetime.now()
    date = now.strftime("%Y-%m-%d")
    time = now.strftime("%H:%M:%S")

    # log_message looks like "2013-01-15,12:35:00,1,None".
    log_message = "%s,%s,%d,%s" % (date, time, device_id, log_message)
    # command_log looks like "LOG 2013-01-15,12:35:00,1,None".
    command_log = ("LOG " + log_message).encode()
    # command_warn looks like "WARN 1".
    command_warn = ("WARN " + str(device_id)).encode()

    print("%s %s - Event triggered. Sending message: " % (date, time), end="");
    try:
        # Send a warning to EventServer if unsent messages exist.
        if unsent_messages == 1:
            tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            tcp.connect((log_server, log_port))
            tcp.sendall(command_warn)
            tcp.close()
            unsent_messages = 0 # Reset unsent messages indicator.

        # Try to send log message to EventServer.
        tcp = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        tcp.connect((log_server, log_port))
        tcp.sendall(command_log)
        tcp.close()
        print("succeded.")
    except:
        unsent_messages = 1 # Indicate that there are unsent messages.
        print(color_warning + "FAILED!" + color_normal)

        # Write down all unsent log messages to file log_file_unsent.
        with open(log_file_unsent, "a") as file:
            file.write(log_message + "\n")

    # Write down all log messages to file log_file.
    with open(log_file, "a") as file:
        file.write(log_message + "\n")

# Don't start if file log_file_unsent exist. We want to force users to take
# care of it before continuing.
if path.isfile(log_file_unsent):
    print("File '%s' found! Merge it with log file on server and remove." %
          log_file_unsent)
    sys.exit(1)

print("EventLogger started. Sending logs to host %s." % log_server)
print("Local logging to '%s', unsent messages in '%s'." % (log_file, \
      log_file_unsent))

# Using try and except to hide the ugly quit message when using Ctrl+C.
try:
    while True:
        event_check() # Perform event check function.
        time.sleep(check_interval) # Sleep X seconds before next run.
except KeyboardInterrupt:
    print()
    sys.exit()
