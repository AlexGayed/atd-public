#!/bin/bash

# Find out what topology is running
TOPO=$(cat /etc/ACCESS_INFO.yaml | shyaml get-value topology)
ARISTA_PWD=$(cat /etc/ACCESS_INFO.yaml | shyaml get-value login_info.jump_host.pw)

# Adding in temporary pip install/upgrade for rCVP API
pip install rcvpapi
pip install --upgrade rcvpapi

# Install Python3-pip
apt install python3-pip -y

# Install python3 libraries
pip3 install ruamel.yaml
pip3 install rcvpapi tornado beautifulsoup4
pip3 install tornado
pip3 install beautifulsoup4

# Screen scrape credentials and make credentials file
python3 /tmp/atd/topologies/all/lab_gui/screen_scrape.py


# Clean up previous stuff to make sure it's current
rm -rf /var/www/html/atd/labguides/

# Make sure login.py and ConfigureTopology.py is current
cp /tmp/atd/topologies/all/login.py /usr/local/bin/login.py
cp /tmp/atd/topologies/all/ConfigureTopology.py /usr/local/bin/ConfigureTopology.py
chmod +x /usr/local/bin/ConfigureTopology.py

# Add files to arista home
rsync -av /tmp/atd/topologies/$TOPO/files/ /home/arista
rsync -av /tmp/atd/topologies/all/lab_gui /home/arista

# Update file permissions in /home/arista
chown -R arista:arista /home/arista

# Update the Arista user password for connecting to the labvm
sed -i "s/{REPLACE_PWD}/$ARISTA_PWD/g" /tmp/atd/topologies/$TOPO/labguides/source/connecting.rst
sed -i "s/{REPLACE_PWD}/$ARISTA_PWD/g" /tmp/atd/topologies/$TOPO/labguides/source/programmability_connecting.rst

# Copy files for nginx and restart nginx
cp /tmp/atd/labvm/services/nginx/default /etc/nginx/sites-enabled/default
systemctl restart nginx

# Build the lab guides html files
cd /tmp/atd/topologies/$TOPO/labguides
make html
sphinx-build -b latex source build

# Build the lab guides PDF
make latexpdf
mkdir /var/www/html/atd/labguides/

# Put the new HTML and PDF in the proper directories
mv /tmp/atd/topologies/$TOPO/labguides/build/latex/ATD.pdf /var/www/html/atd/labguides/
mv /tmp/atd/topologies/$TOPO/labguides/build/html/* /var/www/html/atd/labguides/ && chown -R www-data:www-data /var/www/html/atd/labguides
