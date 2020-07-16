FROM registry.access.redhat.com/ubi8/nodejs-10

# RUN npm config list

# USER 1001

COPY .npmrc /opt/app-root/src/
COPY .bowerrc /opt/app-root/src/
