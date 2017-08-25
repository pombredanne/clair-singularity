#!/bin/bash

echo "Running setup.py install"
python setup.py install

echo "Running tests that don't need Clair"
pytest tests/ -v -m "not needs_clair" --cov clair_singularity --cov-report term-missing

if [[ $TRAVIS_PYTHON_VERSION == "3.5"* ]]; then
    echo "Python 3.5 - running docker tests with Clair"
    docker pull arminc/clair-db:2017-08-21
    docker run -d --name db arminc/clair-db:2017-08-21
    docker pull arminc/clair-local-scan:v2.0.0
    docker run -p 6060:6060 --link db:postgres -d --name clair arminc/clair-local-scan:v2.0.0
    docker ps
    docker build -t clair_singularity .
    docker run -v $TRAVIS_BUILD_DIR:/app --privileged --name clair-singularity --link clair:clair clair_singularity pytest tests/ -v --cov clair_singularity --cov-report term-missing
    if [ $? -eq 0 ]; then
        coveralls -b $TRAVIS_BUILD_DIR
    fi
fi
