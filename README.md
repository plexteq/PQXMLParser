
# PQXMLParser 

Convenient XML parser/wrapper for Objective-C based on libxml2

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

In order to use the code in your project:
* add ```libxml2.2.tbd``` framework/library dependency to your peoject
* add ```/usr/include/libxml2``` to "Header Search Path"

### Installing

Add XmlParser.h and XmlParser.m to your project.

## Running the tests

Press "Cmd+U" from the PQXMLParser project.

## Methods

Parser comprises of 2 main classes - ```XmlDocument``` and ```XmlNode```.
```XmlDocument``` is responsible for XML document serialization and deserialization.
```XmlNode``` is responsible for dealing with xml nodes, their children and attributes.

## License

This project is licensed under the BSD License

