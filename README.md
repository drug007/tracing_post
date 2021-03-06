# Tracing D Applications

Developing an application for linux you may need to monitor your application characteristics in run-time, for example to estimate its performance or memory consumption. There are several options to do it and some of them are:
- means provided by used programming language (for example using writef to print to standard output aka printf debugging)
- debuggers (using scripts or remote tracing)
- OS specific tracing framework (linux {k|u}probes and usdt probes, linux kernel event, performance events in windows etc)

For illustration all of three cases we will use a trivial artifical example:
```D
foreach(counter; 0..total_cycles)
{
    // randomly generate an event of one of three kinds
    Event event = cast(Event) uniform(0, 3);

    // "performing" the job and benchmark its CPU execution time
    switch (event)
    {
        case Event.One:

            doSomeWork;

        break;
        case Event.Two:

            doSomeWork;

        break;
        case Event.Three:

            doSomeWork;

        break;
        default:
            assert(0);
    }
}
```
where `doSomeWork` simulates CPU intensive job by using `Thread.sleep` static method.

That is very common pattern where an application runs in cycle and in every iteration performs some job depending on the application state. Here we can see that the application has three code path (CaseOne, CaseTwo and CaseThree) and we need to trace the application in runtime and collect info about its timings.

### Logging, Tracing and Profiling
When you develop applications some time or other you need to make some decision - does your application work like it should and if not what is wrong with it. There are different ways to achive it and some of them are logging, tracing and profiling. What is difference between them? One variant is:
- if you know exactly what events you are interested in to make the decision - you do logging
- if you don't know exactly what events you need to make a decision and you are forced to collect as many events as you can - you do tracing
- if you collect some events and analyze them to derive new information - you do profiling

## Writef Based Approach
The first way to trace our application is naive (but can be very usefull nevertheless)- using writef(ln) function of std library to output info into file. Someone can say that this is nothing than logging and D even has logger in its std library. Yes, you can say that, in some degree logging can be considered as light version of tracing. Our [code](tracing_writef.d):
```D
    case Event.One:
            auto sw = StopWatch(AutoStart.no);
            sw.start();

            doSomeWork;

            sw.stop();
            writefln("%d:\tEvent %s took: %s", counter, event, sw.peek);
        break;
            
```
So we just used `StopWatch` from Phobos and measure execution time of code block we are interested in. It's simple and even trivial. Also we have all might of Phobos to implement our ideas. Run the application by command `dub tracing_writef.d` and look at its output:
```
Running ./example-writef 
0:      Event One took:   584 ms, 53 μs, and 5 hnsecs
1:      Event One took:   922 ms, 72 μs, and 6 hnsecs
2:      Event Two took:   1 sec, 191 ms, 73 μs, and 8 hnsecs
3:      Event Two took:   974 ms, 73 μs, and 7 hnsecs
...
```

But there is price for this - we should compile tracing code in our binary, we should implement the way to collect tracing output, disable it if needed and so on - and this means another code we should compile in our binary. Summarize it.

pro:
- you get all might of Phobos (if not betterC mode of course) and can get what you want in human readable format (look at this nice duration output, thanks to Jonathan M Davis for his std.datetime)
- source code is portable
- easy to use
- no 3rd party tools needed

con:
- you have to rebuild your application and restart it if you want to change something so this is inappropriate for servers for example, so this approach is not agile and does not let you to play easily with your application/library
- no low level access to the application state
- noise in code due to added tracing code
- it can be unusable due to a lot of debug output
- overhead can be large
- it can be hard to use it in production

