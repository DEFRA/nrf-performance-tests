#!/bin/sh
set -x

echo "run_id: $RUN_ID in $ENVIRONMENT"

NOW=$(date +"%Y%m%d-%H%M%S")

if [ -z "${JM_HOME}" ]; then
  JM_HOME=/opt/perftest
fi

JM_SCENARIOS=${JM_HOME}/scenarios
JM_REPORTS=${JM_HOME}/reports
JM_LOGS=${JM_HOME}/logs

mkdir -p ${JM_REPORTS} ${JM_LOGS}

# Clean any report contents from a previous run. JMeter requires the report
# output directory to be empty; when it is a bind mount it cannot delete the
# directory itself ("Resource busy"), so we clear its contents instead.
rm -rf "${JM_REPORTS:?}"/* "${JM_REPORTS}"/.[!.]* 2>/dev/null || true

TEST_SCENARIO=${TEST_SCENARIO:-test}
SCENARIOFILE=${JM_SCENARIOS}/${TEST_SCENARIO}.jmx
REPORTFILE=${NOW}-perftest-${TEST_SCENARIO}-report.jtl
LOGFILE=${JM_LOGS}/perftest-${TEST_SCENARIO}.log

# Target service. ENVIRONMENT is the name of the environment the test runs in.
SERVICE_ENDPOINT=${SERVICE_ENDPOINT:-nrf-frontend.${ENVIRONMENT}.cdp-int.defra.cloud}
# Port and scheme of the service under test.
SERVICE_PORT=${SERVICE_PORT:-443}
SERVICE_URL_SCHEME=${SERVICE_URL_SCHEME:-https}

# Load profile. These can be overridden via environment variables (e.g. from the
# CDP Portal) and are injected into the test plan as JMeter properties so the
# load shape can be tuned without editing the .jmx scenario.
# THREAD_COUNT is the concurrent users per journey. The test.jmx scenario runs
# three journeys (homepage, submit-quote, upload) in parallel, each as its own
# thread group sharing THREAD_COUNT, so the service sees 3 x THREAD_COUNT
# concurrent sessions. Defaults to 35 (3 x 35 = 105 concurrent sessions),
# matching the ~100 concurrent-user NFR-SCCA-007 capacity target.
THREAD_COUNT=${THREAD_COUNT:-35}
RAMPUP_SECONDS=${RAMPUP_SECONDS:-30}
LOOP_COUNT=${LOOP_COUNT:-100}
DURATION_SECONDS=${DURATION_SECONDS:-300}

# Run the test suite
jmeter -n -t ${SCENARIOFILE} -e -l "${REPORTFILE}" -o ${JM_REPORTS} -j ${LOGFILE} -f \
-Jenv="${ENVIRONMENT}" \
-Jdomain="${SERVICE_ENDPOINT}" \
-Jport="${SERVICE_PORT}" \
-Jprotocol="${SERVICE_URL_SCHEME}" \
-JTHREAD_COUNT="${THREAD_COUNT}" \
-JRAMPUP_SECONDS="${RAMPUP_SECONDS}" \
-JLOOP_COUNT="${LOOP_COUNT}" \
-JDURATION_SECONDS="${DURATION_SECONDS}"

# Publish the results into S3 so they can be displayed in the CDP Portal
if [ -n "$RESULTS_OUTPUT_S3_PATH" ]; then
  # Copy the results log and the generated report files to the S3 bucket
   if [ -f "$JM_REPORTS/index.html" ]; then
      aws --endpoint-url=$S3_ENDPOINT s3 cp "$REPORTFILE" "$RESULTS_OUTPUT_S3_PATH/$REPORTFILE"
      aws --endpoint-url=$S3_ENDPOINT s3 cp "$JM_REPORTS" "$RESULTS_OUTPUT_S3_PATH" --recursive
      if [ $? -eq 0 ]; then
        echo "Results log and test results published to $RESULTS_OUTPUT_S3_PATH"
      fi
   else
      echo "$JM_REPORTS/index.html is not found"
      exit 1
   fi
else
   echo "RESULTS_OUTPUT_S3_PATH is not set"
   exit 1
fi

exit $test_exit_code
