# Aerospike non-root install and run

This archive allows you to install and run Aerospike without requiring the use of the root user or sudo.

## Quick Start

Take this archive and untar it to a convenient place using tar xf <ARCHIVE_NAME>. All the assets will be contained in *aerospike-non-root-install*

You will need to supply an Aerospike Enterprise feature key to enable the software. Copy this key to *aerospike-non-root-install* as \<FEATURE_KEY_NAME\>

A basic configuration file, aerospike.template.conf, is supplied which will set up a local instance of Aerospike and a namespace 'bar'. Full details of configuration at [Aerospike configuration](https://www.aerospike.com/docs/operations/configure/index.html)

Install Aerospike under the local directory name aerospike_local (default).

```
cd aerospike-non-root-install
./install-aerospike-non-root.sh -f <FEATURE_KEY_NAME> -c aerospike.template.conf 
```

Start Aerospike

```
aerospike_local/usr/bin/run-asd-non-root.sh start
```

Insert a record and retrieve it

```
aerospike_local/usr/bin/aql

aql> insert into bar(PK,value) values(1,1)
OK, 1 record affected.

aql> select * from bar where PK=1
+-------+
| value |
+-------+
| 1     |
+-------+
1 row in set (0.001 secs)

OK

aql>exit
```

Stop Aerospike

```
aerospike_local/usr/bin/run-asd-non-root.sh stop
```

If you don't have a feature key, you can install Aerospike Community by using the -o flag with the installer

```
./install-aerospike-non-root.sh -o -c aerospike.template.conf 
```

## Usage

As before, unpack the supplied archive.

The install runs with the following options

```
Usage : install-aerospike-non-root.sh -c <AEROSPIKE_CONFIG_PATH> -f <FEATURE_KEY_FILE> [ -d INSTALL_DIRECTORY] [ -v AEROSPIKE_VERSION ] [ -p DATA_PARTITION ] [-o] [ -i DISTRIBUTION ]
```

**AEROSPIKE_CONFIG_PATH** - path to the Aerospike configuration file to be used when installing Aerospike (aerospike.conf)  
**FEATURE_KEY_FILE** - Enterprise feature key file allowing operation of Enterprise Aerospike  
**INSTALL_DIRECTORY** - Directory you would like Aerospike installed to. Will default to aerospike_local in the local directory  
**AEROSPIKE_VERSION** - Version of Aerospike you would like to install e.g. 4.8.0.5. See [releases](https://www.aerospike.com/enterprise/download/server/notes.html) for full list. Defaults to keyword 'latest' which will install the latest release.  
**DATA_PARTITION** - Directory or file to be used for the *DATA_PARTITION* token - see below  
**DISTRIBUTION** - Distribution to be used - must be one of el6/el7/el8/debian8/debian9/debian10/ubuntu14/ubuntu16/ubuntu18. Defaults to el6
**-o** - Install Community rather than Enterprise Aerospike. *FEATURE_KEY_FILE* is not required when using this flag  

If using the *INSTALL_DIRECTORY* option you should start Aerospike using

```
INSTALL_DIRECTORY/usr/bin/run-asd-non-root.sh start
```

All utilities should be similarly prefixed e.g.

```
INSTALL_DIRECTORY/usr/bin/aql
```

## Configuration Template

A number of special tokens are recognized in the configuration file - this is specific to this install rather than being true of Aerospike in general. These tokens will be replaced as follows

**#ASD_USER#** - replaced by the current user id  
**#ASD_GROUP#** - replaced by the current group id  
**#LOCAL_AEROSPIKE_DIR#** - replaced by the value of *INSTALL_DIRECTORY*  
**#FD_LIMIT#** - replaced with the current value of ulimit -n (open file descriptor limit). This is used to work around the fact that non-privileged users often have low limits for this value. A standard required value for Aerospike is 15000 (set as [proto-fd-max](https://www.aerospike.com/docs/reference/configuration/#proto-fd-max)). You will see a warning if the upper limit is lower than our recommended value.  
**#DATA_FILE#** - replaced by the value of *DATA_PARTITION* above. This is used to set up a basic filesystem based namespace in the quick start.

There is no real need to make use of these tokens in a custom *aerospike.conf* - they are used here to support quick setup.

## Dependencies

* rpm
* cpio
* Standard utilities - which,diff,getopts