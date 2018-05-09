FROM centos
MAINTAINER vinay.khandalkar
ENV container docker
RUN yum update -y;
#RUN yum -y install systemd; \
#(cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
# rm -f /lib/systemd/system/multi-user.target.wants/*;\
# rm -f /etc/systemd/system/*.wants/*;\
# rm -f /lib/systemd/system/local-fs.target.wants/*; \
# rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
# rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
# rm -f /lib/systemd/system/basic.target.wants/*;\
# rm -f /lib/systemd/system/anaconda.target.wants/*;
# VOLUME [ “/sys/fs/cgroup” ]
# CMD [“/usr/sbin/init”]
RUN yum install curl wget httpd sudo php openldap* sendmail sssd vim lynx net-tools openssh-clients -y;
RUN yum install -y git-core zlib zlib-devel gcc-c++ patch readline readline-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison curl sqlite-devel net-tools tcpdump;
#RUN wget https://toolbelt.treasuredata.com/sh/install-redhat-td-agent2.sh \
# && sh install-redhat-td-agent2.sh -y \
# && service td-agent start \
# && service td-agent status;
#RUN passwd root <<-EOF
#redhat
#redhat
#EOF

#RUN /opt/td-agent/embedded/bin/fluent-gem install fluent-plugin-secure-forward;
#RUN /opt/td-agent/embedded/bin/gem install fluent-plugin-splunk-ex;
RUN echo $'[domain/default]\n\
ldap_id_use_start_tls = True\n\
cache_credentials = True\n\
ldap_search_base = dc=int,dc=asurion,dc=com\n\
id_provider = ldap\n\
access_provider = simple\n\
auth_provider = ldap\n\
chpass_provider = ldap\n\
ldap_uri = ldaps://dolomite.int.asurion.com:636,ldaps://malachite.int.asurion.com:636\n\
ldap_tls_reqcert = allow\n\
ldap_access_order = host\n\
simple_allow_users = svc.US-p-chef-mgr\n\
simple_allow_groups = bofh, ent_srvaccts_hosts\n\
debug_level = 6\n\
[sssd]\n\
services = nss, pam\n\
config_file_version = 2\n\
debug_level = 6\n\
domains = default\n\
[nss]\n\
debug_level = 6\n\
[pam]\n\
debug_level = 6\n\
[sudo]\n\
[autofs]\n\
[ssh]\n\
debug_level = 6\n\
[pac]\n'\
> /etc/sssd/sssd.conf
RUN chmod 600 /etc/sssd/sssd.conf;
RUN echo $'127.0.0.1	localhost localhost.localdomain localhost4 localhost4.localdomain4'\
>> /etc/hosts;
RUN rm -rf /run/sssd.pid
RUN /usr/sbin/sssd -i -f /var/log/sssd/sssd.log &
RUN echo $'base dc=int,dc=asurion,dc=com\n\
uri ldaps://dolomite.int.asurion.com:636 ldaps://malachite.int.asurion.com:636\n\
timelimit 120\n\
bind_timelimit 120\n\
idle_timelimit 3600\n\
ssl on\n\
tls_reqcert never\n\
tls_checkpeer no\n\
pam_check_host_attr yes\n'\
> /etc/openldap/ldap.conf;
RUN echo $'ip=`hostname -i`\n\
echo -e "$ip ldprst.int.asurion.com ldprst\n\
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4" >> /etc/hosts\n\
/usr/sbin/httpd -D FOREGROUND\n'\
> /tmp/script.sh;
RUN chmod 777 /tmp/script.sh
RUN echo $'<VirtualHost *:8081>\n\
  DocumentRoot /var/www/html\n\
  DirectoryIndex ldapreset.php\n\
  CustomLog /dev/stdout combined\n\
  ErrorLog /dev/stdout\n\
</VirtualHost>\n'\
> /etc/httpd/conf.d/ldap_reset.conf;
RUN echo $'ldprst.int.asurion.com'\
> /etc/hostname
RUN echo $'Hello this is Openshift httpd'\
> /var/www/html/ldapreset.php
RUN echo $'ServerName test.oso.com:8081'\
>> /etc/httpd/conf/httpd.conf
RUN sed -i 's/Listen 80/Listen 8081/g' /etc/httpd/conf/httpd.conf
#EXPOSE 24284
EXPOSE 8081
#RUN echo $'#httpd &\n\
#td-agent -c /etc/td-agent/td-agent.conf -o /var/log/td-agent/td-agent.log &'\
#> /tmp/script.sh
#RUN chmod 777 /tmp/script.sh
#RUN mkdir -p /etc/td-agent/certs
RUN mkdir -p /opt/ldapreset/tmp\
 && mkdir -p /run/httpd/\
 && chmod -R 777 /run/httpd;
RUN chmod -R 777 /etc/httpd\
 && chmod -R 777 /var/log/httpd\
 && chmod -R 777 /usr/lib64/httpd/modules\
 && chown -R apache:apache /opt/ldapreset/tmp\
 && chmod -R 755 /opt/ldapreset/tmp;
#RUN touch /var/log/td-agent/td-agent.log
#RUN chmod -R 777 /var/log/td-agent/
#CMD ["/usr/sbin/httpd", "-D", "FOREGROUND"]
ENTRYPOINT ["/bin/bash", "/tmp/script.sh"]
#CMD ["/usr/sbin/td-agent", "-c", "/etc/td-agent/td-agent.conf", "-o", "/var/log/td-agent/td-agent.log"]
#ENTRYPOINT ["/bin/bash", "/tmp/script.sh"]
#RUN /bin/bash /tmp/script.sh
#CMD ["sh", "/tmp/script.sh"]
