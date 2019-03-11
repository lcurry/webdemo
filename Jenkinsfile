#!groovy
podTemplate(
  label: "jenkins-agent-appdev",
  cloud: "openshift",
  inheritFrom: "maven",
  containers: [
    containerTemplate(
      name: "jnlp",
      //image: "docker-registry.default.svc:5000/basic-spring-boot-build/jenkins-agent-appdev",
      image: "docker-registry.default.svc:5000/basic-spring-boot-build/jenkins-agent-appdev",
      // image: "172.30.1.1:5000/basic-spring-boot-build/jenkins-slave-gradle",
      // image: "openshift3/jenkins-slave-maven-rhel7",
      resourceRequestMemory: "1Gi",
      resourceLimitMemory: "2Gi",
      resourceRequestCpu: "1",
      resourceLimitCpu: "2"
    )
  ]
) {
  node('jenkins-agent-appdev') {
    echo "Starting Jenkinsfile"
    // Define Maven Command to point to the correct
    // settings for our Nexus installation
    def mvnCmd = "mvn -s ../nexus_settings.xml"

    // Checkout Source Code.
    stage('Checkout Source') {
      checkout scm
    }

      // The following variables need to be defined at the top level
      // and not inside the scope of a stage - otherwise they would not
      // be accessible from other stages.
      // Extract version from the pom.xml
      // def version = getVersionFromPom("pom.xml")
      // TODO  - hardcode version for now 
      def version = "1.0"
      
      // TBD Set the tag for the development image: version + build number
      def devTag  = ""
      // Set the tag for the production image: version
      def prodTag = ""

	OUTPUT_LS = sh (
    		script: 'ls -al',
    		returnStdout: true
		).trim()
	echo "Output of ls command : ${OUTPUT_LS}";

      // Using Maven build the war file
      // Do not run tests in this step
      stage('Build war') {
        echo "Building version ${devTag} !"
        echo "JAVA_HOME = ${JAVA_HOME}"
        echo "PATH = ${PATH}"

        // Execute gradle Build
          sh "gradle --debug build"
        
      }

      // TBD: The next two stages should run in parallel

      // Using Maven run the unit tests
      stage('Unit Tests') {
        echo "Running Unit Tests"

        // TBD: Execute Unit Tests
      }

      // Using Maven to call SonarQube for Code Analysis
      stage('Code Analysis') {
        echo "Running Code Analysis"

        // TBD: Execute Sonarqube Tests
      }

      // Publish the built war file to Nexus
      stage('Publish to Nexus') {
        echo "Publish to Nexus"

        // TBD: Publish to Nexus
      }

      // Build the OpenShift Image in OpenShift and tag it.
      stage('Build and Tag OpenShift Image') {
        echo "Building OpenShift container image tasks:${devTag}"

        // TBD: Build Image, tag Image
          // Start Binary Build in OpenShift using the file we just published
          // The filename is openshift-tasks.war in the 'target' directory of your current
          // Jenkins workspace

//          withEnv(["version=${version}"]) {

	// get output of directory content 

        sh 'oc start-build webdemo --from-dir . --follow  -n basic-spring-boot-dev --build-loglevel=5'
               // sh "oc new-build --name=tasks --image-stream=jboss-eap70-openshift --binary=true --labels=app=tasks -n ${DEV_PROJECT} || true"
               // build image
               // sh "oc start-build tasks --from-dir=oc-build --wait=true -n ${DEV_PROJECT}"
 
//	  }
      }

      // Deploy the built image to the Development Environment.
      stage('Deploy to Dev') {
        echo "Deploying container image to Development Project"

        // TBD: Deploy to development Project
        //      Set Image, Set VERSION
        //      Make sure the application is running and ready before proceeding

      }

      // Copy Image to Nexus container registry
      stage('Copy Image to Nexus container registry') {
        echo "Copy image to Nexus container registry"

        // TBD: Copy image to Nexus container registry

        // TBD: Tag the built image with the production tag.
      }

      // Blue/Green Deployment into Production
      // -------------------------------------
      def destApp   = "tasks-green"
      def activeApp = ""

      stage('Blue/Green Production Deployment') {
        // TBD: Determine which application is active
        //      Set Image, Set VERSION
        //      Deploy into the other application
        //      Make sure the application is running and ready before proceeding
      }

      stage('Switch over to new Version') {
        echo "Switching Production application to ${destApp}."
        // TBD: Execute switch
      }
  }
}

// Convenience Functions to read version from the pom.xml
// Do not change anything below this line.
// --------------------------------------------------------
def getVersionFromPom(pom) {
  def matcher = readFile(pom) =~ '<version>(.+)</version>'
  matcher ? matcher[0][1] : null
}
