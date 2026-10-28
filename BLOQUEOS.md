# Bloqueos y pendientes que necesitan una decisión tuya

Nada de esto impide la demo local: todo funciona y está verificado en tu máquina. Son pasos que no podía
(o no debía) hacer solo.

## 1. Push de la rama y Pull Request del back-end

- **Qué pasó**: `gh` (GitHub CLI) no está instalado y acordamos **no pushear nada**.
- **Estado**: la rama `tp2-integracion` tiene todos los commits locales sobre `main`. No se tocó `main`.
- **Qué necesito de vos**: revisar y pushear.

  ```bash
  cd D:\Programacion\RUBY\farma-check\Farma-Check
  git log --oneline main..tp2-integracion     # revisar los commits
  git push -u origin tp2-integracion
  ```

  Después abrí el PR **contra `main`** desde GitHub (botón "Compare & pull request"), o instalá gh
  (`winget install GitHub.cli`, `gh auth login`) y corré:

  ```bash
  gh pr create --base main --head tp2-integracion --title "TP 2: integración API + front-end" --body-file RESUMEN_NOCHE.md
  ```

- **Nota**: el prompt decía "PR contra `master`", pero el repo no tiene `master`: la rama por defecto es
  `main` (lo confirmaste antes de empezar). Por eso también cambié el disparador del CI a `push: [main]`.

## 2. Crear el repo del front en GitHub

- **Qué pasó**: sin `gh` y sin push no pude crear `Kano55K/farma-check-front`.
- **Estado**: el repo está listo en local en `D:\Programacion\RUBY\farma-check-front` (rama `main`).
- **Qué necesito de vos**: crear el repo **público** vacío `farma-check-front` en GitHub (sin README ni .gitignore) y:

  ```bash
  cd D:\Programacion\RUBY\farma-check-front
  git remote add origin https://github.com/Kano55K/farma-check-front.git
  git push -u origin main
  ```

  O con gh: `gh repo create farma-check-front --public --source . --push`.

## 3. Datos del equipo en los documentos

- `README.md` y `docs/checkpoint.md` tienen los marcadores **`{{INTEGRANTES}}`** y **`{{MODALIDAD}}`**:
  reemplazalos por los integrantes y la modalidad de trabajo.

## 4. Repo git externo vacío

- `D:\Programacion\RUBY\farma-check` es un repositorio git **sin commits** que contiene a `Farma-Check/`
  como carpeta sin seguimiento (probablemente quedó de algún `git init` anterior). No lo toqué. Si no lo
  usás, podés borrar `D:\Programacion\RUBY\farma-check\.git` para evitar confusiones (el repo real del
  back-end es `Farma-Check/.git`).

## 5. Dos Ruby instalados

- En el PATH hay `D:\Ruby33-x64` (3.3.12, la que se usó y está en `.ruby-version`) y `D:\Ruby40-x64`.
  Si alguna terminal toma Ruby 4.0, `bundle install` puede fallar o resolver otras versiones. Verificá
  con `ruby -v` antes de correr los comandos.

## 6. Ramas de Dependabot

- Hay 11 ramas remotas de Dependabot (Rails 8.1.4, brakeman, sqlite3, actions/checkout@7, etc.) sin
  mergear. No las toqué. Brakeman sí lo actualicé a 8.1.0 en `tp2-integracion`, porque `bin/brakeman`
  usa `--ensure-latest` y fallaba con 8.0.6; la rama `dependabot/bundler/brakeman-8.1.0` queda redundante.
