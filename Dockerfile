FROM ghost:4-alpine

RUN cd current && npm install ghost-google-cloud-storage
