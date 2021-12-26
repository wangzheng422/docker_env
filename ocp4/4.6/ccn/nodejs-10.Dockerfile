FROM registry.access.redhat.com/ubi8/nodejs-10

# RUN npm config list

# USER 1001

# you can leave below rc files to source code
# because it will copy by s2i into /opt/app-root/src
# COPY .npmrc /opt/app-root/src/
# COPY .bowerrc /opt/app-root/src/

RUN npm install -g bower && npm install -g bower-nexus3-resolver

