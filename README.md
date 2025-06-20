# Scripts para el servidor de Viveza Textil

Este repositorio contiene los scripts necesarios para la administracion del servidor de Viveza Textil.

---

## Scripts
- **[backups](https://github.com/vivezatextil/server-scripts/tree/main/backups)**: Script para realizar los backups del servidor de manera segura.

---

## 1. Configuración necesaria antes de la instalación

Para poder instalar estos scripts en el servidor (por primera vez) es necesario tener Git instalado y configurado. Puedes verlo en la [documentación del servidor](https://github.com/vivezatextil/server-scripts/tree/main). Además es necesario lo siguiente:


### 1.1 Configuración de claves SSH para autenticación con la cuenta de Github de [Viveza Textil](https://github.com/vivezatextil)

Primero inicia sesión en la cuenta de Github de Viveza, ve a configuración en [SSH and GPG keys](https://github.com/settings/keys), aqui registraremos nuestra clave publica SSH para poder clonar el repositorio.

Ahora genera las claves SSH:

```bash
ssh-keygen -t ed25519 -C "soporte@vivezatextil.com"
```

Para el nombre de las claves usa: `id_ed25519_github_vivezatextil`.

Después agregamos la clave SSH privada al `ssh-agent`:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519_github_vivezatextil
```

Por último, creamos el archivo de configuracion SSH en `~/.ssh/config` para agregar el alias y que no nos solicite la contraseña cada vez que clonemos o actualicemos el repositorio:

```bash
# Cuenta Github (vivezatextil)
Host github-vivezatextil
        HostName github.com
        User git
        IdentityFile ~/.ssh/id_ed25519_github_vivezatextil
        IdentitiesOnly yes
```

Probamos la conexión para ver que funcione:

```bash
ssh -T git@github-vivezatextil
```

Si recibes un error, indica que hay problema con la clave o el alias.

---

## 2. Instalación de los scripts

Para instalar los cripts en el servidor basta con ejecutar:

```bash
curl -o- https://raw.githubusercontent.com/vivezatextil/server-scripts/refs/heads/main/install.sh?token=GHSAT0AAAAAADF2TV5CRGPQHIN4RFPJ7DW42CVTQMA | sudo bash
```

Esto clonara el repositorio en `/opt/server-scripts`, creará los symlinks y estaran disponibles para usar globalmente. Es importante realizar la instalación con un usuario con privilegios `sudo`.

Para la **configuración de los backups** vea la [documentación del script `backupmgr.sh`](https://github.com/vivezatextil/server-scripts/blob/main/backupmgr/README.md). Omita el paso 3 si se instaló mediante el script de instalación `install.sh`.
