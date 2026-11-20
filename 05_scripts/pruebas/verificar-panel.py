#!/usr/bin/env python3
"""verificar-panel.py — lee y ajusta las rutas de simulador.stpr (el panel del Project Manager de Stata, de Ricardo).

El .stpr es una serialización Java (com.stata.projmanager.Tree → Node → ProjItem{isRelPath, type, name, path}).
Este script la recorre con un lector del protocolo de serialización (no por búsqueda de bytes). Cada ProjItem tiene
type 0 (archivo, con path), 1 (grupo del panel, sin path) o 2 (la raíz del proyecto); solo los de type 0 son rutas.

  listar     imprime una línea por archivo del panel (type 0): relativa|absoluta, path, name
  verificar  exige que cada path exista en el repo (relativo a la carpeta del .stpr; un path absoluto es falla:
             no viaja entre clones). Excepción: un archivo que .gitignore excluye a propósito (set_token.do, el token
             personal) no puede existir en un checkout limpio; si falta y `git check-ignore` lo confirma, es AVISO.
             Exit 0 si no hay rotas, 1 si alguna. Es el Gate 12 de `publicar.sh` (--check y --ci).
  normalizar reescribe a su ruta relativa real cada ruta que sale del repo (empieza con ../ o es absoluta) y cuyo
             final sí existe en el repo: se queda con el sufijo más largo que existe. Causa conocida: la carpeta de
             Dropbox «Ricardo Cantú» está en disco con la «ú» descompuesta (u + acento, NFD); si Stata abre el proyecto
             por una ruta con la «ú» compuesta (NFC), no reconoce el archivo como del proyecto y guarda
             ../../../Ricardo Cantú/CIEP_Simuladores/SimuladorCIEP/<ruta>. Se corre cuando Ricardo publica cambios del
             panel, antes de fusionar (versionado-y-git.md §2.5). Una ruta que sale del repo y no resuelve se reporta.
  mover      reescribe SOLO el campo path de los ProjItem cuyo path es exactamente <viejo> (o empieza con <viejo>/,
             para mover carpetas). El name (lo que el panel muestra), el orden y qué archivos aparecen no se tocan:
             son decisiones de Ricardo (versionado-y-git.md §2.5). Pares viejo=nuevo, uno por argumento.

Uso:
  python3 05_scripts/pruebas/verificar-panel.py listar     [--stpr simulador.stpr]
  python3 05_scripts/pruebas/verificar-panel.py verificar  [--stpr simulador.stpr] [--root <repo>]
  python3 05_scripts/pruebas/verificar-panel.py normalizar [--stpr simulador.stpr] [--root <repo>]
  python3 05_scripts/pruebas/verificar-panel.py mover      [--stpr simulador.stpr] viejo=nuevo [viejo=nuevo ...]
"""
import argparse
import os
import struct
import subprocess
import sys

TC_NULL, TC_REFERENCE, TC_CLASSDESC, TC_OBJECT, TC_STRING, TC_ARRAY = 0x70, 0x71, 0x72, 0x73, 0x74, 0x75
TIPO_ARCHIVO = 0
TC_BLOCKDATA, TC_ENDBLOCKDATA, TC_LONGSTRING, TC_BLOCKDATALONG = 0x77, 0x78, 0x7C, 0x7A
SC_WRITE_METHOD = 0x01
PRIM = {'B': 1, 'C': 2, 'D': 8, 'F': 4, 'I': 4, 'J': 8, 'S': 2, 'Z': 1}


