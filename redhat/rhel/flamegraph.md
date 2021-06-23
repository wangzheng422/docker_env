# flamegraph

```bash
brew install flamegraph

gperf record -e cpu-clock -g -p 28591

perf script -i perf.data &> perf.unfold

stackcollapse-perf.pl perf.unfold &> perf.folded

flamegraph.pl perf.folded > perf.svg

```

# ovs debug

```bash
mpstat -I CPU
# Linux 4.18.0-305.3.1.el8.x86_64 (iZ2zefa0nvt6ve965o41v5Z)       06/21/2021      _x86_64_        (2 CPU)

# 09:05:30 PM  CPU        1/s        4/s        8/s        9/s       10/s       11/s       12/s       14/s       15/s       24/s       25/s       26/s       27/s       28/s       29/s       30/s      NMI/s      LOC/s      SPU/s      PMI/s      IWI/s      RTR/s      RES/s      CAL/s      TLB/s      TRM/s      THR/s      DFR/s      MCE/s      MCP/s      HYP/s      HRE/s      HVS/s      ERR/s      MIS/s      PIN/s      NPI/s      PIW/s
# 09:05:30 PM    0       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00      14.39       0.00       0.00     543.15       0.00       0.00       0.00       0.00      66.87       0.63       0.57       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00
# 09:05:30 PM    1       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00      44.96       0.00       0.00       0.00       0.00      19.69       0.00     561.98       0.00       0.00       0.00       0.00      64.32       0.79       0.62       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00       0.00


mpstat -I SCPU
# Linux 4.18.0-305.3.1.el8.x86_64 (iZ2zefa0nvt6ve965o41v5Z)       06/21/2021      _x86_64_        (2 CPU)

# 09:06:20 PM  CPU       HI/s    TIMER/s   NET_TX/s   NET_RX/s    BLOCK/s IRQ_POLL/s  TASKLET/s    SCHED/s  HRTIMER/s      RCU/s
# 09:06:20 PM    0       0.00      43.03       0.00      22.58       0.00       0.00       0.01      66.39       0.26     133.43
# 09:06:20 PM    1       0.00      47.29       0.00      26.40      43.19       0.00       0.06      68.29       0.00     138.26


```