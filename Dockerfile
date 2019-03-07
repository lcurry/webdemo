FROM openshift/rhel7

#MAINTAINER http://www.centos.org
#LABEL Vendor="CentOS"

#ADD CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo
#ADD epel.repo /etc/yum.repos.d/epel.repo
#ADD RPM-GPG-KEY-EPEL-7 /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

RUN yum -y update && yum -y install java tomcat && yum clean all

#ADD logging.properties /usr/share/tomcat/conf/logging.properties
ADD run-tomcat.sh /run-tomcat.sh
RUN chmod -v +x /run-tomcat.sh

RUN mkdir /logs
RUN chmod -v -R a+rw /logs

EXPOSE 8080

#ADD wars/* /var/lib/tomcat/webapps/
ADD build/libs/* /var/lib/tomcat/webapps/
#ADD config/* /opt/nrl/demo/config/

CMD ["/run-tomcat.sh"]
