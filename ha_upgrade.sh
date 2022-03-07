#!/bin/sh
# Homeassistant installer script by @devbis
set -e

OPENWRT_VERSION=${OPENWRT_VERSION:-21.02}
HOMEASSISTANT_MAJOR_VERSION="2022.3"

get_ha_version()
{
  wget -q -O- https://pypi.org/simple/homeassistant/ | grep ${HOMEASSISTANT_MAJOR_VERSION} | tail -n 1 | cut -d "-" -f2 | cut -d "." -f1,2,3
}
HOMEASSISTANT_VERSION=$(get_ha_version)

if [ "${HOMEASSISTANT_VERSION}" == "" ]; then
  echo "Incorrect Home Assistant version. Exiting ...";
  exit 1;
fi

echo "Starting the Home Assistant removal"
/etc/init.d/homeassistant stop
/etc/init.d/homeassistant disable
pip3 uninstall homeassistant -y
echo "Home Assistant was successfully deleted"


echo "=========================================="
echo " Installing Home Assistant ${HOMEASSISTANT_VERSION} ..."
echo "=========================================="


echo "Install HASS"
cd /tmp
rm -rf homeassistant.tar.gz homeassistant-${HOMEASSISTANT_VERSION}
wget https://pypi.python.org/packages/source/h/homeassistant/homeassistant-${HOMEASSISTANT_VERSION}.tar.gz -O homeassistant.tar.gz
tar -zxf homeassistant.tar.gz
rm -rf homeassistant.tar.gz
cd homeassistant-${HOMEASSISTANT_VERSION}/homeassistant/
echo '' > requirements.txt

mv components components-orig
mkdir components
cd components-orig
mv \
  __init__.py \
  air_quality \
  alarm_control_panel \
  alert \
  alexa \
  analytics \
  api \
  auth \
  automation \
  binary_sensor \
  blueprint \
  brother \
  button \
  camera \
  climate \
  cloud \
  config \
  counter \
  cover \
  default_config \
  device_automation \
  device_tracker \
  dhcp \
  diagnostics \
  discovery \
  energy \
  esphome \
  fan \
  frontend \
  geo_location \
  google_assistant \
  google_translate \
  group \
  hassio \
  history \
  homeassistant \
  http \
  humidifier \
  image \
  image_processing \
  input_boolean \
  input_button \
  input_datetime \
  input_number \
  input_select \
  input_text \
  ipp \
  light \
  lock \
  logbook \
  logger \
  lovelace \
  manual \
  map \
  media_player \
  media_source \
  met \
  mobile_app \
  mpd \
  mqtt \
  my \
  network \
  notify \
  number \
  onboarding \
  panel_custom \
  panel_iframe \
  persistent_notification \
  person \
  python_script \
  recorder \
  remote \
  rest \
  safe_mode \
  scene \
  script \
  search \
  select \
  sensor \
  shopping_list \
  siren \
  ssdp \
  stream \
  sun \
  switch \
  system_health \
  system_log \
  tag \
  telegram \
  telegram_bot \
  template \
  time_date \
  timer \
  trace \
  tts \
  updater \
  upnp \
  usb \
  vacuum \
  wake_on_lan \
  water_heater \
  weather \
  webhook \
  websocket_api \
  workday \
  xiaomi_aqara \
  xiaomi_miio \
  yeelight \
  zeroconf \
  zone \
  ../components

if [ $LUMI_GATEWAY ]; then
  mv zha ../components
fi
cd ..
rm -rf components-orig
cd components

# serve static with gzipped files
sed -i 's/filepath = self._directory.joinpath(filename).resolve()/try:\n                filepath = self._directory.joinpath(Path(rel_url + ".gz")).resolve()\n                if not filepath.exists():\n                    raise FileNotFoundError()\n            except Exception as e:\n                filepath = self._directory.joinpath(filename).resolve()/' http/static.py

