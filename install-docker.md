### 1.Update the apt package index and install packages to allow apt to use a repository over HTTPS:  

sudo apt-get update  
  
sudo apt-get install \
     ca-certificates \
     curl \
     gnupg \
     lsb-release  

### 2.Add Docker’s official GPG key:  

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg  

### 3. Use the following command to set up the stable repository. 

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

### 4. Install Docker Engine

 sudo apt-get update
 sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

### 5. Verify that Docker Engine is installed correctly by running the hello-world image.

  sudo docker run hello-world
