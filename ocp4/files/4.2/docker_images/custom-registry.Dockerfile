FROM registry.redhat.io/openshift4/ose-operator-registry:latest

COPY manifests manifests

# ENV DEBUGLOG true
# RUN pwd

RUN /bin/initializer -o ./bundles.db

EXPOSE 50051

ENTRYPOINT ["/usr/bin/registry-server"]

CMD ["--database", "/registry/bundles.db"]