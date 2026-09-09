*! ensure_asset v1.4 - Garantiza disponibilidad de datos vinculados al repo via GitHub Releases
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
import datetime
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


def _sha_mismatch_msg(asset_name, entry, expected_sha, actual_sha, local_path,
                      manifest, pinned_mode):
    """Mensaje-runbook del candado. Caso (a): corrupcion -> borrar y re-correr.
    Caso (b): actualizacion intencional -> la secuencia COMPLETA para declararla
    y republicarla (solo equipo CIEP con el repo; en modo endpoint no aplica).
    Los valores (SHA, tamano, tag) salen del archivo real y del manifest, para
    que el mensaje nunca quede desactualizado ni haya que teclearlos."""
    try:
        actual_size = os.path.getsize(local_path)
    except OSError:
        actual_size = '?'
    rel_path = entry.get('local_path', asset_name)
    tag = str(manifest.get('release_tag', '<release_tag>'))
    today = datetime.date.today().isoformat()
    msg = (
        "SHA-256 no coincide para " + asset_name + ".\n"
        "  Esperado: " + expected_sha + "\n"
        "  Real:     " + actual_sha + "\n"
        "  Archivo:  " + local_path + "\n"
        "Dos casos posibles:\n"
        "  (a) Si NO modificaste este archivo: esta corrupto o desactualizado.\n"
        "      Borralo y vuelve a correr (se re-descarga del Release " + tag + ").\n"
    )
    if pinned_mode:
        return msg + (
            "  (b) Si lo actualizaste a proposito: esta instalacion no tiene el repo;\n"
            "      la actualizacion se declara desde el clon de desarrollo del CIEP.\n"
            "      NO borres el archivo: perderias los datos nuevos."
        )
    return msg + (
        "  (b) Si lo actualizaste A PROPOSITO (p.ej. nuevo Paquete Economico):\n"
        "      NO borres el archivo: perderias los datos nuevos. El manifest debe\n"
        "      declararlo. Secuencia completa (solo equipo CIEP con el repo):\n"
        "      1. Valida el CONTENIDO del archivo nuevo (quien edita, valida).\n"
        "         Si no eres Ricardo, avisale ANTES de continuar.\n"
        "      2. cd al clon de DESARROLLO (NO la Carpeta de investigadores de\n"
        "         Dropbox-CIEP/SimuladorCIEP: ahi git lo opera solo Ricardo).\n"
        "         Confirma con: git rev-parse --show-toplevel\n"
        "      3. Valores ya calculados de este archivo (verificalos si quieres):\n"
        "           shasum -a 256 \"" + rel_path + "\"   -> " + actual_sha + "\n"
        "           stat -f%z \"" + rel_path + "\"        -> " + str(actual_size) + "\n"
        "      4. Edita 05_scripts/manifest.json, entrada \"" + asset_name + "\":\n"
        "           \"sha256\": \"" + actual_sha + "\",\n"
        "           \"size_bytes\": " + str(actual_size) + ",\n"
        "         y arriba \"data_updated\": \"" + today + "\" (si cambiaron los datos).\n"
        "      5. Re-corre el modulo: este candado debe pasar en silencio.\n"
        "      6. git add 05_scripts/manifest.json && git commit -m \"fix(assets): "
        + asset_name + " ...\" && git push\n"
        "      7. gh release delete-asset " + tag + " \"" + asset_name + "\" -y || true\n"
        "         bash 05_scripts/publicar.sh " + tag + "\n"
        "         (re-sube el asset al Release " + tag + " y verifica los "
        + str(len(manifest.get('assets', []))) + " assets)\n"
        "      8. Avisa a Ricardo: pull en la Carpeta de investigadores (solo el).\n"
        "      Detalle y por que: 02_governance/runbook-actualizar-assets.md"
    )


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
            _fail(_sha_mismatch_msg(asset_name, entry, expected_sha, actual_sha,
                                    local_path, manifest, pinned_mode))
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
