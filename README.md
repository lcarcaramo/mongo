# Tags
> _Built from [`quay.io/ibm/ubuntu:18.04`](https://quay.io/repository/ibm/ubuntu?tab=info)_
-	`4.4.1` - [![Build Status](https://travis-ci.com/lcarcaramo/mongo.svg?branch=master)](https://travis-ci.com/lcarcaramo/mongo)

### __[Original Source Code](https://github.com/docker-library/mongo)__

# MongoDB

MongoDB is a [free and open-source cross-platform document-oriented database](https://en.wikipedia.org/wiki/Document-oriented_database) program. Classified as a [NoSQL](https://en.wikipedia.org/wiki/NoSQL) database program, MongoDB uses [JSON](https://en.wikipedia.org/wiki/JSON)-like documents with [schemata](https://en.wikipedia.org/wiki/Database_schema). MongoDB is developed by [MongoDB Inc.](https://en.wikipedia.org/wiki/MongoDB_Inc.), and is published under a combination of the [Server Side Public License](https://www.mongodb.com/licensing/server-side-public-license) and the [Apache License](https://en.wikipedia.org/wiki/Apache_License).

First developed by the software company 10gen (now MongoDB Inc.) in October 2007 as a component of a planned platform as a service product, the company shifted to an open source development model in 2009, with 10gen offering commercial support and other services. Since then, MongoDB has been adopted as backend software by a number of major websites and services, including MetLife, Barclays, ADP, UPS, Viacom, and the New York Times, among others. MongoDB is the most popular NoSQL database system.

> [wikipedia.org/wiki/MongoDB](https://en.wikipedia.org/wiki/MongoDB)



# How to use this image

## Start a `mongo` server instance

```console
$ docker run --name some-mongo -d quay.io/ibm/mongo:4.4.1
```

... where `some-mongo` is the name you want to assign to your container and `4.4.1` is the tag specifying the MongoDB version you want. See the list above for relevant tags.

## Connect to MongoDB from another Docker container

The MongoDB server in the image listens on the standard MongoDB port, `27017`, so connecting via Docker networks will be the same as connecting to a remote `mongod`. The following example starts another MongoDB container instance and runs the `mongo` command line client against the original MongoDB container from the example above, allowing you to execute MongoDB statements against your database instance:

```console
$ docker run -it --network some-network --rm quay.io/ibm/mongo:4.4.1 mongo --host some-mongo test
```

... where `some-mongo` is the name of your original `mongo` container.

## Container shell access and viewing MongoDB logs

The `docker exec` command allows you to run commands inside a Docker container. The following command line will give you a bash shell inside your `mongo` container:

```console
$ docker exec -it some-mongo bash
```

The MongoDB Server log is available through Docker's container log:

```console
$ docker logs some-mongo
```

## Configuration

See the [MongoDB manual](https://docs.mongodb.com/manual/) for information on using and configuring MongoDB for things like replica sets and sharding.

## Customize configuration without configuration file

Most MongoDB configuration can be set through flags to `mongod`. The entrypoint of the image is created to pass its arguments along to `mongod`. See below an example of setting MongoDB to use a different [threading and execution model](https://docs.mongodb.com/manual/reference/program/mongod/#cmdoption-mongod-serviceexecutor) via `docker run`.

```console
$ docker run --name some-mongo -d quay.io/ibm/mongo:4.4.1 --serviceExecutor adaptive
```

To see the full list of possible options, check the MongoDB manual on [`mongod`](https://docs.mongodb.com/manual/reference/program/mongod/) or check the `--help` output of `mongod`:

```console
$ docker run -it --rm quay.io/ibm/mongo:4.4.1 --help
```

## Setting WiredTiger cache size limits

By default Mongo will set the `wiredTigerCacheSizeGB` to a value proportional to the host's total memory regardless of memory limits you may have imposed on the container. In such an instance you will want to set the cache size to something appropriate, taking into account any other processes you may be running in the container which would also utilize memory.

Taking the examples above you can configure the cache size to use 1.5GB as:

```console
$ docker run --name some-mongo -d quay.io/ibm/mongo:4.4.1 --wiredTigerCacheSizeGB 1.5
```

See [the upstream "WiredTiger Options" documentation](https://docs.mongodb.com/manual/reference/program/mongod/#wiredtiger-options) for more details.

## Using a custom MongoDB configuration file

For a more complicated configuration setup, you can still use the MongoDB configuration file. `mongod` does not read a configuration file by default, so the `--config` option with the path to the configuration file needs to be specified. Create a custom configuration file and put the configuration file in the container by putting it in a Docker volume and then mounting that volume to the container. See the MongoDB manual for a full list of [configuration file](https://docs.mongodb.com/manual/reference/configuration-options/) options.

For example, the docker volume `mongo-config` contains the custom configuration file at `/mongod.conf`. Then run a `quay.io/ibmz/mongo:4.4.0` container with the `mongo-config` volume attached, and the `--config /etc/mongo/mongod.conf` command passed in.

```console
$ docker run --name custom-mongo-container -v mongo-config:/etc/mongo/ -d quay.io/ibm/mongo:4.4.0 --config /etc/mongo/mongod.conf
```

## Environment Variables

When you start the `mongo` image, you can adjust the initialization of the MongoDB instance by passing one or more environment variables on the `docker run` command line. Do note that none of the variables below will have any effect if you start the container with a data directory that already contains a database: any pre-existing database will always be left untouched on container startup.

### `MONGO_INITDB_ROOT_USERNAME`, `MONGO_INITDB_ROOT_PASSWORD`

These variables, used in conjunction, create a new user and set that user's password. This user is created in the `admin` [authentication database](https://docs.mongodb.com/manual/core/security-users/#user-authentication-database) and given [the role of `root`](https://docs.mongodb.com/manual/reference/built-in-roles/#root), which is [a "superuser" role](https://docs.mongodb.com/manual/core/security-built-in-roles/#superuser-roles).

The following is an example of using these two variables to create a MongoDB instance and then using the `mongo` cli to connect against the `admin` authentication database.

```console
$ docker run -d --network some-network --name some-mongo \
	-e MONGO_INITDB_ROOT_USERNAME=mongoadmin \
	-e MONGO_INITDB_ROOT_PASSWORD=secret \
	quay.io/ibm/mongo:4.4.1

$ docker run -it --rm --network some-network mongo \
	quay.io/ibm/mongo:4.4.1 --host some-mongo \
		-u mongoadmin \
		-p secret \
		--authenticationDatabase admin \
		some-db
> db.getName();
some-db
```

Both variables are required for a user to be created. If both are present then MongoDB will start with authentication enabled (`mongod --auth`).

Authentication in MongoDB is fairly complex, so more complex user setup is explicitly left to the user via `/docker-entrypoint-initdb.d/` (see the *Initializing a fresh instance* and *Authentication* sections below for more details).

### `MONGO_INITDB_DATABASE`

This variable allows you to specify the name of a database to be used for creation scripts in `/docker-entrypoint-initdb.d/*.js` (see *Initializing a fresh instance* below). MongoDB is fundamentally designed for "create on first use", so if you do not insert data with your JavaScript files, then no database is created.

## Docker Secrets

As an alternative to passing sensitive information via environment variables, `_FILE` may be appended to the previously listed environment variables, causing the initialization script to load the values for those variables from files present in the container. In particular, this can be used to load passwords from Docker secrets stored in `/run/secrets/<secret_name>` files. This is only available when using docker swarm or docker compose to run your containers. For example with docker swarm enabled:

```console
$ printf "/my/mongo/root" | docker secret create mongo-root -
$ docker service create
    --name some-mongo
    --secret mongo-root
    --env MONGO_INITDB_ROOT_PASSWORD_FILE=/run/secrets/mongo-root"
    quay.io/ibm/mongo:4.4.1  
```

Currently, this is only supported for `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD`.

# Initializing a fresh instance

When a container is started for the first time it will execute files with extensions `.sh` and `.js` that are found in `/docker-entrypoint-initdb.d`. Files will be executed in alphabetical order. `.js` files will be executed by `mongo` using the database specified by the `MONGO_INITDB_DATABASE` variable, if it is present, or `test` otherwise. You may also switch databases within the `.js` script.

# Authentication

As noted above, authentication in MongoDB is fairly complex (although disabled by default). For details about how MongoDB handles authentication, please see the relevant upstream documentation:

-	[`mongod --auth`](https://docs.mongodb.com/manual/reference/program/mongod/#cmdoption-mongod-auth)
-	[Security > Authentication](https://docs.mongodb.com/manual/core/authentication/)
-	[Security > Role-Based Access Control](https://docs.mongodb.com/manual/core/authorization/)
-	[Security > Role-Based Access Control > Built-In Roles](https://docs.mongodb.com/manual/core/security-built-in-roles/)
-	[Security > Enable Auth (tutorial)](https://docs.mongodb.com/manual/tutorial/enable-authentication/)

In addition to the `/docker-entrypoint-initdb.d` behavior documented above (which is a simple way to configure users for authentication for less complicated deployments), this image also supports `MONGO_INITDB_ROOT_USERNAME` and `MONGO_INITDB_ROOT_PASSWORD` for creating a simple user with [the role `root`](https://docs.mongodb.com/manual/reference/built-in-roles/#root) in the `admin` [authentication database](https://docs.mongodb.com/manual/core/security-users/#user-authentication-database), as described in the *Environment Variables* section above.

# Caveats

## Where to Store Data

Use Docker volumes.

```console
$ docker volume create <mongodb volume>
```

This image also defines a volume for `/data/configdb` [for use with `--configsvr` (see docs.mongodb.com for more details)](https://docs.mongodb.com/v3.4/reference/program/mongod/#cmdoption-configsvr).

## Creating database dumps

Most of the normal tools will work, although their usage might be a little convoluted in some cases to ensure they have access to the `mongod` server. A simple way to ensure this is to use `docker exec` and run the tool from the same container, similar to the following:

```console
$ docker exec some-mongo sh -c 'exec mongodump -d <database_name> --archive' > /some/path/on/your/host/all-collections.archive
```

# License

View [license information](https://github.com/mongodb/mongo/blob/6ea81c883e7297be99884185c908c7ece385caf8/README#L89-L95) for the software contained in this image.

It is relevant to note the change from AGPL to SSPLv1 for all versions after October 16, 2018.

As with all Docker images, these likely also contain other software which may be under other licenses (such as Bash, etc from the base distribution, along with any direct or indirect dependencies of the primary software being contained).

Some additional license information which was able to be auto-detected might be found in [the `repo-info` repository's `mongo/` directory](https://github.com/docker-library/repo-info/tree/master/repos/mongo).

As for any pre-built image usage, it is the image user's responsibility to ensure that any use of this image complies with any relevant licenses for all software contained within.
