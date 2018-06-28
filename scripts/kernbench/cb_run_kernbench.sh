#!/usr/bin/env bash

cd ~

source $(echo $0 | sed -e "s/\(.*\/\)*.*/\1.\//g")/cb_common.sh

set_load_gen $@

LOAD_PROFILE=$(echo ${LOAD_PROFILE} | tr '[:upper:]' '[:lower:]')

KERNBENCH_NR_CPUS=$(get_my_ai_attribute_with_default kernbench_nr_cpus 0)

# Override the default 4*cpu for make -j <nr>
if test $KERNBENCH_NR_CPUS = 0; then
	NRJOBS=""
else
	NRJOBS="-o $KERNBENCH_NR_CPUS"
fi

#If more than one command is needed (e.g., connected by "&&" or ";", please dump it on script, instead of just assigining to the variable CMDLINE"
echo "#!/usr/bin/env bash" > kernbenchloadgen.sh
echo "cd linux" >> kernbenchloadgen.sh
echo "../ltp/utils/benchmark/kernbench-0.42/kernbench -n 1 -H -M -f $NRJOBS" >> kernbenchloadgen.sh
echo "mv kernbench.log .." >> kernbenchloadgen.sh

sudo chmod 755 ./kernbenchloadgen.sh
CMDLINE="sudo ./kernbenchloadgen.sh"

execute_load_generator "${CMDLINE}" ${RUN_OUTPUT_FILE} ${LOAD_DURATION}

elapsed_time=$(grep "Elapsed Time" kernbench.log | awk '{print $3}')
user_time=$(grep "User Time" kernbench.log | awk '{print $3}')
system_time=$(grep "System Time" kernbench.log | awk '{print $3}')
percent_cpu=$(grep "Percent CPU" kernbench.log | awk '{print $3}')
context_switches=$(grep "Context Switches" kernbench.log | awk '{print $3}')
sleeps=$(grep "Sleeps" kernbench.log | awk '{print $2}')

~/cb_report_app_metrics.py \
elapsed_time:$elapsed_time:s \
user_time:$user_time:s \
system_time:$system_time:s \
percent_cpu:$percent_cpu:pc \
context_switches:$context_switches:nr \
sleeps:$sleeps:nr \
$(common_metrics)

echo "~/cb_report_app_metrics.py \
	elapsed_time:$elapsed_time:s \
	user_time:$user_time:s \
	system_time:$system_time:s \
	percent_cpu:$percent_cpu:pc \
	context_switches:$context_switches:nr \
	sleeps:$sleeps:nr \
	$(common_metrics)" >>/tmp/metrics.txt

rm kernbench.log

unset_load_gen

exit 0
