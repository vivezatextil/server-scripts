# Backup Seguro y Automático con rclone + Google Drive

---

## 1. Instalar rclone

```bash
sudo curl https://rclone.org/install.sh | sudo bash
```

Verifica la instalación:

```bash
rclone version
```

---

## 2. Configurar rclone para Google Drive con cifrado

1. Ejecuta:

```bash
rclone config
```

2. Crea un nuevo remote:

- Elige `n` para nuevo remote.
- Nómbralo, por ejemplo, `gdrive`.
- Selecciona tipo drive (Google Drive).
- Sigue los pasos para autenticar tu cuenta de Google (usa un navegador externo).
- Configura acceso completo (full access).
- Cuando termine, crea un remote cifrado sobre este:
    - Nuevo remote, nombre `gdrive_enc`.
    - Tipo `crypt`.
    - Remote path: `gdrive:backups` (o la carpteta que quieras en Drive).
    - Configura cifrado para nombres y contenido.
    - Genera clave(s) y guardala(s) en `/etc/rclone/keys/`
    - Guarda la contraseña de cifrado Bitwarden como una nueva nota y agrégale un campo de contraseña personalizado.

3. Prueba que puedes listar el contenido:

```bash
rclone ls gdrive_enc:
```

---

## 3. Descargar y configurar script de backup seguro.

Clona el repositorio en algun lugar de tu `home`, por ejemplo en `~/temp`. Para clonar el repositorio recuerda tener antes las claves SSH y los aliases necesarios. Puedes ver como hacerlo en la [documentación principal](https://github.com/vivezatextil/server-scripts/blob/main/README.md#1-configuraci%C3%B3n-necesaria-antes-de-la-instalaci%C3%B3n) del repositorio.

```bash
cd ~
mkdir -p temp
cd temp
git clone git@github-vivezatextil:vivezatextil/server-scripts.git
```

Luego mueve el repositorio completo a `/opt/`:

```bash
mv server-scripts /opt/server-scripts
```

Entra a la carpeta `/opt/server-scripts` y luego a `backupmgr/`. Crea un symlink del script en `/usr/local/bin/` y dale permisos de ejecución para que se pueda ejecutar globalmente.

```bash
cd /opt/server-scripts/backupmgr/
sudo chmod +x backupmgr.sh
sudo ln -s backupmgr.sh /usr/local/bin/backupmgr
```

---

## 4. Automatizar con cron

Edita crontab de root:

```bash
sudo crontab -e
```

Agrega la siguiente línea para ejecutar backup diario a las 2 AM:

```cron
0 2 * * * backupmgr >> /var/log/backupmgr.log 2>&1
```

---

## 5. Seguridad y buenas practicas

- Asegúrate que el archivo `/opt/server-scripts/backupmgr.sh` y credenciales rclone tengan permisos estrictos (600).
- No compartas claves de cifrado ni token de Google Drive.
- Revisa periodicamente `/var/log/backupmgr.log` para verificar que los backups se realizan sin errores.
- Prueba restaurar un backup para validar proceso.

---

## 6. Restauración de backup

Para restaurar un backup:

1. Descarga el archivo deseaso del remote cifrado con:

```bash
rclone copy gdrive_enc:backup_YYYY-MM-DD_HH-MM-SS.tar.gz /tmp/
```

2. Descomprime:

```bash
sudo tar -zxf /tmp/backup_YYYY-MM-DD_HH-MM-SS.tar.gz -C /
```
