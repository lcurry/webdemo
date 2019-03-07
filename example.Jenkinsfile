#!groovy
podTemplate(
  label: "jenkins-agent-appdev",
  cloud: "openshift",
  inheritFrom: "maven",
  containers: [
    containerTemplate(
      name: "jnlp",
      image: "docker-registry.default.svc:5000/8ff4-jenkins/jenkins-agent-appdev",
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
    def version = getVersionFromPom("openshift-tasks/pom.xml")

    // TBD Set the tag for the development image: version + build number
    def devTag  = version + "-" + "${env.BUILD_NUMBER}"
    // Set the tag for the production image: version
    def prodTag = version

    // Set Development and Production Project Names
    def jenkinsProject = "8ff4-jenkins"
    def devProject  = "8ff4-tasks-dev"
    def prodProject = "8ff4-tasks-prod"

    // Using Maven build the war file
    // Do not run tests in this step
    stage('Build war') {
      echo "Building version ${devTag}"
      // TBD: Execute Maven Build
      dir("openshift-tasks") {
        sh "${mvnCmd} clean package -DskipTests"
      }
    }

    // TBD: The next two stages should run in parallel

    // Using Maven run the unit tests
    stage('Unit Tests') {
      echo "Running Unit Tests"
      dir("openshift-tasks") {
      // TBD: Execute Unit Tests
      sh "${mvnCmd} test"
      }
    }

    // Using Maven to call SonarQube for Code Analysis
    stage('Code Analysis') {
      echo "Running Code Analysis"
      dir("openshift-tasks") {
      // TBD: Execute Sonarqube Tests
      sh "${mvnCmd} sonar:sonar -Dsonar.host.url=http://sonarqube.gpte-hw-cicd.svc.cluster.local:9000/ -Dsonar.projectName=${JOB_BASE_NAME}-${devTag}"
      }
    }

    // Publish the built war file to Nexus
    stage('Publish to Nexus') {
      echo "Publish to Nexus"
      dir("openshift-tasks") {
        // TBD: Publish to Nexus
        sh "${mvnCmd} deploy -DskipTests=true -DaltDeploymentRepository=nexus::default::http://nexus3.gpte-hw-cicd.svc.cluster.local:8081/repository/releases/"
      }
    }

    // Build the OpenShift Image in OpenShift and tag it.
    stage('Build and Tag OpenShift Image') {

      // TBD: Build Image, tag Image
        echo "Building OpenShift container image tasks !: ${devTag}"

          // Start Binary Build in OpenShift using the file we just published
          // The filename is openshift-tasks.war in the 'target' directory of your current
          // Jenkins workspace

          withEnv(["version=${version}"]) {
           sh 'oc start-build tasks -n 8ff4-tasks-dev -F --from-file=http://nexus3.gpte-hw-cicd.svc.cluster.local:8081/repository/releases/org/jboss/quickstarts/eap/tasks/${version}/tasks-${version}.war'
          }
    }

    stage('Tag image') {
     withEnv(["devTag=${devTag}"]){
      sh 'oc tag 8ff4-tasks-dev/tasks:latest 8ff4-tasks-dev/tasks:${devTag}'
     }
    }

    // Copy Image to Nexus container registry
    stage('Copy Image to Nexus container registry') {
      echo "Copy image to Nexus container registry"

      // TBD: Copy image to Nexus container registry
      echo "Copy the tested container image to the shared Nexus container registry"
      echo "apply cred file workaround"
      sh 'oc whoami -t > result'
      def token = readFile('result').trim()
      //sh "skopeo copy --src-tls-verify=false --dest-tls-verify=false --src-creds openshift:${token} --dest-creds admin:redhat docker://docker-registry.default.svc.cluster.local:5000/${jenkinsProject}/tasks:${devTag} docker://nexus3-registry-gpte-hw-cicd.apps.na311.openshift.opentlc.com/tasks:${devTag}"
      withEnv(["devTag=${devTag}"]){
        sh "skopeo copy --src-tls-verify=false --dest-tls-verify=false --src-creds=openshift:${token} --dest-creds=admin:redhat docker://docker-registry.default.svc.cluster.local:5000/${devProject}/tasks:${devTag} docker://nexus-registry.gpte-hw-cicd.svc.cluster.local:5000/tasks:${devTag}"
      }
      // TBD: Tag the built image with the production tag.
    }

    stage('Deploy to dev') {
    withEnv(["devTag=${devTag}","prodTag=${prodTag}"]){
       sh 'oc set env dc/tasks VERSION="${devTag} (tasks-dev)" -n 8ff4-tasks-dev'
       sh 'oc set image dc/tasks tasks=8ff4-tasks-dev/tasks:${devTag} --source=imagestreamtag -n 8ff4-tasks-dev'
       sh 'oc rollout latest dc/tasks -n 8ff4-tasks-dev'
       sh 'oc tag tasks:${devTag} tasks:${prodTag} -n 8ff4-tasks-dev'

       // wait till deployed and available
       openshift.withCluster() {
         openshift.withProject("${devProject}") {
         //openshift.selector("dc", "tasks").rollout().latest();
         // Wait for application to be deployed
         def dc = openshift.selector("dc", "tasks").object()
         def dc_version = dc.status.latestVersion
         def rc = openshift.selector("rc", "tasks-${dc_version}").object()

         echo "Waiting for ReplicationController tasks-${dc_version} to be ready"
         while (rc.spec.replicas != rc.status.readyReplicas) {
           sleep 5
           rc = openshift.selector("rc", "tasks-${dc_version}").object()
         }
       }
     }  // end check for available


    }
   }

    sh "oc get route tasks --template='{{.spec.to.name}}' -n 8ff4-tasks-prod > activeApp"
    def activeApp = readFile('activeApp').trim()
    def destApp = ""
    if (activeApp == "tasks-blue") {
       destApp   = "tasks-green"
    }
    else {
       destApp   = "tasks-blue"
    }

    stage('Blue/Green Production Deployment') {
        withEnv(["destApp=${destApp}","prodTag=${prodTag}"]){
          sh 'oc set env dc/${destApp} VERSION="${prodTag} (${destApp})" -n 8ff4-tasks-prod'
          sh "oc set image dc/${destApp} ${destApp}=docker-registry.default.svc:5000/8ff4-tasks-dev/tasks:${prodTag} -n 8ff4-tasks-prod"
          sh "oc rollout latest dc/${destApp} -n 8ff4-tasks-prod"
          // wait till depoloyed and available
          openshift.withCluster() {
            openshift.withProject("${prodProject}") {
            //openshift.selector("dc", "tasks").rollout().latest();
            // Wait for application to be deployed
            def dc = openshift.selector("dc", "${destApp}").object()
            def dc_version = dc.status.latestVersion
            def rc = openshift.selector("rc", "${destApp}-${dc_version}").object()

            echo "Waiting for ReplicationController ${destApp}-${dc_version} to be ready"
            while (rc.spec.replicas != rc.status.readyReplicas) {
              sleep 5
              rc = openshift.selector("rc", "${destApp}-${dc_version}").object()
            }
          }
        }  // end check for available

        }
    }

    stage('Switch over to new Version') {
        withEnv(["destApp=${destApp}"])  {
          echo "Switching Production application to ${destApp}."
          sh "oc patch route/tasks -n 8ff4-tasks-prod -p \'{\"spec\":{\"to\":{\"name\":\"${destApp}\"}}}\' -n 8ff4-tasks-prod"
        }
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

