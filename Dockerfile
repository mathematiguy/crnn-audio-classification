FROM pytorch/pytorch:1.0-cuda10.0-cudnn7-devel

RUN apt-get update
RUN apt-get install -y ffmpeg sox graphviz mpg123 git python3-pip
RUN curl https://bootstrap.pypa.io/get-pip.py | python3

ENV GRAPHVIZ_DOT /usr/bin/dot

COPY requirements.txt /root/requirements.txt
RUN pip3 install -r /root/requirements.txt

COPY torchaudio-contrib /work/torchaudio-contrib
RUN pip3 install -e /work/torchaudio-contrib