class Lector:
    """Lector del protocolo de serialización de Java (el subconjunto que usa el Project Manager de Stata)."""

    def __init__(self, b):
        self.b, self.i, self.handles = b, 0, []
        self.items = []          # [{isRelPath, type, name, path, path_span}] ; path_span = (inicio, fin) del TC_STRING

    def u(self, fmt):
        n = struct.calcsize(fmt)
        v = struct.unpack('>' + fmt, self.b[self.i:self.i + n])
        self.i += n
        return v[0] if len(v) == 1 else v

    def utf(self):
        n = self.u('H')
        s = self.b[self.i:self.i + n].decode('utf-8')
        self.i += n
        return s

    def contenido(self):
        """Lee un objeto; devuelve (valor, (inicio, fin, era_referencia))."""
        ini = self.i
        tc = self.u('B')
        if tc == TC_NULL:
            return None, (ini, self.i, False)
        if tc == TC_REFERENCE:
            return self.handles[self.u('i') - 0x7E0000], (ini, self.i, True)
        if tc == TC_STRING:
            s = self.utf()
            self.handles.append(s)
            return s, (ini, self.i, False)
        if tc == TC_LONGSTRING:
            n = self.u('q')
            s = self.b[self.i:self.i + n].decode('utf-8')
            self.i += n
            self.handles.append(s)
            return s, (ini, self.i, False)
        if tc == TC_CLASSDESC:
            self.i -= 1
            return self.descriptor(), (ini, self.i, False)
        if tc == TC_OBJECT:
            return self.objeto(), (ini, self.i, False)
        if tc == TC_ARRAY:
            desc = self.descriptor()
            h = len(self.handles)
            self.handles.append(None)
            n = self.u('i')
            t = desc['nombre'][1]
            vals = [self.campo(t) for _ in range(n)]
            self.handles[h] = vals
            return vals, (ini, self.i, False)
        if tc in (TC_BLOCKDATA, TC_BLOCKDATALONG):
            n = self.u('B') if tc == TC_BLOCKDATA else self.u('i')
            self.i += n
            return ('blockdata', n), (ini, self.i, False)
        raise ValueError('typecode 0x%02x no soportado en el byte %d' % (tc, ini))

    def descriptor(self):
        tc = self.u('B')
        if tc == TC_NULL:
            return None
        if tc == TC_REFERENCE:
            return self.handles[self.u('i') - 0x7E0000]
        if tc != TC_CLASSDESC:
            raise ValueError('se esperaba un descriptor de clase en el byte %d' % (self.i - 1))
        d = {'nombre': self.utf()}
        self.u('q')
        self.handles.append(d)
        d['flags'] = self.u('B')
        d['campos'] = []
        for _ in range(self.u('H')):
            t = chr(self.u('B'))
            nombre = self.utf()
            if t in 'L[':
                self.contenido()
            d['campos'].append((t, nombre))
        self.anotacion()
        d['super'] = self.descriptor()
        return d

    def anotacion(self):
        while self.b[self.i] != TC_ENDBLOCKDATA:
            self.contenido()
        self.i += 1

    def campo(self, t):
        if t in PRIM:
            n = PRIM[t]
            v = self.b[self.i:self.i + n]
            self.i += n
            return (int.from_bytes(v, 'big', signed=True), None)
        return self.contenido()

    def objeto(self):
        desc = self.descriptor()
        h = len(self.handles)
        obj = {'clase': desc['nombre']}
        self.handles.append(obj)
        cadena, d = [], desc
        while d:
            cadena.insert(0, d)
            d = d['super']
        for d in cadena:
            for t, nombre in d['campos']:
                obj[nombre] = self.campo(t)
            if d['flags'] & SC_WRITE_METHOD:
                self.anotacion()
        if obj['clase'] == 'com.stata.projmanager.ProjItem':
            self.items.append(dict(isRelPath=bool(obj['isRelPath'][0]), type=obj['type'][0], name=obj['name'][0],
                                   path=obj['path'][0], path_span=obj['path'][1]))
        self.handles[h] = obj
        return obj

    def leer(self):
        if self.u('H') != 0xACED:
            raise ValueError('no es una serialización Java (magic distinto de ACED)')
        self.u('H')
        while self.i < len(self.b):
            self.contenido()
        return self.items


def items(ruta):
    return Lector(open(ruta, 'rb').read()).leer()


