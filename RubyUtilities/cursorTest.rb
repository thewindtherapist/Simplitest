# require 'curses'
 
# Curses.init_screen
# begin
  # Curses.setpos(6, 3)  # column 6, row 3
  # Curses.addstr("Hello")
 # puts "hello world"
  # Curses.addstr("Hello again")
  # Curses.getch  # Wait until user presses some key.
# ensure
  # Curses.close_screen
  # puts "hello world again"
# end

#!/usr/local/bin/ruby

# require "curses"
# include Curses

# def show_message(message)
  # width = message.length + 6
  # win = Window.new(5, width,
               # (lines - 5) / 2, (cols - width) / 2)
  # win.box(?|, ?-)
  # win.setpos(2, 3)
  # win.addstr(message)
  # win.refresh
  # win.getch
  # win.close
# end

# init_screen
# begin
  # crmode
# #  show_message("Hit any key")
  # setpos((lines - 5) / 2, (cols - 10) / 2)
  # addstr("Hit any key")
  # refresh
  # getch
  # show_message("Hello, World!")
  # refresh
# ensure
  # close_screen
# end

#!/usr/local/bin/ruby
# rain for a curses test

require "curses"
include Curses

def onsig(sig)
  close_screen
  exit sig
end

def ranf
  rand(32767).to_f / 32767
end

# main #
for i in 1 .. 15  # SIGHUP .. SIGTERM
  if trap(i, "SIG_IGN") != 0 then  # 0 for SIG_IGN
    trap(i) {|sig| onsig(sig) }
  end
end

init_screen
nl
noecho
srand

xpos = {}
ypos = {}
r = lines - 4
c = cols - 4
for i in 0 .. 4
  xpos[i] = (c * ranf).to_i + 2
  ypos[i] = (r * ranf).to_i + 2
end

i = 0
while TRUE
  x = (c * ranf).to_i + 2
  y = (r * ranf).to_i + 2

  setpos(y, x); addstr(".")

  setpos(ypos[i], xpos[i]); addstr("o")

  i = if i == 0 then 4 else i - 1 end
  setpos(ypos[i], xpos[i]); addstr("O")

  i = if i == 0 then 4 else i - 1 end
  setpos(ypos[i] - 1, xpos[i]);      addstr("-")
  setpos(ypos[i],     xpos[i] - 1); addstr("|.|")
  setpos(ypos[i] + 1, xpos[i]);      addstr("-")

  i = if i == 0 then 4 else i - 1 end
  setpos(ypos[i] - 2, xpos[i]);       addstr("-")
  setpos(ypos[i] - 1, xpos[i] - 1);  addstr("/ \\")
  setpos(ypos[i],     xpos[i] - 2); addstr("| O |")
  setpos(ypos[i] + 1, xpos[i] - 1); addstr("\\ /")
  setpos(ypos[i] + 2, xpos[i]);       addstr("-")

  i = if i == 0 then 4 else i - 1 end
  setpos(ypos[i] - 2, xpos[i]);       addstr(" ")
  setpos(ypos[i] - 1, xpos[i] - 1);  addstr("   ")
  setpos(ypos[i],     xpos[i] - 2); addstr("     ")
  setpos(ypos[i] + 1, xpos[i] - 1);  addstr("   ")
  setpos(ypos[i] + 2, xpos[i]);       addstr(" ")

  xpos[i] = x
  ypos[i] = y
  refresh
  sleep(0.5)
end

# end of main