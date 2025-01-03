FROM nvidia/cuda:12.4.1-base-ubuntu22.04
ENV DEBIAN_FRONTEND noninteractive
ENV CMDARGS --listen

# Install base dependencies
RUN apt-get update -y && \
    apt-get install -y curl libgl1 libglib2.0-0 python3-pip python-is-python3 git wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create model directories
RUN mkdir -p /content/app/models/checkpoints

# Download models
RUN cd /content/app/models/checkpoints && \
    wget -O otti.safetensors https://huggingface.co/AdiCakepLabs/otti_v1/resolve/main/otti.safetensors && \
    wget -O illustrious-xl.safetensors https://huggingface.co/OnomaAIResearch/Illustrious-xl-early-release-v0/resolve/main/Illustrious-XL-v0.1.safetensors

COPY requirements_docker.txt requirements_versions.txt /tmp/
RUN pip install --no-cache-dir -r /tmp/requirements_docker.txt -r /tmp/requirements_versions.txt && \
    rm -f /tmp/requirements_docker.txt /tmp/requirements_versions.txt

RUN pip install --no-cache-dir xformers==0.0.23 --no-dependencies

RUN curl -fsL -o /usr/local/lib/python3.10/dist-packages/gradio/frpc_linux_amd64_v0.2 https://cdn-media.huggingface.co/frpc-gradio-0.2/frpc_linux_amd64 && \
    chmod +x /usr/local/lib/python3.10/dist-packages/gradio/frpc_linux_amd64_v0.2

RUN adduser --disabled-password --gecos '' user && \
    mkdir -p /content/app /content/data

COPY entrypoint.sh /content/
RUN chown -R user:user /content && \
    chown -R user:user /content/app/models

WORKDIR /content
USER user

COPY --chown=user:user . /content/app
RUN mv /content/app/models /content/app/models.org

# Create necessary directories and move downloaded models
RUN mkdir -p /content/app/models.org/checkpoints && \
    cp /content/app/models/checkpoints/*.safetensors /content/app/models.org/checkpoints/

CMD [ "sh", "-c", "/content/entrypoint.sh ${CMDARGS}" ]