def main():
    ap = argparse.ArgumentParser(description='Rutas de simulador.stpr: listar, verificar, mover (solo el campo path).')
    ap.add_argument('accion', choices=['listar', 'verificar', 'normalizar', 'mover'])
    ap.add_argument('pares', nargs='*', help='mover: viejo=nuevo')
    ap.add_argument('--stpr', default=None, help='default: <raíz del repo>/simulador.stpr')
    ap.add_argument('--root', default=None, help='verificar: raíz contra la que se resuelven los paths relativos')
    a = ap.parse_args()
    repo = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    stpr = a.stpr or os.path.join(repo, 'simulador.stpr')
    root = a.root or os.path.dirname(os.path.abspath(stpr))
    its = [it for it in items(stpr) if it['type'] == TIPO_ARCHIVO]

    if a.accion == 'listar':
        for it in its:
            print('%s\t%s\t%s' % ('relativa' if it['isRelPath'] else 'absoluta', it['path'], it['name']))
        return 0

    if a.accion == 'verificar':
        rotas, locales = [], []
        for it in its:
            p = it['path'] or ''
            if not it['isRelPath'] or os.path.isabs(p):
                rotas.append((p, 'ruta absoluta: no viaja entre clones'))
            elif not os.path.exists(os.path.join(root, p)):
                ign = subprocess.run(['git', '-C', root, 'check-ignore', '-q', '--no-index', '--', p],
                                     stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0
                (locales if ign and not p.startswith('../') else rotas).append((p, 'no existe'))
        for p, _ in locales:
            print('  AVISO: %s no está en este árbol; .gitignore lo excluye a propósito (archivo local por diseño)' % p)
        for p, por in rotas:
            print('  ROTA: %s (%s)' % (p, por))
        print('verificar-panel.py: %d rutas de archivo en %s, %d rotas' % (len(its), os.path.relpath(stpr, root), len(rotas)))
        return 1 if rotas else 0

    destinos = []                 # (item, ruta nueva)
    if a.accion == 'normalizar':
        sin_resolver = []
        for it in its:
            p = it['path'] or ''
            if not (p.startswith('../') or os.path.isabs(p)):
                continue
            partes = [x for x in p.split('/') if x not in ('', '.', '..')]
            q = next(('/'.join(partes[i:]) for i in range(len(partes)) if os.path.isfile(os.path.join(root, *partes[i:]))), None)
            if q is None or not it['isRelPath']:
                sin_resolver.append(p)
            else:
                destinos.append((it, q))
        for p in sin_resolver:
            print('  SIN RESOLVER: %s (sale del repo y ningún final de la ruta existe en él, o el panel la marca absoluta)' % p)
    else:
        pares = []
        for par in a.pares:
            if '=' not in par:
                ap.error('mover espera pares viejo=nuevo: %r' % par)
            pares.append(tuple(par.split('=', 1)))
        for it in its:
            p = it['path'] or ''
            for viejo, nuevo in pares:
                if p == viejo or p.startswith(viejo.rstrip('/') + '/'):
                    destinos.append((it, nuevo + p[len(viejo):]))
                    break
    b = open(stpr, 'rb').read()
    cambios = []
    for it, q in destinos:
        ini, fin, ref = it['path_span']
        if ref:
            sys.exit('verificar-panel.py: el path %r es una referencia a otra cadena del .stpr; no se reescribe '
                     'sin rehacer los handles (ábrelo en el Project Manager)' % it['path'])
        cod = q.encode('utf-8')
        cambios.append((ini, fin, bytes([TC_STRING]) + struct.pack('>H', len(cod)) + cod, it['path'], q))
    for ini, fin, nuevo_b, _, _ in sorted(cambios, reverse=True):
        b = b[:ini] + nuevo_b + b[fin:]
    if cambios:
        Lector(b).leer()   # el resultado se vuelve a leer completo antes de escribir
        open(stpr, 'wb').write(b)
    for _, _, _, p, q in cambios:
        print('  %s -> %s' % (p, q))
    print('verificar-panel.py %s: %d ruta(s) reescrita(s) en %s' % (a.accion, len(cambios), stpr))
    return 0


if __name__ == '__main__':
    sys.exit(main())
