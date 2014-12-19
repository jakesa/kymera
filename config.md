##Config

This page describes all of the options available in the kymera_config.yaml. The options are grouped by their relation to each of the different Kymera components.
The config file can be manipulated by in two different ways, either directly by changing the contents of the kymera_config.yaml or programatically using
the the Kymera::Config class. More on its usuage can be found [here relative link](config_class.md)

###Client

The client needs to know where to send the test requests and where to listen for the results.

####Broker Address

The broker address is where the client will connect to send subsequent test run requests. The address as 3 components to is,
the protocol, the ip address and the port number.  The protocol for the address will always be tcp. The ip should be the ip address
of the computer that the broker will reside on and the port number will be the port that the broker will be listening on for communication.
An example of this would be: 'tcp://192.168.0.12:5000'

####Results Bus Address

The results bus address is the address the client should connect to in order to receive real time results as well as run completion notification.
As with the broker address it has 3 components as well. The protocol, the ip address and the port number.
An example of this would be: 'tcp://192.168.0.12:5000'

###Broker

The broker has 4 configuration options. The client listening port, the worker listening port, the internal worker port and the number of connections

####Client Listening Port

The client listening port is the port that the broker is listening on for connections from the clients. This port number should be the port that the client
is using in the broker address

####Worker Listening Port

The worker listening port is the port that the broker is listening on for connections from the workers. This port number should be the port tat the workers
are using when specifying the broker address

####Internal Worker Port

The part of the broker that is responsible for managing the test queue needs to have its own port for connections. This port is used only within the broker
and is not needed by any other component

####Number of Connections

Currently, the broker has two queues that it uses for managing tests.  When the broker is started, it spawn a number of threads based on number of connections
config option. It then uses those threads as the queue for sending tests to workers.

###Worker

####Broker address

This is the address of the broker that the client will get its test run requests from. Like the others, it has a protocol, an ip address and a port number

####Results Collector Address

This is the address where the worker will send its final results for a completed test. Like the others, it has a protocol, an ip address and a port number

####Results Bus Collector

This is the address where the worker will send its realtime output.

###Result Collector

####Incoming Listening Port

This is the port that the results collector will listen on for incoming results from workers

####Results Bus Address

This is the address that the results collector will send the completion signal to the client

####Send Mongo Results

This config options tells the collector whether or not to send the results to a mongo database

####Mongo DB Address

The location of the mongo database that the collector will send the full runs results to

####Mongo DB Port

The port number the mongo database is listening on

####Mongo Database Name

The name of the datbase that the results will be written to

####Mongo Collection Name

The name of the collection that the results will belong to

###Result Bus

####Publish Port

The port that workers and collectors will publish messages to

####Subscribe Port

The port that clients will subscribe to in order to get results