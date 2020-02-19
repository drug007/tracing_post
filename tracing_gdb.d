/+ dub.sdl:
	name "tracing-gdb"
	description "Example for article."
	authors "drug007"
	copyright "Copyright © 2019-2020, drug007"
	license "BSL"
+/

module advanced;

import std;

/// There are three kind of jobs
enum Case { One, Two, Three, }

/// simulate performing useful work
auto doSomeWork()
{
	import core.thread : Thread;
	enum delay = 400;
	Thread.sleep(dur!"msecs"(uniform(delay, 3*delay)));
}

/// convenient wrapper
extern(C)
long currClock()
{
	return Clock.currStdTime;
}

extern(C)
char* printClock(long value)
{
	static char[128] buffer;
	sformat(buffer[], "%s\0", dur!"hnsecs"(value));
	return buffer.ptr;
}

void main()
{
	const total_cycles = 20;

	foreach(counter; 0..total_cycles)
	{
		// randomly getting a job of one of three kinds
		Case kind = cast(Case) uniform(0, 3);

		// "performing" the job and benchmark its CPU execution time
		switch (kind)
		{
			case Case.One:

				doSomeWork;

			break;
			case Case.Two:

				doSomeWork;

			break;
			case Case.Three:

				doSomeWork;

			break;
			default:
				assert(0);
		}
	}
}