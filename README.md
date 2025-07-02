# Scripts para el servidor de Viveza Textil

Este repositorio contiene los scripts necesarios para la administración del servidor de Viveza Textil.

---

## Scripts

- **[backupmgr](https://github.com/vivezatextil/server-scripts/tree/main/backupmgr)**: Script para realizar backups seguros del servidor.
- **[usermgr](https://github.com/vivezatextil/server-scripts/tree/main/usermgr)**: Gestor avanzado de usuarios SSH con roles, bloqueo, reportes y auditoría.

---

## 1. Configuración necesaria antes de la instalación

### 1.1 Configuración de claves SSH para autenticación con la cuenta de Github de [Viveza Textil](https://github.com/vivezatextil)

Primero inicia sesión en la cuenta de Github de Viveza, ve a configuración en [SSH and GPG keys](https://github.com/settings/keys) y registra tu clave pública SSH.

Genera las claves SSH con:

```bash
ssh-keygen -t ed25519 -C "soporte@vivezatextil.com" -f ~/.ssh/id_ed25519_github_vivezatextil
```

Agrega la clave SSH privada al `ssh-agent`:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github_vivezatextil
```

Configura el alias SSH en `~/.ssh/config`:

```bash
Host github-vivezatextil
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519_github_vivezatextil
    IdentitiesOnly yes
```

Prueba la conexión:

```bash
ssh -T git@github-vivezatextil
```

---

## 2. Instalación de los scripts

Ejecuta la instalación automatizada:

```bash
curl -o- https://raw.githubusercontent.com/vivezatextil/server-scripts/main/install.sh | sudo bash
```

Esto clona el repositorio en `/opt/server-scripts`, asigna permisos, crea symlinks para los comandos globales `backupmgr` y `usermgr`.

**Importante:** Ejecutar como usuario con permisos `sudo`.

---

## 3. Uso básico

- Ejecuta el gestor de usuarios con:

```bash
sudo usermgr
```

- Ejecuta el gestor de backups con:

```bash
sudo backupmgr
```

---

## 4. Documentación adicional

Para configurar y usar el backup, consulta la documentación de [backupmgr](https://github.com/vivezatextil/server-scripts/blob/main/backupmgr/README.md).

Para más información sobre el gestor de usuarios, consulta [usermgr](https://github.com/vivezatextil/server-scripts/blob/main/usermgr/README.md).

