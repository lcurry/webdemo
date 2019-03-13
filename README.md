# Sample webdemo

## Steps to run webdemo inside Openshift 

### 1) Setup Infrastructure
Setup infrastructure CICD projects for jenkins and DEV, Test, PROD projects
The step will set up Openshift, e.g. create separate namespaces/projects, deploy Jenkins, and create the
objects necessary for this demo.

Login to openshift.
To login as administrator on minishift:
```
    oc login -u admin
```
You will use the applier framework to setup the infrastructure.
Clone the repo here:
https://github.com/redhat-cop/container-pipelines/tree/master/basic-spring-boot
Run the following commands :
```
ansible-galaxy install -r requirements.yml --roles-path=galaxy
ansible-playbook -i .applier/ galaxy/openshift-applier/playbooks/openshift-cluster-seed.yml
```
After performing this step you'll have the following projects created in Openshift.
basic-spring-boot-build
basic-spring-boot-dev
basic-spring-boot-stage
basic-spring-boot-prod

And Jenkins should be available running in openshift via URL. May take a few minustes to become available. 


### 2) Create Jenkins Slave agent Image  
Create Custom "slave" Agent container for Jenkins.  This image will be specified in the Jenkinsfile as our build image.  
We need this step if our build image requires anything above and beyond standard build images. 
E.g. Gradle, JDK, and Mercurial client.
We can add anything else we might need for the build.
As an example base image, we built our base imaage using the Dockerfile.rhel7 found here:

https://github.com/lcurry/jenkins-slave-gradle/blob/master/Dockerfile.rhel7

Note: the Dockerfile above references a password file 'hgrc.rhel7' that is not included in the source control repo.
You will need to create a file in the same directory containing the following content 
(update appropriately for your environment)

```
[auth]
mingus.prefix = https://path to your repo goes here
mingus.username = scm user name goes here
mingus.password = password goes here

```
You can then run the following commands to build the image inside Openshift:

```
$ cat Dockerfile.rhel7 | oc new-build --name jenkins-agent-appdev --dockerfile='-' -n basic-spring-boot-build
$ oc start-build jenkins-agent-appdev --follow -n basic-spring-boot-build
```

Above will create image in Openshift registry
```
$ oc get is -n basic-spring-boot-build
jenkins-agent-appdev       172.30.1.1:5000/basic-spring-boot-build/jenkins-agent-appdev       latest    About a minute ago
```


### 3) Create Jenkins pipeline buildConfig 
Create pipeline build config pointing to the Git REPO that holds Jenkinsfile.
Alternatively could include Jenkinsfile inline in buildConfig .yml. 
The following will create a jenkins pipeline BuildConfig that will automatically show up in Jenkins.
(Note this command will create the buildConfig directly from the in-line yaml.  An alternative approach would 
be to create the buldConfig with 'oc new-build' passing the appropriate options. Either technique result in the same
buildConfig object created in Openshift.)   
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
        ref: "master"
        uri: "https://URL for SCM goes here/hg/devops/redhat/openshift-cicd-poc"
    strategy:
      type: "JenkinsPipeline"
      jenkinsPipelineStrategy:
        jenkinsfilePath: jenkins-pipeline/Jenkinsfile
kind: List
metadata: []
EOF
```
The above points to the Jenkinsfile in Kallithea git repo.  The buildConfig will also need the credentials for
accessing Kallithea.  These will be included in the buildConfig as souce secrets.  In addition the GIT_SSL_NO_VERIFY=true 
needs to be set in the buildConfig.
Both of these additions to the buildConfig can be made in the Openshift UI or from the command line.

```
Commands TBD
oc create secret generic kallithea-login  --from-literal=username=XXX --from-literal=password=XXX --type=kubernetes.io/basic-auth -n basic-spring-boot-build
oc set build-secret --source bc/webdemo-pipeline kallithea-login -n basic-spring-boot-build

END Commands TBD
```


### 4) Create new buildConfig (docker strategy) for application build. 

This build will be manually started (triggered) from the Jenkinsfile (associated with above Jenkins Pipeline Build Config).  See Jenkinsfile for starting the bulid using the buildConfig created in this step.
To create the new build config.  Note this buildConfig is created in the namespace/project of the DEV environment for deployment 
of the built artifact to DEV.
```
oc new-build --strategy=docker --binary=true  --image-stream=openshift/jboss-webserver31-tomcat8-openshift:1.2 --name servlettemplate-runtime -n basic-spring-boot-dev
```
The above command will create a new buildConfig in the basic-spring-boot-dev project namespace that will be used to create the runtime image (from existing Dockerfile) for the application.  Note: the '--image-stream' param is required for Openshift to pull in the proper image stream that is used as the base image inside the Dockerfile.

### 5) Set up additional application objects in Openshift.
This preperation will create placeholders for the objects in Openshift needed for rollout of the application to openshift.
Certain values in these objects won't get populated until the build is run from the Jenkinsfile.

```
oc new-app --docker-image docker-registry.default.svc:5000/basic-spring-boot-dev/servlettemplate-runtime:0.0-0 --name=servlettemplate-runtime --allow-missing-images -n  basic-spring-boot-dev --insecure-registry
oc set triggers dc/servlettemplate-runtime --remove-all -n  basic-spring-boot-dev
oc expose dc servlettemplate-runtime --port 8080 -n basic-spring-boot-dev
oc expose svc servlettemplate-runtime -n basic-spring-boot-dev
```

In addition, the "route" will need to have the following path added "/OCServletTemplate", and also enable Security.


### 6) Trigger the build  
From within Jenkins (within Openshift) use the webdemo-pipeline to start new build. 
This will cause the Jenkinsfile to run.  Alternatively, you can trigger the build from the command line.
```
oc start-build bc/webdemo-pipeline -n basic-spring-boot-build

```
You can follow the progress of the build from the Jenkins console logs.


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

### 1) Build source 

From the directory where the 'OCServletTemplate' code has been cloned.

```
 ./gradlew copyDockerFiles
```
### 2) Create new (binary) build from Dockerfile and source 
From same directory as build:
```
oc new-build --strategy=docker --binary=true --image-stream=openshift/jboss-webserver31-tomcat8-openshift:1.2  --name servlettemplate-runtime
```
This will create a new buildConfig in Openshift.

### 3) Start build 
This command should also be run from same directory as build:
```
oc start-build servlettemplate-runtime --from-dir=build/docker --follow  --wait
```
This will uploaded Dockerfile and necessary source files to Openshift to run the build and 
create image based on the Dockerfile.  
The new image should now be created and exist in the Openshift image registry.


### 4) Create Application to expose the service  

```
oc new-app --docker-image docker-registry.default.svc:5000/basic-spring-boot-dev/servlettemplate-runtime:latest --name=servlettemplate-runtime --insecure-registry
```

Several objects were created as a result, including a Service, Route, ImageStream, BuildConfig and a DeploymentConfig

Additional builds can be triggerd by running the 'start-build' command above. The new image will automatically be deployed.

### 5) Expose the service by adding proper Path and enable Security
In addition, the "route" will need to have the following path added "/OCServletTemplate", and also enable Security.
You can do this from the Openshift UI under "routes".
