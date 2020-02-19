/+ dub.sdl:
	name "tracing-writef"
	description "Example for article."
	authors "drug007"
	copyright "Copyright © 2019-2020, drug007"
	license "BSL"
+/
module advanced;

import std;
import std.datetime.stopwatch : StopWatch, AutoStart;

// There are three kind of jobs
enum Event { One, Two, Three, }

// simulate performing useful work
auto doSomeWork()
{
	import core.thread : Thread;
	enum delay = 400;
	Thread.sleep(dur!"msecs"(uniform(delay, 3*delay)));
}

void main()
{
	const total_cycles = 20;

	foreach(counter; 0..total_cycles)
	{
		// randomly generate an event of one of three kinds
		Event event = cast(Event) uniform(0, 3);

		// "performing" the job and benchmark its CPU execution time
		switch (event)
		{
			case Event.One:
				auto sw = StopWatch(AutoStart.no);
				sw.start();

				doSomeWork;

				sw.stop();
				writefln("%d:\tEvent %s   took: %s", counter, event, sw.peek);
			break;
			case Event.Two:
				auto sw = StopWatch(AutoStart.no);
				sw.start();

				doSomeWork;

				sw.stop();
				writefln("%d:\tEvent %s   took: %s", counter, event, sw.peek);
			break;
			case Event.Three:
				auto sw = StopWatch(AutoStart.no);
				sw.start();

				doSomeWork;

				sw.stop();
				writefln("%d:\tEvent %s took: %s", counter, event, sw.peek);
			break;
			default:
				assert(0);
		}
	}
}