So in fact this approach is very suitable on early stage of developing and less useful in final product. Although if tracing logic is fixed and well defined this approach can be used in production ready applications/libraries - for example this way of dmd frontend tracing was suggested by Stefan Koch to [profile perfomance and memory consumption](https://github.com/dlang/dmd/pull/7792).

## GDB Based Approach
Debugger is more advanced way to trace our application. You do not need to modify your application to change the methodology of tracing that is very useful in production. Instead of compiling tracing logic in the application you set breakpoints. When gdb stop the application execution on breakpoint you can use large arsenal of gdb functionality to inspect internal state of inferior (this term used in gdb means the binary being debugged). You do not have ability to use Phobos directly but you can use helpers and moreover you have access to registers and stack - unavailable option in case of writef debugging. Let's take a look at our [code](tracing_gdb.d) for `Event.One`:
```D
    case Case.One:

        doSomeWork;

    break;
```
As you can see now our code does not contain any tracing code and is much cleaner. Tracing logic is placed in separate file, [trace.gdb](trace.gdb). Its content is:
```
set pagination off
set print address off

break app.d:45
commands
set $EventOne = currClock()
continue
end

break app.d:46
commands
set $EventOne = currClock() - $EventOne
printf "%d:\tEvent One   took: %s\n", counter, printClock($EventOne)
continue
end

...

run
quit
```
In first line pagination is switch off. It enables scrolling, in other case you should be press Enter or `q` button to continue script execution if your current console will be filled up. Second line disable showing address of current breakpoint to make output less verbose. Then breakpoints on line 33 is set and between `commands` and `end`  gdb commands enumerated that will be executed when gdb stop on this breakpoints. We set breakpoints on line 33 to get current timestamp (using helper) before `doSomeWork` will be called and on line 34 to get current timestamp after `doSomeWork` has been executed - in fact the line #34 does not exists but gdb is smart enough to set the breakpoint on the next available line. `$case0` is a [convenient variable](https://www.sourceware.org/gdb/onlinedocs/gdb/Convenience-Vars.html) where we store timestamp to calculate code execution time. `currClock()` and `printClock(long)` are helpers to let us pretty formatting by means of Phobos. The last two commands in the script is command to run debugging and quit debugger on finish. 

To build and start our tracing session use the following command:
```bash
dub build tracing_gdb.d --single
gdb --command=trace.gdb ./tracing-gdb | grep Event
```
where `trace.gdb` is the name of gdb script and `tracing-gdb` is the name of our binary. We use `grep` to make gdb output looks like writefln output to make compare easier. Now discuss advantages/disadvantages of gdb based approach.

pro:
  - your code is clean and does not contain any tracing code
  - you do not need to recompile your application to change tracing methodology, in many cases it's enough to change your gdb script
  - you do not need even to restart your application
  - you can use it in production (sorta of)
  - no overhead if you do not trace and little when does
  - you can use [watchpoints](https://www.sourceware.org/gdb/onlinedocs/gdb/Set-Watchpoints.html#Set-Watchpoints) and [catchpoints](https://www.sourceware.org/gdb/onlinedocs/gdb/Set-Catchpoints.html#Set-Catchpoints) besides of breakpoints

con: 
  - using breakpoints in some cases may be inconvenient, annoying or impossible.
  - gdb pretty-printing provides "less pretty" output because lack of fulle Phobos support comparing to writef approach
  - sometimes gdb is not available in production

The point about hard breakpoint setting in gdb is based on the fact that to set a breakpoint in gdb you can use only an address, a line number or a function name (see [gdb manual](https://www.sourceware.org/gdb/onlinedocs/gdb/Set-Breaks.html#Set-Breaks)). Using an address is too low level and inconvenient. Line numbers are ephemerial and can easily be changed by developers so your scripts will be broken and this is annoying. Function name is convenient and stable but is useless if you need to place tracing probe inside a function.

Good example of using gdb for tracing can be a project of another bright member of D community, Vladimir Panteleev - [dmdprof](https://github.com/CyberShadow/dmdprof)

## Usdt Based Approach

So far we have two ways to trace our application that are complimentary each other. But is there a way to union all advantages of these two ways together and avoid their drawbacks? Of course, the answer is yes. In fact there are several ways to achieve this but hereafter only one will be discussed - USDT, user land statically defined tracing. 
Warning: Unfortunately due to historical reasons Linux tracing ecosystem is fragmented and rather confusing. There is no plain and simple introduction. Get ready to invest much more time if you want to understand this domain.

The first well-known full-fledged tracing framework was DTrace developed by Sun Microsystem (originally, now it is open sourced and even licensed under GPL). Yes, there have been strace and ltrace for a long time but they were limited - for example they do not let you trace what happened inside function call. Today, DTrace is available in Solaris, FreeBSD, macOS and Oracle Linux. In fact DTrace is not available in Linux due to its initial license - the CDDL instead of GPL. In 2018 DTrace was relicensed under GPL but it was too late and now Linux has its own tracing ecosystem. As everything open source has disadvantages and in the current case it resulted in fragmentation - there are several tools/frameworks/etc that are able to solve the same problems in different ways but somehow and sometime can interoperate each other. We will be using [bpftrace](https://github.com/iovisor/bpftrace) - high level tracing language for Linux eBPF. In D USDT probes are provided by [usdt](http://code.dlang.org/packages/usdt) library. Let's start from our [code](tracing_usdt.d):
```D
	case Case.One:
		mixin(USDT_PROBE!("dlang", "CaseOne", kind));

		doSomeWork;

		mixin(USDT_PROBE!("dlang", "CaseOne_return", kind));
	break;
```
Here we mixed in two probes in the start and the end of the code we are interested in. It seems looking like our first example, `tracing_writef` but huge difference is that there is no any logic here. We only defined two probes that are NOP instructions. That means that these probes has almost zero overhead and we can use them in production. The second great advantage is that we can change logic while the application is running. That just is impossible in case of using writef based approach. As we use bpftrace we need to write a script where we define actions that should be performed on our probes:
```
usdt:./tracing-usdt:dlang:CaseOne
{
	@last["CaseOne"] = nsecs;
}

usdt:./tracing-usdt:dlang:CaseOne_return
{
	if (@last["CaseOne"] != 0)
	{
		$tmp = nsecs;
		$period = ($tmp - @last["CaseOne"]) / 1000000;
		printf("%d:\tEvent CaseOne   took: %d ms\n", @counter++, $period);
		@last["CaseOne"] = $tmp;
		@timing = hist($period);
	}
}
...
```
The first statement is the action block. It triggers on USDT probe that compiled in `./tracing-usdt` executable (it includes path to the executable) with `dlang` provider name and `CaseOne` probe name. When this probes hit then global (@ sign) AA `last` updates current timestamp for its element `CaseOne` - by doing this we store the time moment our code start running. The second action block defines actions performed on `CaseOne_return` probe hit. Here we first of all check if we already initialized corresponding element in @last AA. This is needed because our application can be already running when we run the script and we `CaseOne_return` probe can be fired before `CaseOne`. Then we calculate how many time our code execution took, output it and store in a histogramm `timing`.

Blocks `BEGIN` and `END` define actions performed in the beginning and the end of the script and this is nothing more than initialization and finalization.

Build and run the example:
```
dub build tracing_usdt.d   --single --compiler=ldmd2 # or gdc
./tracing-usdt &                                     # run the example in background
sudo bpftrace bpftrace.bt                            # start tracing session
```
Output:
```
Attaching 8 probes...
0:	Event CaseThree took: 552 ms
1:	Event CaseThree took: 779 ms
2:	Event CaseTwo   took: 958 ms
3:	Event CaseOne   took: 1174 ms
4:	Event CaseOne   took: 1059 ms
5:	Event CaseThree took: 481 ms
6:	Event CaseTwo   took: 1044 ms
7:	Event CaseThree took: 611 ms
8:	Event CaseOne   took: 545 ms
9:	Event CaseTwo   took: 1038 ms
10:	Event CaseOne   took: 913 ms
11:	Event CaseThree took: 989 ms
12:	Event CaseOne   took: 1149 ms
13:	Event CaseThree took: 541 ms
14:	Event CaseTwo   took: 1072 ms
15:	Event CaseOne   took: 633 ms
16:	Event CaseTwo   took: 832 ms
17:	Event CaseTwo   took: 1120 ms
^C



@timing: 
[256, 512)             1 |@@@@@                                               |
[512, 1K)             10 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@|
[1K, 2K)               7 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@                |
```

In the session output above there are only 18 lines insead of 20 - it's because `tracing-usdt` had been started before the bpftrace script so the first two events were lost. Also you need to break the example running by `Ctrl-C` after `tracing-usdt` completes. After the bpftrace script stops execution it ouputs content of `timing` map as histogram. The histogram says that one time code execution takes value between 256 and 512 ms, ten times between 512 and 1024 ms and seven times more between 1024 and 2048 ms. This builtin statistic ease bpftrace using.

Pro:
- you have low-level access to your code (registers, memory etc)
- minimal noise in your code
- no recompilation/rerun if you decide to change tracing logic
- almost zero overhead
- can be effectively used in production
Con:
- learning USDT can be hard, particularly considering the state of linux tracing ecosystem
- you need external tools (frontends)
- OS specific

Note: gdb has support for USDT probes since v7.5. You can modify `trace.gdb` script to set breakpoints using USDT probes instead of line numbers. That eases developing because you don't need to synchronize line numbers during source code modification.

Futher reading: 
- [Profiling D's Garbage Collection with Bpftrace](https://theartofmachinery.com/2019/04/26/bpftrace_d_gc.html)
- [Systemtap Probes and Gdb](https://blog.sergiodj.net/2012/10/27/gdb-and-systemtap-probes-part-2.html)

## Conclusion

Summary for both parts:

Feature | writef | gdb | usdt
------- | :------: | --- | ---
pretty <br> printing | by means of Phobos <br> and other libs | by means of <br> [pretty-printing](https://www.sourceware.org/gdb/onlinedocs/gdb/Pretty-Printing.html) | limited builtins 
 low-level | no | yes | yes
 clean code | no | yes | sorta of
 recompilation | yes | no | no
 restart | yes | no | no
 usage <br> complexity | easy | easy+ | advanced
 3rd party <br> tools | no | only debugger | tracing system front end
 crossplatform | yes | sorta of | OS specific
 overhead | can be large | none | can be ignored <br> even in production
 production ready | sometimes possible | sometimes impossible | yes
  |  |  | 

Feature description:
- `pretty printing` is important if the tracing output should be read by human (and can be ignored in case of intermaching data exchange)
- `low-level` means access to low-level detail of traced binary like registers or memory
- `clean` code characterized if your code would contain additional tracing code that is not related to business logic of the application.
- `recompilation` determines if you should recompile your application if you'd like to change tracing methodology
- `restart` determines if you should restart your application if you'd like to change tracing methodology
- `usage complexity` defines is it available to beginners or only seasoned developers can use this technolody
- `3rd party tools` describes if you need to use other tools not provided by standard tools of the D language to use this technolody
- `crossplatform` says can you use this approach on different OSes without changes
- `overhead` - what price do you pay for using this technolody?
- `production ready` - is it possible to use this technolody in production system without any consequencies