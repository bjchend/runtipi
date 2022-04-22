ROOT_FOLDER="$(readlink -f $(dirname "${BASH_SOURCE[0]}")/..)"

# Constants
NGINX_PORT="80"
# Apps
APP_PI_HOLE_PORT="8081"
APP_WG_EASY_PORT="8082"
APP_NEXTCLOUD_PORT="8082"
APP_ANONADDY_PORT="8083"
APP_SIMPLETORRENT_PORT="8084"
APP_FRESHRSS_PORT="8085"

echo
echo "======================================"
if [[ -f "${ROOT_FOLDER}/state/configured" ]]; then
  echo "=========== RECONFIGURING ============"
else
  echo "============ CONFIGURING ============="
fi
echo "=============== TIPI ================="
echo "======================================"
echo

# Store paths to intermediary config files
ENV_FILE="./templates/.env"

# Remove intermediary config files
[[ -f "$ENV_FILE" ]] && rm -f "$ENV_FILE"

# Copy template configs to intermediary configs
[[ -f "./templates/.env-sample" ]] && cp "./templates/.env-sample" "$ENV_FILE"

# Install ansible if not installed
if ! command -v ansible-playbook > /dev/null; then
  echo "Installing Ansible..."
  sudo apt-get install -y software-properties-common
  sudo apt-add-repository -y ppa:ansible/ansible
  sudo apt-get update
  sudo apt-get install -y ansible
fi

ansible-playbook ansible/setup.yml -i ansible/hosts -K

echo "Generating config files..."
for template in "${ENV_FILE}"; do
  sed -i "s/<nginx-port>/${NGINX_PORT}/g" "${template}"
  # Apps
  sed -i "s/<app-pi-hole-port>/${APP_PI_HOLE_PORT}/g" "${template}"
  sed -i "s/<app-wgeasy-port>/${APP_WG_EASY_PORT}/g" "${template}"
  sed -i "s/<app-nextcloud-port>/${APP_NEXTCLOUD_PORT}/g" "${template}"
  sed -i "s/<app-anonaddy-port>/${APP_ANONADDY_PORT}/g" "${template}"
  sed -i "s/<app-simpletorrent-port>/${APP_SIMPLETORRENT_PORT}/g" "${template}"
  sed -i "s/<app-freshrss-port>/${APP_FRESHRSS_PORT}/g" "${template}"
done

mv -f "$ENV_FILE" "$ROOT_FOLDER/.env"

echo "Configuring permissions..."
echo
find "$ROOT_FOLDER" -path "$ROOT_FOLDER/app-data" -prune -o -exec chown 1000:1000 {} + || true

# Create configured status
touch "${ROOT_FOLDER}/state/configured"