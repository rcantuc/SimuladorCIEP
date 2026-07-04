*! ensure_asset v1.1 - Garantiza disponibilidad de datos vinculados al repo via GitHub Releases
*! Sintaxis: ensure_asset "<nombre>"
*! <nombre> debe coincidir con un campo "name" en 05_scripts/manifest.json
*!
*! Verifica que el asset exista localmente con el SHA-256 declarado en el manifest.
*! Si falta, lo descarga del GitHub Release indicado por release_url_prefix.
*! Aborta con _rc=198 si manifest no existe, asset no esta declarado, o SHA no coincide.

program define ensure_asset
    version 16
    syntax anything(name=asset_name)

    * Quitar comillas externas si las hay
    local asset_name = subinstr(`"`asset_name'"', `"""', "", .)

    python: ensure_asset_main("`asset_name'")
end


python:
import json
import hashlib
import os
import urllib.request
import urllib.parse
from sfi import Macro, SFIToolkit


def _fail(msg):
    SFIToolkit.errprintln("ensure_asset: " + msg)
    SFIToolkit.error(198)


def _sha256_of(path):
    h = hashlib.sha256()
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(65536), b''):
            h.update(chunk)
    return h.hexdigest()


def ensure_asset_main(asset_name):
    asset_name = asset_name.strip().strip('"')
    sysdir_site = Macro.getGlobal('c(sysdir_site)')
    manifest_path = os.path.join(sysdir_site, '05_scripts', 'manifest.json')

    if not os.path.isfile(manifest_path):
        _fail(
            "no se encontro manifest.json en " + manifest_path + ".\n"
            "Asegurate de estar en un clone del repo del Simulador."
        )
        return

    try:
        with open(manifest_path, 'r', encoding='utf-8') as f:
            manifest = json.load(f)
    except json.JSONDecodeError as e:
        _fail("manifest.json no es JSON valido: " + str(e))
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
            urllib.request.urlretrieve(download_url, local_path)
        except Exception as e:
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
