# Use a specific Debian version and a slim variant
FROM debian:latest

# Set environment variables to prevent prompts
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
	apt-get install -y \
	sudo \
	curl \
	wget \
	gnupg \
	zip \
	unzip \
	build-essential \
	libc6 \
    gdb \
	apt-transport-https \
	ssh \
	nano \
	tmux \
	vim \
	neovim \
	git \
	vim \
	&& apt-get clean && \
	rm -rf /var/lib/apt/lists/*
	

# Create a non-root user with sudo privileges
RUN useradd -ms /bin/bash devuser && \
    echo 'devuser ALL=(ALL) NOPASSWD: ALL' | tee -a /etc/sudoers

# Switch to the non-root user
USER devuser

# Set the working directory
WORKDIR /home/devuser

# Default command to run when the container starts
CMD ["bash"]