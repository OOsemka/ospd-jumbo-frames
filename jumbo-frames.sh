#!/bin/bash
echo "******************* Steps to enable jumbo frames on tenant network"

echo "******************* Parameters"
SSH="ssh -o StrictHostKeyChecking=no"
SCP="scp -o StrictHostKeyChecking=no"
SSHUSER="heat-admin"
source ~/stackrc
COMPUTES=$(nova list | grep overcloud-compute | awk '{print $12}' | cut -f2 -d=)
CONTROLLERS=$(nova list | grep overcloud-controller | awk '{print $12}' | cut -f2 -d=)
CONTROLLER=$(nova list | grep overcloud-controller | awk '{print $12}' | head -1 | cut -f2 -d=)


echo "******************* Step 1 - display current mtu configuration"
for NODE in $CONTROLLERS $COMPUTES; do $SSH $SSHUSER@$NODE "sudo hostname; echo ****nova.conf:; sudo grep mtu /etc/nova/nova.conf; echo ****ovs_neutron_plugin.ini:; sudo grep mtu /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini; echo ****l3_agent.ini:; sudo grep mtu /etc/neutron/l3_agent.ini; echo ****dnsmasq-neutron.conf:; sudo grep dhcp-option-force /etc/neutron/dnsmasq-neutron.conf ; echo **********************************"; done

echo "******************* Step 2 - adjust required parameters for Controllers and Compute nodes"
for NODE in $CONTROLLERS $COMPUTES; do $SSH $SSHUSER@$NODE "sudo hostname; echo ****nova.conf:; sudo openstack-config --set /etc/nova/nova.conf DEFAULT network_device_mtu 8950; echo ****ovs_neutron_plugin.ini:; sudo openstack-config --set /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini ovs veth_mtu 8950;"; done


echo "******************* Step 3 - adjust required parameters for just Controllers"
for NODE in $CONTROLLERS; do $SSH $SSHUSER@$NODE "echo ****l3_agent.ini:; sudo openstack-config --set /etc/neutron/l3_agent.ini DEFAULT network_device_mtu 8950; echo ****dnsmasq-neutron.conf:; sudo chmod 777 /etc/neutron/dnsmasq-neutron.conf; sudo echo dhcp-option-force=26,8950 > /etc/neutron/dnsmasq-neutron.conf; sudo chmod 644 /etc/neutron/dnsmasq-neutron.conf; echo **********************************"; done

echo "******************* Step 4 - display adjusted mtu configuration"
for NODE in $CONTROLLERS $COMPUTES; do $SSH $SSHUSER@$NODE "sudo hostname; echo ****nova.conf:; sudo grep mtu /etc/nova/nova.conf; echo ****ovs_neutron_plugin.ini:; sudo grep mtu /etc/neutron/plugins/openvswitch/ovs_neutron_plugin.ini; echo ****l3_agent.ini:; sudo grep mtu /etc/neutron/l3_agent.ini; echo ****dnsmasq-neutron.conf:; sudo grep dhcp-option-force /etc/neutron/dnsmasq-neutron.conf ; echo **********************************"; done



echo "******************* Step 5 - restart all services - there will be interruption in services"
for NODE in $CONTROLLER; do $SSH $SSHUSER@$NODE "sudo pcs resource cleanup"; done
for NODE in $COMPUTES; do $SSH $SSHUSER@$NODE "sudo systemctl restart openstack-nova-compute; sudo systemctl restart openstack-ceilometer-compute; sudo systemclt restart openvswitch"; done 
echo "sleep for 60 seconds"
sleep 60

echo "Any existing tenant networks and routers will remain set with the
original MTU, you must delete and recreate existing tenant networks and routers to take
advantage of the new MTU settings. The settings will only apply to VMs started after the
services have been restarted."
echo "all done"

