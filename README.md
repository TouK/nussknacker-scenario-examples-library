# Nussknacker Scenario Examples Library

The project provides:
1. A tool for bootstrapping, running example scenarios, mocking external services (currently DB and OpenAPI service) and generating example 
   data for the example scenario (it's in the `scenario-examples-bootstrapper` dir) - let's call it Scenario Examples Bootstrapper
2. Scenario examples definitions (it's in the `scenario-examples-library` dir) - it's Scenario Examples Library

The main purpose is to provide a simple way for creating Nu scenarios that can be treated as examples. 
An example scenario has the following capabilities:
1. It can be deployed using the Scenario Examples Bootstrapper Docker image in any Nu environment 
2. It contains mocks of external services the example scenario depends on
3. it contains data generators to generate some data, to show users the deployed example scenario in action

## Building the docker image locally

```bash
docker buildx build --tag touk/nussknacker-example-scenarios-library:latest .
```

## Publishing

The publish process is done by the Github Actions. See `.github/workflows/publish.yml`. It's going to publish docker image with two tags:
`latest` and with version taken from the `version` file.

## Testing

The Library can be tested with Nu Quickstart. You can locally test your changes with the following script:

```bash
.github/workflows/scripts/test-with-nu-quickstart.sh
```

## Running the library

To illustrate how to use the image, we're going to use a docker-compose.yml snippet:

```yaml
services:

  nu-example-scenarios-library:
    image: touk/nussknacker-example-scenarios-library:latest
    environment:
      NU_DESIGNER_ADDRESS: "designer:8080"
      NU_REQUEST_RESPONSE_OPEN_API_SERVICE_ADDRESS: "designer:8181"
      KAFKA_ADDRESS: "kafka:9092"
      SCHEMA_REGISTRY_ADDRESS: "schema-registry:8081"
    volumes:
      - nussknacker_designer_shared_configuration:/opt/nussknacker/conf/

  [...]

  designer:
    image: touk/nussknacker:latest_scala-2.12
    environment:
      EXAMPLE_SCENARIOS_LIBRARY_SERVICE_NAME: nu-example-scenarios-library
      CONFIG_FILE: "/opt/nussknacker/conf/application.conf,/opt/nussknacker/conf/additional-configuration.conf"
    [...]
    volumes:
      - nussknacker_designer_shared_configuration:/opt/nussknacker/conf
    
  [...]

volumes:
  nussknacker_designer_shared_configuration:
    name: nussknacker_designer_shared_configuration
```

### ENVs:

#### Used by the `nu-example-scenarios-library` service

- `NU_DESIGNER_ADDRESS` - it contains the address (with port) of the Designer API. It's used to import and deploy scenarios and for Nu 
  configuration reloading. You should always configure one. 
- `NU_REQUEST_RESPONSE_OPEN_API_SERVICE_ADDRESS` - it contains the address (with port) of the server which exposes Request-Response 
  scenarios. You will need it when you want to run Request-Response scenario example using the library with requests generator.
- `KAFKA_ADDRESS` - it contains the address (With port) of a Kafka service. You will need it when you want to run streaming examples 
  with Kafka sources. It's used to create topics and by generator to generate example messages.
- `SCHEMA_REGISTRY_ADDRESS` - it contains the address (with port) of a Schema Registry service. You will need it when you want to run 
  streaming examples with Kafka sources. It's used to create schemas for Kafka topics.

#### Used by the `designer` service 

- `EXAMPLE_SCENARIOS_LIBRARY_SERVICE_NAME` - it's the address (without port) of the Example Scenarios Library service. You can use this env
  in designer custom configurations (required by your example). Eg. `${EXAMPLE_SCENARIOS_LIBRARY_SERVICE_NAME}:5432` is the mock Postgres service, `${EXAMPLE_SCENARIOS_LIBRARY_SERVICE_NAME}:8080` is the mock HTTP service exposed by the Library. 

### Nu Configuration

Some example scenarios require to provide a custom Nussknacker configuration (e.g. DB definition or Open API service definitions). 
The Scenario Examples Bootstrapper is able to customize Nu service configuration and reload it using Nu API. But it has to have
an access to the shared `additional-configuration.conf` file. The Bootstrapper is going to put each scenario example configuration file close
to the `additional-configuration.conf` and add proper "[include](https://github.com/lightbend/config/blob/main/HOCON.md#includes)" in this file.
In the docker compose case (see the example above) to achieve it, you should: 
1. create a shared configuration volume and mount it in `nu-example-scenarios-library` and `designer` services
2. include `/opt/nussknacker/conf/additional-configuration.conf` in the `CONFIG_FILE` ENV value

## What's underneath and how it works

### Scenario Examples Library

In the `scenario-examples-library` you will find definition of Nu scenarios, their mocks and example data generators (for showcase purposes). 
We want to build and develop the library and we hope new examples will be added to it in the future. If you want to create an example of Nu 
scenario, don't hesitate to put it here. 

### Scenario Examples Bootstrapper

In the `scenario-examples-bootstrapper` you will find the code of the service which is responsible for:
* creating mocks required by the example scenarios (DB mocks and OpenAPI mocks)
* configuring Nu Designer, importing, and deploying the example scenarios
* configuring Nu stack dependencies (like Kafka and Schema Registry)
* running data generators for the example scenarios

#### Mocks

There is one PostgreSQL-based database which can be used by Nu's database components. Each example service can define DDL scripts that will be 
imported by the DB instance.

The second type of mock is an OpenAPI service. It's based on the Wiremock. You can deliver OpenAPI definition that will be served by 
the Wiremock server. Moreover, you can create Wiremock mappings to instruct the mock on how to respond when your mocked OpenAPI service 
is called during scenario execution.

#### Scenario setup

You are supposed to deliver the example in the Nu JSON format. Some examples needs to customize the Nu Designer configuration, so you can
provide the custom parts of configuration too. And obviously you can instruct the Bootstrapper what topics and JSON schemas are required
by the scenario - it'll configure them too.

#### Data generators

To see the example in action, some data has to be provided. This is why Bootstrapper allows you to deliver these example data by defining:
- them statically - in files with listed Kafka messages or HTTP request bodies (in case of the Request-Response scenarios). It's run only 
  on the Boostrapper service starts.
- generator - it's a bash script that produces Kafka messages of HTTP request bodies. It's used by the Bootstapper to continuously generate
  and send the example data to the scenarios sources.

## Creating an example scenario

// todo: