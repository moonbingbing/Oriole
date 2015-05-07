FROM 		ubuntu:14.04

RUN apt-get update

#install wget curl htop vim
RUN apt-get install -y wget
RUN apt-get install -y curl
RUN apt-get install -y htop
RUN apt-get install -y vim

RUN apt-get install -y phantomjs

# install HHVM
#RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0x5a16e7281be7a449
#RUN echo "deb http://dl.hhvm.com/ubuntu trusty main" > /etc/apt/sources.list.d/pgdg.list
#RUN apt-get update
#RUN apt-get install -y hhvm

#install redis
RUN apt-get install -y redis-server
RUN sed 's/^appendonly no/appendonly yes/' -i /etc/redis/redis.conf

#install beanstalkd
RUN apt-get install -y beanstalkd && mkdir /var/lib/beanstalkd/binlog



#install supervisor
RUN apt-get install -y supervisor



EXPOSE 80 8080 9001 11300

CMD ["/usr/bin/supervisord"]


