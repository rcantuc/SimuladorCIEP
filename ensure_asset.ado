*! ensure_asset v1.2 - Garantiza disponibilidad de datos vinculados al repo via GitHub Releases
*! Sintaxis: ensure_asset "<nombre>"
*! <nombre> debe coincidir con un campo "name" en 05_scripts/manifest.json
*!
*! Verifica que el asset exista localmente con el SHA-256 declarado en el manifest.
*! Si falta, lo descarga del GitHub Release indicado por release_url_prefix.
*! Doble entorno: con repo usa el manifest local; sin repo (instalacion via
*! net install) descarga el manifest de GitHub usando el pin de version que
*! publicar-endpoint.sh quema en la copia publicada.
*! Aborta con _rc=198 si no hay manifest alcanzable, asset no esta declarado,
*! o SHA no coincide.

program define ensure_asset
    version 16
    syntax anything(name=asset_name)

    * Quitar comillas externas si las hay
    local asset_name = subinstr(`"`asset_name'"', `"""', "", .)

    * PIN de version: VACIO en el repo. publicar-endpoint.sh lo rellena en la
    * copia PUBLICADA al endpoint, para que un usuario sin repo reconstruya
    * contra los assets de SU version instalada. NO editar esta linea a mano.
    local PINNED_VERSION ""

    python: ensure_asset_main("`asset_name'", "`PINNED_VERSION'")
end


python:
import json
import hashlib
import os
import urllib.parse
import requests
from sfi import Macro, SFIToolkit


def _fail(msg):
    SFIToolkit.errprintln("ensure_asset: " + msg)
    SFIToolkit.error(198)


def _download(url, dest_path):
    """Descarga url a dest_path (streaming). Lanza excepcion si falla.
    Usa requests (trae sus propios certificados SSL via certifi): urllib
    truena con CERTIFICATE_VERIFY_FAILED en Pythons sin certificados
    configurados, y requests ya es dependencia dura de la suite (AccesoBIE)."""
    with requests.get(url, stream=True, timeout=120) as r:
        r.raise_for_status()
        with open(dest_path, 'wb') as f:
            for chunk in r.iter_content(chunk_size=65536):
                f.write(chunk)


def _sha256_of(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()


def _fetch_pinned_manifest(sysdir_site, pin):
    """Descarga (y cachea por version) el manifest del repo publico por tag.
    Devuelve la ruta local del manifest, o None si fallo (ya reporto)."""
    cache_path = os.path.join(sysdir_site, 'raw', 'temp', 'manifest-' + pin + '.json')
    if os.path.isfile(cache_path):
        return cache_path
    url = ('https://raw.githubusercontent.com/rcantuc/SimuladorCIEP/'
           + urllib.parse.quote(pin) + '/05_scripts/manifest.json')
    SFIToolkit.displayln('ensure_asset: sin repo local; descargando manifest de la version ' + pin + '...')
    os.makedirs(os.path.dirname(cache_path), exist_ok=True)
    try:
        _download(url, cache_path)
    except Exception as e:
        if os.path.isfile(cache_path):
            os.remove(cache_path)
        _fail(
            'no se pudo descargar el manifest de la version ' + pin + '.\n'
            '  URL: ' + url + '\n  Razon: ' + str(e) + '\n'
            'Verifica conexion o que el tag ' + pin + ' exista en el repo publico.'
        )
        return None
    return cache_path


def ensure_asset_main(asset_name, pinned_version=""):
    asset_name = asset_name.strip().strip('"')
    pinned_version = pinned_version.strip()
    sysdir_site = Macro.getGlobal('c(sysdir_site)')
    manifest_path = os.path.join(sysdir_site, '05_scripts', 'manifest.json')
    pinned_mode = False

    if not os.path.isfile(manifest_path):
        if not pinned_version:
            _fail(
                "no se encontro manifest.json en " + manifest_path + ".\n"
                "Asegurate de estar en un clone del repo del Simulador."
            )
            return
        # Modo endpoint: sin repo, el catalogo se baja de GitHub por tag
        manifest_path = _fetch_pinned_manifest(sysdir_site, pinned_version)
        if manifest_path is None:
            return
        pinned_mode = True

    try:
        with open(manifest_path, 'r', encoding='utf-8') as f:
            manifest = json.load(f)
    except json.JSONDecodeError as e:
        if pinned_mode:
            os.remove(manifest_path)
        _fail("manifest.json no es JSON valido: " + str(e))
        return

    if pinned_mode and manifest.get('version') != pinned_version:
        os.remove(manifest_path)
        _fail(
            "el manifest descargado declara version '" + str(manifest.get('version')) + "' "
            "pero el pin de esta instalacion es '" + pinned_version + "'.\n"
            "  URL: https://raw.githubusercontent.com/rcantuc/SimuladorCIEP/"
            + pinned_version + "/05_scripts/manifest.json\n"
            "El tag pudo haberse movido. Reporta esto a ciep.mx."
        )
        return

    entry = next(
        (a for a in manifest.get('assets', []) if a.get('name') == asset_name),
        None,
    )
    if entry is None:
        _fail(
            "asset '" + asset_name + "' no declarado en manifest. "
            "Verifica el nombre o actualiza el manifest."
        )
        return

    local_path = os.path.join(sysdir_site, entry['local_path'])
    expected_sha = entry['sha256']

    if os.path.isfile(local_path):
        actual_sha = _sha256_of(local_path)
        if actual_sha != expected_sha:
            _fail(
                "SHA-256 no coincide para " + asset_name + ".\n"
                "  Esperado: " + expected_sha + "\n"
                "  Real:     " + actual_sha + "\n"
                "Archivo corrupto o desactualizado. Borralo y vuelve a correr."
            )
            return
    else:
        download_url = manifest['release_url_prefix'] + urllib.parse.quote(asset_name)
        SFIToolkit.displayln("ensure_asset: descargando " + asset_name + " desde GitHub Release...")
        os.makedirs(os.path.dirname(local_path), exist_ok=True)
        try:
            _download(download_url, local_path)
        except Exception as e:
            if os.path.isfile(local_path):
                os.remove(local_path)
            _fail(
                "descarga fallo para " + asset_name + ".\n"
                "  URL: " + download_url + "\n  Razon: " + str(e) + "\n"
                "Verifica conexion o que el release " + str(manifest.get('release_tag', '?')) + " este publicado."
            )
            return

        actual_sha = _sha256_of(local_path)
        if actual_sha != expected_sha:
            _fail(
                "SHA-256 no coincide para " + asset_name + " tras descarga.\n"
                "  Esperado: " + expected_sha + "\n"
                "  Real:     " + actual_sha + "\n"
                "Descarga corrupta. Vuelve a correr."
            )
            return

        SFIToolkit.displayln("ensure_asset: " + asset_name + " descargado y verificado.")
end
