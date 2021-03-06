###################
##               ##
##    BPF SLS    ##
##               ##
###################

################################################################################
# This configuration makes the following assumptions -
#
#   - All interfaces on your machine have a /etc/nsm/$HOSTNAME-$INTERFACE
#   configuration folder.
#
#   - If NOT - you have specified a custom grain called 'sensor_interfaces'
#   which is a list of the sensor interfaces that have been configured, example
#   below.
#
#   sensor_interfaces:
#     - <monitoring interface_1>
#     - <monitoring interface_2>
#
# This salt code will use this list of interfaces to create the appropiate
# bpf.conf files.
#
# sensor/bpf/bpf.conf - default bpf.conf file, just like /etc/nsm/rules/bpf.conf
# anything placed in this file will be the default configuration on all minions.
#
# To modify the bpf.conf file for a specific service accross all minions, change
# the name to sensor/bpf/bpf-[ids, bro, pcap, prads].conf.
#
# The settings for a specific node can be done by creating a folder specific to
# the node and and placing a bpf.conf file there with the desired setting. Use
# the nodename (the hostname) to target.
################################################################################

{% set nodename = grains['nodename'] %}

{% if grains['sensor_interfaces'] is defined %}
{% set sensor_interfaces = grains['sensor_interfaces'] %}
{% else %}
{% set sensor_interfaces = grains['ip_interfaces'].iterkeys()|list %}
{% endif %}

{% for interface in sensor_interfaces %}

{% if interface not in ['lo'] %}

{% set sensorname = '{0}-{1}'.format(nodename, interface) %}

bpfsync-{{ sensorname }}:
  file.managed:
    - name: /etc/nsm/{{ sensorname }}/bpf.conf
    - source:
      - salt://sensor/bpf/{{ nodename }}/{{ interface }}bpf.conf
      - salt://sensor/bpf/{{ nodename }}/bpf.conf
      - salt://sensor/bpf/bpf.conf

{% for serv in ['bro', 'ids', 'pcap', 'prads'] %}
bpfsync-{{ sensorname }}-{{ serv }}:
  file.managed:
    - name: /etc/nsm/{{ sensorname }}/bpf-{{ serv }}.conf
    - source:
      - salt://sensor/bpf/{{ nodename }}/{{ interface }}/bpf-{{ serv }}.conf
      - salt://sensor/bpf/{{ nodename }}/bpf-{{ serv }}.conf
      - salt://sensor/bpf/{{ nodename }}/bpf.conf
      - salt://sensor/bpf/bpf-{{ serv }}.conf
      - salt://sensor/bpf/bpf.conf

{% endfor %}
{% endif %}
{% endfor %}
