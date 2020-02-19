set pagination off
set print address off

break tracing_gdb.d:53
commands
set $EventOne = currClock()
continue
end

break tracing_gdb.d:54
commands
set $EventOne = currClock() - $EventOne
printf "%d:\tEvent One   took: %s\n", counter, printClock($EventOne)
continue
end

break tracing_gdb.d:58
commands
set $EventTwo = currClock()
continue
end

break tracing_gdb.d:59
commands
set $EventTwo = currClock() - $EventTwo
printf "%d:\tEvent Two   took: %s\n", counter, printClock($EventTwo)
continue
end

break tracing_gdb.d:63
commands
set $EventThree = currClock()
continue
end

break tracing_gdb.d:64
commands
set $EventThree = currClock() - $EventThree
printf "%d:\tEvent Three took: %s\n", counter, printClock($EventThree)
continue
end

run
quit