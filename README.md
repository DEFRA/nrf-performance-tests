# nrf-performance-tests

A JMeter based performance test runner for the Nature Restoration Fund (NRF)
service on the CDP Platform. It ships scenarios for the `nrf-frontend` quote
journey — a smoke test, the boundary **upload** flow, and the **submit quote**
step — runnable locally via Docker Compose or on the CDP perf environment.

- [Licence](#licence)
  - [About the licence](#about-the-licence)

## Build

Test suites are built automatically by the [.github/workflows/publish.yml](.github/workflows/publish.yml) action whenever a change are committed to the `main` branch.
A successful build results in a Docker container that is capable of running your tests on the CDP Platform and publishing the results to the CDP Portal.

## Run

The performance test suites are designed to be run from the CDP Portal.
The CDP Platform runs test suites in much the same way it runs any other service, it takes a docker image and runs it as an ECS task, automatically provisioning infrastructure as required.

## Local Testing with Docker Compose

You can run the entire performance test stack locally using Docker Compose, including LocalStack, Redis, and the target service. This is useful for development, integration testing, or verifying your test scripts **before committing to `main`**, which will trigger GitHub Actions to build and publish the Docker image.

### Build the Docker image

```bash
docker compose build --no-cache development
```

This ensures any changes to `entrypoint.sh` or other scripts are picked up properly.

---

### Start the full test stack

```bash
docker compose up --build
```

This brings up the full Nature Restoration Fund stack under test:

* `development`: the container that runs the JMeter performance tests
* `service`: the `nrf-frontend` application under test (port 3000)
* `nrf-backend`: the backend API the frontend calls (port 3001)
* `postgres`: PostGIS database for the backend
* `liquibase`: applies the backend database schema, then exits
* `cdp-uploader`: file-upload/scan service (mock virus scanner) for the upload flow
* `redis`: backing cache for the frontend, backend and uploader
* `localstack`: simulates AWS S3, SNS and SQS

Once all services are healthy, the performance tests start automatically.

> **Liquibase changelogs (local only):** the `liquibase` service applies the
> backend schema from the sibling `nrf-backend` checkout
> (`../nrf-backend/changelog`). If that repo lives elsewhere, set
> `BACKEND_CHANGELOG_PATH` before running. This is only needed locally — CDP
> environments run their own migrations.

---

### Choosing a scenario

The suite ships three JMeter scenarios, selected with the `TEST_SCENARIO`
environment variable on the `development` container:

| `TEST_SCENARIO` | File | What it tests |
|-----------------|------|---------------|
| `start` (default) | `scenarios/start.jmx` | Smoke test — `GET /` (start page) |
| `upload` | `scenarios/upload.jmx` | Boundary upload flow (frontend → backend → cdp-uploader) |
| `submit-quote` | `scenarios/submit-quote.jmx` | Submit a quote — `POST /quote/check-your-answers` |

```bash
docker compose run --rm -e TEST_SCENARIO=submit-quote development
```

### Tuning the load profile

The load shape is controlled by environment variables (defaults shown), injected
into the test plans as JMeter properties:

```bash
THREAD_COUNT=10 RAMPUP_SECONDS=30 LOOP_COUNT=100 DURATION_SECONDS=300
```

In the CDP perf environment these are set from the Portal.

---

### Notes

* LocalStack resources (the `s3://test-results` bucket, the upload buckets/queues and the `nrf-quote-estimate-request` SNS topic) are created automatically by [`compose/localstack/05-setup.sh`](compose/localstack/05-setup.sh).
* Logs and reports are written to `./reports` on your host. `entrypoint.sh` clears this directory before each run, so reports do not accumulate between runs.
* `entrypoint.sh` runs JMeter for the selected `TEST_SCENARIO` and publishes the results to S3.
* `depends_on` healthchecks (and `service_completed_successfully` for `liquibase`) ensure the database, backend, uploader and frontend are ready before the tests start.
* Boundary/upload test data lives in [`test-data/`](test-data) and is copied into the image by the `Dockerfile`.
* If you change test scripts, scenarios or `entrypoint.sh`, rebuild the test container:

```bash
docker compose build development
```

## Local Testing with LocalStack

### Build a new Docker image
```
docker build . -t my-performance-tests
```
### Create a Localstack bucket
```
aws --endpoint-url=localhost:4566 s3 mb s3://my-bucket
```

### Run performance tests

```
docker run \
-e S3_ENDPOINT='http://host.docker.internal:4566' \
-e RESULTS_OUTPUT_S3_PATH='s3://my-bucket' \
-e AWS_ACCESS_KEY_ID='test' \
-e AWS_SECRET_ACCESS_KEY='test' \
-e AWS_SECRET_KEY='test' \
-e AWS_REGION='eu-west-2' \
my-performance-tests
```

docker run -e S3_ENDPOINT='http://host.docker.internal:4566' -e RESULTS_OUTPUT_S3_PATH='s3://cdp-infra-dev-test-results/cdp-portal-perf-tests/95a01432-8f47-40d2-8233-76514da2236a' -e AWS_ACCESS_KEY_ID='test' -e AWS_SECRET_ACCESS_KEY='test' -e AWS_SECRET_KEY='test' -e AWS_REGION='eu-west-2' -e ENVIRONMENT='perf-test' my-performance-tests


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
