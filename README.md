# Sample webdemo


To build using gradle. This will place the .war file in ./build/libs/webdemo.war

$ gradle build      

Local Docker 
To build the docker image

$ docker build . -t webdemo:1.0

$ docker image ls

Run --name <unique name of container>  <image name : tag>

$ docker run  -p 8080:8080 -d  --name webdemo-7  webdemo:1.3

To stand up with embedded tomcat for test (no Docker):

$ gradle appRun

From browser go to following URL:

http://localhost:8080/webdemo

# Running in Openshift 
Create new app with Dockerfile strategy (docker file in current . directory)
Several objects were created as a result, including a Service, Route, ImageStream, BuildConfig and a DeploymentConfig

$ oc new-app --name webdemo . --strategy=docker

This will not trigger the build so must trigger and tell location of source

$ oc start-build bc/webdemo  --from-dir .

To see the service

$ oc get service


Create a route
$ oc expose svc/webdemo

Go here to see:
http://webdemo-basic-spring-boot-build.192.168.99.100.nip.io/webdemo/
