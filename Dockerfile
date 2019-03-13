FROM openshift/jboss-webserver31-tomcat8-openshift:1.2

ADD logging.properties /usr/share/tomcat/conf/logging.properties

EXPOSE 8080

ADD wars/* /deployments/
ADD config/* /opt/nrl/demo/config/
USER root
RUN chown -R 1001:0 /deployments && chmod -R a+rw /deployments
RUN chown -R 1001:0 /opt/nrl && chmod -R a+rw /opt/nrl
