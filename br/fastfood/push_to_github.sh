#!/usr/bin/env bash
# push_to_github.sh
# Use na raiz do repositório local para adicionar/atualizar remote e enviar para GitHub.
# Exemplo:
#   chmod +x push_to_github.sh
#   ./push_to_github.sh
#
# Variáveis:
#   REMOTE_URL pode ser definido no ambiente para substituir o padrão.
#   FORCE=true pula prompts interativos.

set -euo pipefail

# Configurável: URL do repositório remoto (padrão adiciona .git)
DEFAULT_REMOTE_URL="https://github.com/jpcd12/br.fastfood.git"
REMOTE_URL="${REMOTE_URL:-$DEFAULT_REMOTE_URL}"
FORCE="${FORCE:-false}"

# Verifica se estamos dentro de um repositório git
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Erro: este diretório não é um repositório Git. Execute o script a partir da raiz do seu repositório."
  exit 1
fi

# Verifica mudanças não commitadas
if git status --porcelain | grep -q .; then
  echo "Atenção: existem mudanças não commitadas neste repositório."
  if [ "$FORCE" != "true" ]; then
    read -p "Deseja continuar mesmo assim? (y/N) " yn
    case "$yn" in
      [Yy]*) ;;
      *) echo "Abortando. Faça commit ou defina FORCE=true e execute novamente."; exit 1;;
    esac
  fi
fi

# Detecta remote origin atual (se houver)
CURRENT_ORIGIN=""
if git remote get-url origin >/dev/null 2>&1; then
  CURRENT_ORIGIN="$(git remote get-url origin)"
  echo "Remote 'origin' existente: $CURRENT_ORIGIN"
  if [ "$FORCE" != "true" ]; then
    read -p "Deseja sobrescrever 'origin' com ${REMOTE_URL}? (y/N) " resp
    case "$resp" in
      [Yy]*)
        git remote set-url origin "${REMOTE_URL}"
        echo "Remote 'origin' atualizado para ${REMOTE_URL}"
        ;;
      *)
        echo "Mantendo remote 'origin' atual: $CURRENT_ORIGIN"
        ;;
    esac
  else
    git remote set-url origin "${REMOTE_URL}"
    echo "Remote 'origin' forçado para ${REMOTE_URL}"
  fi
else
  git remote add origin "${REMOTE_URL}"
  echo "Remote 'origin' adicionado: ${REMOTE_URL}"
fi

# Garante que o branch principal seja 'main' (altera se necessário)
# Use a branch atual como base para renomear
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "Branch atual: $CURRENT_BRANCH. Renomeando para 'main'."
  git branch -M main
else
  echo "Branch já é 'main'."
fi

# Push para origin main
echo "Fazendo push para origin main..."
git push -u origin main

echo "Push concluído com sucesso para ${REMOTE_URL} (branch main)."