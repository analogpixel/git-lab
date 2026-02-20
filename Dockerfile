FROM ubuntu:24.04

LABEL maintainer="git-lab"
LABEL description="Interactive Git scenario laboratory"

ENV DEBIAN_FRONTEND=noninteractive
ENV TERM=xterm-256color

# Install git and useful utilities
RUN apt-get update && apt-get install -y \
    git \
    vim \
    nano \
    less \
    tree \
    bash-completion \
    man-db \
    && rm -rf /var/lib/apt/lists/*

# Create the student user
RUN useradd -m -s /bin/bash student

# Configure git globally for the student user
RUN su - student -c "git config --global user.name 'Lab Student'" && \
    su - student -c "git config --global user.email 'student@git-lab.local'" && \
    su - student -c "git config --global init.defaultBranch main" && \
    su - student -c "git config --global core.editor vim" && \
    su - student -c "git config --global color.ui auto"

# Create directory structure
#   /srv/git/          -> "remote" bare repositories live here
#   /home/student/workspace/ -> "local" working directory
#   /opt/git-lab/      -> lab scripts and scenarios
RUN mkdir -p /srv/git && chown student:student /srv/git && \
    mkdir -p /home/student/workspace && chown student:student /home/student/workspace && \
    mkdir -p /opt/git-lab/scenarios

# Copy lab scripts and scenarios into the image
COPY git-lab.sh /opt/git-lab/git-lab.sh
COPY scenarios/ /opt/git-lab/scenarios/
COPY agents.md /opt/git-lab/agents.md

# Make all scripts executable
RUN chmod +x /opt/git-lab/git-lab.sh && \
    chmod +x /opt/git-lab/scenarios/*.sh

# Add git-lab to PATH via alias
RUN echo 'alias git-lab="/opt/git-lab/git-lab.sh"' >> /home/student/.bashrc && \
    echo '' >> /home/student/.bashrc && \
    echo 'echo "============================================"' >> /home/student/.bashrc && \
    echo 'echo "  Welcome to the Git Laboratory!"' >> /home/student/.bashrc && \
    echo 'echo "  Type: git-lab  to start a scenario"' >> /home/student/.bashrc && \
    echo 'echo "============================================"' >> /home/student/.bashrc && \
    echo 'echo ""' >> /home/student/.bashrc

WORKDIR /home/student/workspace
USER student

CMD ["/bin/bash"]

