# The process of switching to jumbo frames for tenant network has been improved in newer version of OpenStack. I have tested OSP10, but I believe this will apply to OSP9 as well
# As a prereq make sure your controller overcloud nodes have access to repositories since openstack-utils is required
# enable ansible on your undercloud and make sure you create an inventory file - process is automated in here:
# https://github.com/OOsemka/ansible-overcloud-inventory
# Execute following from undercloud:

ansible controller -b -m raw -a "yum -y install openstack-utils"
ansible controller -b -m raw -a "openstack-config --set /etc/neutron/neutron.conf DEFAULT global_physnet_mtu 8996"
ansible controller -b -m raw -a "systemctl restart neutron-dhcp-agent.service"
ansible controller -b -m raw -a "systemctl restart neutron-l3-agent.service"
ansible controller -b -m raw -a "systemctl restart neutron-metadata-agent.service"
ansible controller -b -m raw -a "systemctl restart neutron-openvswitch-agent.service"
ansible controller -b -m raw -a "systemctl restart neutron-server.service"
