FROM alpine:3.23.4
RUN apk add hugo

# adds theme and content
RUN mkdir -p /app/hugo
COPY ./content /app/hugo
WORKDIR /app/hugo
EXPOSE 6300

#CMD ["hugo", "version"]
CMD ["hugo", "server", "--bind=0.0.0.0"]
#ENTRYPOINT ["hugo", "server", "--logLevel", "debug"]
