/+ dub.sdl:
	name "tracing-usdt"
	description "Example of application tracing using userland statically defined tracing probes"
	authors "drug007"
	copyright "Copyright © 2019-2020, drug007"
	license "BSL"
	dependency "usdt" version="~>0.0.1"
+/

import std;

import usdt : USDT_PROBE;

/// There are three kind of jobs
enum Case { One, Two, Three, }

/// simulate performing useful work
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
		// randomly getting a job of one of three kinds
		Case kind = cast(Case) uniform(0, 3);

		// "performing" the job and benchmark its CPU execution time
		switch (kind)
		{
			case Case.One:
				mixin(USDT_PROBE!("dlang", "CaseOne", kind));

				doSomeWork;

				mixin(USDT_PROBE!("dlang", "CaseOne_return", kind));
			break;
			case Case.Two:
				mixin(USDT_PROBE!("dlang", "CaseTwo", kind));

				doSomeWork;

				mixin(USDT_PROBE!("dlang", "CaseTwo_return", kind));
			break;
			case Case.Three:
				mixin(USDT_PROBE!("dlang", "CaseThree", kind));

				doSomeWork;

				mixin(USDT_PROBE!("dlang", "CaseThree_return", kind));
			break;
			default:
				assert(0);
		}
	}
}