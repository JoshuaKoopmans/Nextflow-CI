# Specify intented nextflow version to use
ARG NEXTFLOW_VERSION=19.10.0

# Use image containing Nextflow as base
FROM nextflow/nextflow:${NEXTFLOW_VERSION}

LABEL maintainer="joshua.abc@hotmail.com"
LABEL version="0.1"
LABEL description="This Dockerfile serves the purpose of building a nextflow pipeline testing image."

