#cloud-config
debconf_selections:
 maas: |
  {{ "{{" }}for line in str(curtin_preseed).splitlines(){{ "}}" }}
  {{ "{{" }}line{{ "}}" }}
  {{ "{{" }}endfor{{ "}}" }}
early_commands:
{{ "{{" }}if third_party_drivers and driver{{ "}}" }}
  {{ "{{" }}py: key_string = ''.join(['\\x%x' % x for x in driver['key_binary']]){{ "}}" }}
  {{ "{{" }}if driver['key_binary'] and driver['repository'] and driver['package']{{ "}}" }}
  driver_00_get_key: /bin/echo -en '{{ "{{" }}key_string{{ "}}" }}' > /tmp/maas-{{ "{{" }}driver['package']{{ "}}" }}.gpg
  driver_01_add_key: ["apt-key", "add", "/tmp/maas-{{ "{{" }}driver['package']{{ "}}" }}.gpg"]
  {{ "{{" }}endif{{ "}}" }}
  {{ "{{" }}if driver['repository']{{ "}}" }}
  driver_02_add: ["add-apt-repository", "-y", "deb {{ "{{" }}driver['repository']{{ "}}" }} {{ "{{" }}node.get_distro_series(){{ "}}" }} main"]
  {{ "{{" }}endif{{ "}}" }}
  {{ "{{" }}if driver['package']{{ "}}" }}
  driver_03_update_install: ["sh", "-c", "apt-get update --quiet && apt-get --assume-yes install {{ "{{" }}driver['package']{{ "}}" }}"]
  {{ "{{" }}endif{{ "}}" }}
  {{ "{{" }}if driver['module']{{ "}}" }}
  driver_04_load: ["sh", "-c", "depmod && modprobe {{ "{{" }}driver['module']{{ "}}" }} || echo 'Warning: Failed to load module: {{ "{{" }}driver['module']{{ "}}" }}'"]
  {{ "{{" }}endif{{ "}}" }}
{{ "{{" }}else{{ "}}" }}
  driver_00: ["sh", "-c", "echo third party drivers not installed or necessary."]
{{ "{{" }}endif{{ "}}" }}
late_commands:
  {{ "{{" }}py: bootdata_url = ''.join([{{ .Values.bootdata_url | quote }},node.hostname,"/promconfig"]){{ "}}" }}
  {{ "{{" }}py: promsvc_url = ''.join([{{ .Values.bootdata_url | quote }},node.hostname,"/promservice"]){{ "}}" }}
  {{ "{{" }}py: vfsvc_url = ''.join([{{ .Values.bootdata_url | quote }},node.hostname,"/vfservice"]){{ "}}" }}
  {{ "{{" }}py: prominit_url = ''.join([{{ .Values.bootdata_url | quote }},node.hostname,"/prominit"]){{ "}}" }}
  drydock_01: ["curtin", "in-target","--", "wget", "--no-proxy", "{{ "{{" }}bootdata_url{{ "}}" }}", "-O", "/etc/prom_init.yaml"]
  drydock_02: ["curtin", "in-target","--", "wget", "--no-proxy", "{{ "{{" }}prominit_url{{ "}}" }}", "-O", "/var/tmp/prom_init.sh"]
  drydock_03: ["curtin", "in-target","--", "chmod", "555", "/var/tmp/prom_init.sh"]
  drydock_04: ["curtin", "in-target","--", "wget", "--no-proxy", "{{ "{{" }}promsvc_url{{ "}}" }}", "-O", "/lib/systemd/system/prom_init.service"]
  drydock_05: ["curtin", "in-target","--", "systemctl", "enable", "prom_init.service"]
  drydock_06: ["curtin", "in-target","--", "wget", "--no-proxy", "{{ "{{" }}vfsvc_url{{ "}}" }}", "-O", "/lib/systemd/system/drydock_vf.service"]
  drydock_07: ["curtin", "in-target","--", "systemctl", "enable", "drydock_vf.service"]
  maas: [wget, '--no-proxy', {{ "{{" }}node_disable_pxe_url|escape.json{{ "}}" }}, '--post-data', {{ "{{" }}node_disable_pxe_data|escape.json{{ "}}" }}, '-O', '/dev/null']
{{ "{{" }}if third_party_drivers and driver{{ "}}" }}
  {{ "{{" }}if driver['key_binary'] and driver['repository'] and driver['package']{{ "}}" }}
  driver_00_key_get: curtin in-target -- sh -c "/bin/echo -en '{{ "{{" }}key_string{{ "}}" }}' > /tmp/maas-{{ "{{" }}driver['package']{{ "}}" }}.gpg"
  driver_02_key_add: ["curtin", "in-target", "--", "apt-key", "add", "/tmp/maas-{{ "{{" }}driver['package']{{ "}}" }}.gpg"]
  {{ "{{" }}endif{{ "}}" }}
  {{ "{{" }}if driver['repository']{{ "}}" }}
  driver_03_add: ["curtin", "in-target", "--", "add-apt-repository", "-y", "deb {{ "{{" }}driver['repository']{{ "}}" }} {{ "{{" }}node.get_distro_series(){{ "}}" }} main"]
  {{ "{{" }}endif{{ "}}" }}
  driver_04_update_install: ["curtin", "in-target", "--", "apt-get", "update", "--quiet"]
  {{ "{{" }}if driver['package']{{ "}}" }}
  driver_05_install: ["curtin", "in-target", "--", "apt-get", "-y", "install", "{{ "{{" }}driver['package']{{ "}}" }}"]
  {{ "{{" }}endif{{ "}}" }}
  driver_06_depmod: ["curtin", "in-target", "--", "depmod"]
  driver_07_update_initramfs: ["curtin", "in-target", "--", "update-initramfs", "-u"]
{{ "{{" }}endif{{ "}}" }}