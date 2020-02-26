#!/bin/bash

dub tracing_writef.d

dub build tracing_writef.d --single                  || exit 1
dub build tracing_gdb.d    --single                  || exit 1
dub build tracing_usdt.d   --single --compiler=ldmd2 || exit 1

./tracing-writef                                     || exit 1
gdb --command=trace.gdb ./tracing-gdb | grep Event   || exit 1
./tracing-usdt &
sudo bpftrace bpftrace.bt