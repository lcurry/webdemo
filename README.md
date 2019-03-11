# Sample webdemo

## Steps to run webdemo inside Openshift 

### 1) Setup Infrastructure
Setup infrastructure CICD projects for jenkins and DEV, Test, PROD projects
The step will set up Openshift, e.g. create separate namespaces/projects, deploy Jenkins, and create the
objects necessary for this demo.

Login to openshift.
To login as administrator on minishift:
```
    oc login -u system:admin
```
You will use the applier framework to setup the infrastructure.
Clone the repo here:
https://github.com/redhat-cop/container-pipelines/tree/master/basic-tomcat
Run the following commands :
```
ansible-galaxy install -r requirements.yml --roles-path=galaxy
ansible-playbook -i .applier/ galaxy/openshift-applier/playbooks/openshift-cluster-seed.yml
```
After performing this step you'll have the following projects created in Openshift.
basic-tomcat-build
basic-tomcat-dev
basic-tomcat-stage
basic-tomcat-prod

And Jenkins should be available running in openshift via URL. May take a few minustes to become available. 


### 2) Create Jenkins Slave agent Image  
Create Custom "slave" Agent container for Jenkins.  This image will be specified in the Jenkinsfile as our build image.  
We need this step if our build image requires anything above and beyond standard build images. 
*Note we determined probably don't need gradle.*
We can add anything else we might need for the build.
As an example base image, we built our base imaage using the Dockerfile.rhel7 found here:

https://github.com/redhat-cop/containers-quickstarts/tree/master/jenkins-slaves/jenkins-slave-gradle
```
$ cat Dockerfile.rhel7 | oc new-build --name jenkins-agent-appdev --dockerfile='-' -n basic-spring-boot-build
$ oc start-build jenkins-agent-appdev --follow -n basic-spring-boot-build
```

Above will create image in Openshift registry
```
$ oc get is
jenkins-agent-appdev       172.30.1.1:5000/basic-spring-boot-build/jenkins-agent-appdev       latest    About a minute ago
```


### 3) Create Jenkins pipeline buildConfig 
Create pipeline build config pointing to the Git REPO that holds Jenkinsfile.
Alternatively could include Jenkinsfile inline in buildConfig .yml. 
The following will create a jenkins pipeline BuildConfig that will automatically show up in Jenkins
```
oc create -n basic-spring-boot-build -f - <<EOF
apiVersion: v1
items:
- kind: "BuildConfig"
  apiVersion: "v1"
  metadata:
    name: "webdemo-pipeline"
  spec:
    source:
      contextDir: "."
      type: "Git"
      git:
        reg: "dev"
        uri: "https://github.com/lcurry/webdemo.git"
    strategy:
      type: "JenkinsPipeline"
      jenkinsPipelineStrategy:
        jenkinsfilePath: Jenkinsfile
kind: List
metadata: []
EOF
```

The above points to the public repo that contains the webdemo app.  

### 3) Create mew buildConfig that will be started (triggered) from the Jenkinsfile (associated with above Jenkins Pipeline Build Config).  See Jenkinsfile for starting the bulid using the buildConfig created in this step.
To create the new build config
```
oc new-build --strategy=docker --binary=true --docker-image centos:centos7 --name webdemo -n basic-spring-boot-dev
```
The above command will create a new buildConfig that will be used to create the runtime image (from existing Dockerfile) for the application via a builder based on centos.



### 4) Trigger the build  
From within Jenkins (within Openshift) use the webdemo-pipeline to start new build. 
This will cause the Jenkinsfile to run. 



## Steps to run locally 

To build using gradle. This will place the .war file in ./build/libs/webdemo.war
```
$ gradle build      
```

Local Docker 
To build the docker image
```
$ docker build . -t webdemo:1.0

$ docker image ls
```
To run docker image in container in daemon mode exposing port 8080
```
$ docker run  -p 8080:8080 -d  --name webdemo-7  webdemo:1.3
```
To stand up with embedded tomcat for test (no Docker):
```
$ gradle appRun
```
From browser go to following URL:

http://localhost:8080/webdemo

## Deploy to Openshift  (without Jenkins Pipeline)
Create new app with Dockerfile strategy (docker file in current . directory)
Several objects were created as a result, including a Service, Route, ImageStream, BuildConfig and a DeploymentConfig
```
$ oc new-app --name webdemo . --strategy=docker
```
This will not trigger the build so must trigger and tell location of source
```
$ oc start-build bc/webdemo  --from-dir .
```
To see the service
```
$ oc get service
```

Create a route
```
$ oc expose svc/webdemo
```
Go here to see:
http://webdemo-basic-spring-boot-build.192.168.99.100.nip.io/webdemo/
