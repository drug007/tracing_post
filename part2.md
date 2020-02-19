## Usdt base approach

So far we have two ways to trace our application that are complimentary each other. But is there a way to union all advantages of these two ways together and avoid their drawbacks? Of course, the answer is yes. In fact there are several ways to achieve this but hereafter only one will be discussed - user space statically defined tracing. 
Warning: Unfortunately due to historical reasons Linux tracing ecosystem is fragmented and rather confusing. There is no plain and simple introduction. Get ready to invest much time if you want to understand this domain.

The first well-known full-fledged tracing framework was DTrace developed by Sun Microsystem (originally, now it is open sourced and even licensed under GPL). Yes, there have been strace and ltrace for a long time but they were limited - for example they do not let you trace what happened inside function call. Today, DTrace is available in Solaris, FreeBSD, macOS and Oracle Linux. In fact DTrace is not available in Linux due to its initial license - the CDDL instead of GPL. In 2018 DTrace was relicensed under GPL but it was too late and now Linux has its own tracing ecosystem. As everything open source has disadvantages and in the current case it resulted in fragmentation - there are several tools/frameworks/etc that are solve the same problems in different ways but somehow and sometime can interoperate each other. To avoid this ambiguity hereafter only one animal of this zoo will be discussed: userland statically defined tracing.

gdb has support for stap probes since v7.5 (2012, https://blog.sergiodj.net/2012/10/27/gdb-and-systemtap-probes-part-2.html)

systemtap
perf
bcc
bpftrace
lttng

gdb scripts usage example (http://dkhramov.dp.ua/Comp.GDBScripts#.XkV4gqhn3uP)

## Conclusion

Summary for both parts:

Feature | writefln | gdb | usdt
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