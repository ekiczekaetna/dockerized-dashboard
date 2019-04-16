FROM ruby:2.6.2

RUN apt-get update && \
    apt-get -y install nodejs && \
    apt-get -y clean
RUN gem install bundler smashing

COPY /smashing /smashing
RUN cd /smashing && bundle

COPY run.sh /

ENV PORT 3030
EXPOSE $PORT
WORKDIR /smashing

CMD ["/run.sh"]