sed -i 's/sqlalchemy==[0-9\.]*/sqlalchemy/' recorder/manifest.json
sed -i 's/pillow==[0-9\.]*/pillow/' image/manifest.json
sed -i 's/, UnidentifiedImageError//' image/__init__.py
sed -i 's/except UnidentifiedImageError/except OSError/' image/__init__.py
sed -i 's/zeroconf==[0-9\.]*/zeroconf/' zeroconf/manifest.json
sed -i 's/netdisco==[0-9\.]*/netdisco/' discovery/manifest.json
sed -i 's/PyNaCl==[0-9\.]*/PyNaCl/' mobile_app/manifest.json
sed -i 's/defusedxml==[0-9\.]*/defusedxml/' ssdp/manifest.json
sed -i 's/netdisco==[0-9\.]*/netdisco/' ssdp/manifest.json

if [ $LUMI_GATEWAY ]; then
  # remove unwanted zha requirements
  sed -i 's/"bellows==[0-9\.]*",//' zha/manifest.json
  sed -i 's/"zigpy-cc==[0-9\.]*",//' zha/manifest.json
  sed -i 's/"zigpy-deconz==[0-9\.]*",//' zha/manifest.json
  sed -i 's/"zigpy-xbee==[0-9\.]*",//' zha/manifest.json
  sed -i 's/"zigpy-znp==[0-9\.]*"//' zha/manifest.json
  sed -i 's/"zigpy-zigate==[0-9\.]*",/"zigpy-zigate"/' zha/manifest.json
  sed -i 's/import bellows.zigbee.application//' zha/core/const.py
  sed -i 's/import zigpy_cc.zigbee.application//' zha/core/const.py
  sed -i 's/import zigpy_deconz.zigbee.application//' zha/core/const.py
  sed -i 's/import zigpy_xbee.zigbee.application//' zha/core/const.py
  sed -i 's/import zigpy_znp.zigbee.application//' zha/core/const.py
  sed -i -e '/znp = (/,/)/d' -e '/ezsp = (/,/)/d' -e '/deconz = (/,/)/d' -e '/ti_cc = (/,/)/d' -e '/xbee = (/,/)/d' zha/core/const.py
fi

sed -i 's/"cloud",//' default_config/manifest.json
sed -i 's/"dhcp",//' default_config/manifest.json
sed -i 's/"mobile_app",//' default_config/manifest.json
sed -i 's/"updater",//' default_config/manifest.json
sed -i 's/"usb",//' default_config/manifest.json
sed -i 's/==[0-9\.]*//g' frontend/manifest.json

cd ../..
sed -i 's/    "/    # "/' homeassistant/generated/config_flows.py
sed -i 's/    # "mqtt"/    "mqtt"/' homeassistant/generated/config_flows.py
sed -i 's/    # "esphome"/    "esphome"/' homeassistant/generated/config_flows.py
sed -i 's/    # "met"/    "met"/' homeassistant/generated/config_flows.py
if [ $LUMI_GATEWAY ]; then
  sed -i 's/    # "zha"/    "zha"/' homeassistant/generated/config_flows.py
fi

# disabling all zeroconf services
sed -i 's/^    "_/    "_disabled_/' homeassistant/generated/zeroconf.py
# re-enable required ones
sed -i 's/_disabled_esphomelib./_esphomelib./' homeassistant/generated/zeroconf.py
sed -i 's/_disabled_ipps./_ipps./' homeassistant/generated/zeroconf.py
sed -i 's/_disabled_ipp./_ipp./' homeassistant/generated/zeroconf.py
sed -i 's/_disabled_printer./_printer./' homeassistant/generated/zeroconf.py
sed -i 's/_disabled_miio./_miio./' homeassistant/generated/zeroconf.py

sed -i 's/from jinja2 import contextfunction, pass_context/from jinja2 import contextfunction, contextfilter as pass_context/' homeassistant/helpers/template.py

sed -i 's/"installation_type": "Unknown"/"installation_type": "Home Assistant on OpenWrt"/' homeassistant/helpers/system_info.py
sed -i 's/defusedxml==[0-9\.]*//' homeassistant/package_constraints.txt

find . -type f -exec touch {} +
sed -i "s/[>=]=.*//g" setup.cfg

rm -rf /usr/lib/python${PYTHON_VERSION}/site-packages/homeassistant-*.egg

cat << "EOF" > setup.py
from setuptools import setup

setup() 
EOF

python3 setup.py install
cd ../
rm -rf homeassistant-${HOMEASSISTANT_VERSION}/

/etc/init.d/homeassistant enable
echo "Done."
