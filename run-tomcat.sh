#!/bin/bash
# description: Tomcat Start

#JAVA_HOME=/usr/java/jdk1.7.0_09
JAVA_HOME=/usr/bin/java
export JAVA_HOME

PATH=$JAVA_HOME/bin:$PATH

export PATH

#CATALINA_HOME=/usr/share/apache-tomcat-7.0.32
CATALINA_HOME=/usr/share/tomcat

CATALINA_BASE=$CATALINA_HOME
cd $CATALINA_HOME
echo "start tomcat goes here!"
java \
    -classpath $CATALINA_HOME/bin/bootstrap.jar:$CATALINA_HOME/bin/tomcat-juli.jar \
    -Dcatalina.home=$CATALINA_HOME \
    -Dcatalina.base=$CATALINA_BASE \
    -Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager \
    -Djava.util.logging.config.file=$CATALINA_BASE/conf/logging.properties \
    org.apache.catalina.startup.Bootstrap


#sh $CATALINA_HOME/bin/startup.sh


