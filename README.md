# Kymera

Kymera is a distributed system build on ZeroMQ for running Cucumber tests across a network.
If you are at this page, first let me say Thank You for your interest.  That being said, the Kymera gem
is in a very early stage of development and is currently build specifically for use in DAT Solutions© internal testing infrastructure.
I plan to make this more generic so it can be used with other systems, but for now the goal is to get something working for DAT Solutions©
If you are still are interested, please download the source code and hack away.



##Architecture
The Kyemra gem is comprised of 5 components:

###Client
The client is the main entry point into the gem. This allows users to submit run requests to the framework. It is responsible for parsing the tests
and sending them out to the Broker

###Broker
The broker is the component that is responsible for creating and maintaining the test execution queues. When a queue is spawned, the tests are sent to the
 connected workers in a round-robin format. When a worker signals that it is available for test execution, the broker will send it a test to run.

###Worker
The worker is the component that is responsible for actually running the tests. As the tests are ran, the worker will publish its output to the results bus. When
the test is completed it will send the entire output of that run to the test results collector for processing

###Results Collector
The result collector is responsible for taking all of the results from a test run, aggregating them and sending those results back to the client
Optionally, the collector can also send a complete version of the results, parsed into html, to a mongodb database for reporting purposes.

###Results Bus
The Results Bus is where all the results are published. The Client listens on this bus for both real time output of the test run as well as the signal
that the test run has completed.

## Installation
Please note that at the time of this writing, this gem has not been published. You will need to pull a copy of the repo and build the gem yourself

    $ gem install kymera

This gem uses ZeroMQ. It will need to be installed. You can find the installation instructions on their website [here](http://zeromq.org/intro:get-the-software)

## Usage

After installation is complete, you will need to generate the kymera_config.yaml file for gem configuration. This should be done in the same location
as you Cucumber project. For convenience, there is a command line tool included with the gem. To generate the config file enter the following command

    $ kymera config

By default, the gem is setup to run everything locally and has the mongodb feature turned off.  Before you can use the Kymera system, the following components
must be running:
*Broker
*Results Collector
*Results Bus
*At least one worker

They can be started individually or all at once:

All at once

    $kymera broker collector bus worker

Individually

    $kymera broker
    $kymera collector


Once all the necessary processes are started, you can start the a test run by calling the #run_tests method on the Kymera module

    $Kymera.run_tests('\Path\to\tests', 'cucumber', [-p default], 'develop', false)


The run_tests method takes the following parameters
*Test path
    This can be a path to a specific test or a path to a directory of tests. The system will parse all of the feature files for
    tests it is supposed to run based on the run options passed in.
*Test runner
    This is the runner that they system is to use for running the tests. At the time of this writing, the only supported running is cucumber
*Runner options
    These are the options to be passed to the runner and what will be used to parse the tests to be executed.
*Branch name
    When a test is started on a worker, it pulls the specified branch for any changes and updates before running the test. This parameter tells it the branch
    name
*Live results
    This parameter tells the system whether or not to display real time results. By default it is set to true. If set to false, there will be no console output
    to the client until the run has been completed

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
