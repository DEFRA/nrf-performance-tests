# nrf-performance-tests

A JMeter based performance test runner for the Nature Restoration Fund (NRF)
service on the CDP Platform. It ships scenarios for the `nrf-frontend` quote
journey — the boundary **upload** flow and the **submit quote** step — running
all three journeys (homepage, submit-quote, upload) in parallel.

- [Licence](#licence)
  - [About the licence](#about-the-licence)

## Build

Test suites are built automatically by the [.github/workflows/publish.yml](.github/workflows/publish.yml) action whenever a change is committed to the `main` branch.
A successful build results in a Docker container that is capable of running your tests on the CDP Platform and publishing the results to the CDP Portal.

## Run

The performance test suites are designed to be run from the CDP Portal.
The CDP Platform runs test suites in much the same way it runs any other service — it takes a Docker image and runs it as an ECS task, automatically provisioning infrastructure as required.

## Local testing

Local runs use [nrf-solution](https://github.com/DEFRA/nrf-solution), which brings up the full stack (frontend, backend, databases, LocalStack) via Tilt and runs the perf test container against it.

See [nrf-solution/docs/perf-testing.md](https://github.com/DEFRA/nrf-solution/blob/main/docs/perf-testing.md) for instructions.

## Scenarios

The suite ships a single JMeter scenario:

| `TEST_SCENARIO` | File | What it tests |
|-----------------|------|---------------|
| `test` (default) | `scenarios/test.jmx` | Mixed capacity proof — three journeys (homepage, submit-quote, upload) run **in parallel** to exercise the service under concurrent mixed load (NFR-SCCA-007) |

## Tuning the load profile

`THREAD_COUNT` is the concurrent users *per journey* and `RAMPUP_SECONDS`, `LOOP_COUNT`, `DURATION_SECONDS` shape the run (defaults shown):

```
THREAD_COUNT=35  RAMPUP_SECONDS=30  LOOP_COUNT=100  DURATION_SECONDS=300
```

In the CDP perf environment these are set from the Portal. Locally they are set via the Tilt dashboard — see the perf-testing guide linked above.

## Licence

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

<http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3>

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government licence v3

### About the licence

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable
information providers in the public sector to license the use and re-use of their information under a common open
licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
