FROM registry.sigma.cmri/test/nttmec_gpu

# RUN chown -R root: /var/
RUN chown -R root: /opt

COPY gpu_start.sh /opt/start.sh