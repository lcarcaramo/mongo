#!/bin/bash

set -e

export ANSI_YELLOW_BOLD="\e[1;33m"
export ANSI_GREEN="\e[32m"
export ANSI_YELLOW_BACKGROUND="\e[1;7;33m"
export ANSI_GREEN_BACKGROUND="\e[1;7;32m"
export ANSI_CYAN="\e[36m"
export ANSI_RESET="\e[0m"
export DOCKERFILE_TOP="**************************************** DOCKERFILE ******************************************"
export DOCKERFILE_BOTTOM="**********************************************************************************************"
export TEST_SUITE_START="**************************************** SMOKE TESTS *****************************************"
export TEST_SUITE_END="************************************** TEST SUCCESSFUL ***************************************"

# Pass in path to folder where Dockerfile lives
print_dockerfile () {
        echo -e "\n$ANSI_CYAN$DOCKERFILE_TOP\n$(<$1/Dockerfile)\n$ANSI_CYAN$DOCKERFILE_BOTTOM $ANSI_RESET\n"
}

# Pass in test case message
print_test_case () {
        echo -e "\n$ANSI_YELLOW_BOLD$1 $ANSI_RESET"
}

print_success () {
        echo -e "\n$ANSI_GREEN$1 $ANSI_RESET \n"

}

# Pass in path to folder where Dockerfile lives
build () {
        print_dockerfile $1
        docker build -q -t $1 $1
}

cleanup () {
        docker rmi $1
}

suite_start () {
        echo -e "\n$ANSI_YELLOW_BACKGROUND$TEST_SUITE_START$ANSI_RESET \n"
}

suite_end () {
        echo -e "\n$ANSI_GREEN_BACKGROUND$TEST_SUITE_END$ANSI_RESET \n"
}


suite_start
        print_test_case "It can start a new MongoDB container:"
                docker run --rm --name mongodb-container-runs -d quay.io/ibmz/mongo:4.4.1
                export DATABASE_FOUND=$(docker exec mongodb-container-runs mongo --eval db | grep test)
                print_success "Success! The database \"$DATABASE_FOUND\" was found in the started quay.io/ibmz/mongo:4.4.1 container."
                print_success "This is an indication that MongoDB started successfully, and was able to initialize the \"$DATABASE_FOUND\" database."
                print_success "Terminating..."
                docker rm -f mongodb-container-runs
                
        print_test_case "It can connect to a remote MongoDB container:"
                docker run --rm --name remote-mongodb-container -d quay.io/ibmz/mongo:4.4.1
                docker run --network container:remote-mongodb-container --rm quay.io/ibmz/mongo:4.4.1 mongo --host localhost test || exit 1
                print_success "Success! A quay.io/ibmz/mongo:4.4.1 container was able to remotely connnect to another quay.io.ibmz/mongo:4.4.1 container."
                print_success "Terminating remote-mongodb-container..."
                docker rm -f remote-mongodb-container
                
        print_test_case "It can use a custom mongod.conf config file:"
                build "can-use-custom-config-file"
                docker run --name custom-config-container -d "can-use-custom-config-file" --config /etc/mongo/mongod.conf && mongod || exit 1
                print_success "Getting config file from container:"
                docker exec custom-config-container cat /etc/mongo/mongod.conf
                print_success "Success! Custom image that inclues a custom mongod.conf configuration file was created and use to run a container that applies that configuration."
                print_success "Terminating..."
                docker rm -f custom-config-container
                cleanup "can-use-custom-config-file"
suite_end
