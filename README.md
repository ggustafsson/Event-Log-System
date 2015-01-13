Event Log System
================

![EventLogger](https://github.com/ggustafsson/Event-Log-System/raw/master/Previews/EventLogger.png)

![EventServer](https://github.com/ggustafsson/Event-Log-System/raw/master/Previews/EventServer.png)

![EventParser](https://github.com/ggustafsson/Event-Log-System/raw/master/Previews/EventParser.png)

![Log report](https://github.com/ggustafsson/Event-Log-System/raw/master/Previews/Log%20Report%20Shortened.png)

The full log report is too big to display. It can be found here:
https://github.com/ggustafsson/Event-Log-System/raw/master/Previews/Log%20Report.png

Description
-----------
**Event Log System** is the result of a project in a Computer Science course at
University West, Trollhättan. It is a collection of components used for several
things.

1. Automatic logging of environmental events.
2. Logging of those events to a centralised server.
3. Create simple statistical overview of logs.

The best way to understand all of this is to read the file **Project
Report.pdf**. Note that while writing this version 1.0.3 was the current
version.

Components
----------
- **EventLogger** (runs on Raspberry Pi): Logs events and notifies the server
  running **EventServer**.
- **EventServer** (runs on server): Waits for incoming log messages from
  **EventLogger** and also shares the whole log file through HTTP.
- **EventParser** (runs on client): Parses the log file and create a HTML page
  with bar graphs etc.

Dependencies
------------
- EventLogger:
  - **Raspberry Pi**
  - **Python 3**
  - **RPi.GPIO**
- EventServer:
  - **Ruby 2**
- EventParser:
  - **Ruby 2**

License
-------
Released under the BSD 2-Clause License.

    Copyright (c) 2015, Göran Gustafsson. All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions are met:

     Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.

     Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation
     and/or other materials provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
    IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
    ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
    LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
    CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
    CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
    ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
