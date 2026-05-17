# Copy to ~/.config/my-linux-config/shell/local.sh and edit for this machine.
# Keep this file free of real secrets before committing.

# Load service keys from a private file if you use one.
# if [[ -r "${HOME}/private_service_keys.json" ]]; then
#   export EXAMPLE_SERVICE_KEY="$(python3 -c 'import json, pathlib; print(json.loads(pathlib.Path.home().joinpath("private_service_keys.json").read_text()).get("EXAMPLE_SERVICE_KEY", ""))')"
# fi

# Add private signing or access keys for this machine.
# if command -v ssh-add >/dev/null 2>&1; then
#   ssh-add "${HOME}/path/to/private_key" >/dev/null 2>&1 || true
# fi

# Add private project paths for this machine.
# case ":${PATH}:" in
#   *":${HOME}/example-project/bin:"*) ;;
#   *) export PATH="${HOME}/example-project/bin:${PATH}" ;;
# esac

# Activate a local Python environment only when you want every shell to enter it.
# if command -v mamba >/dev/null 2>&1; then
#   mamba activate daily_use
# fi
