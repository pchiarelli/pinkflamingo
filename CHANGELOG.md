# Changelog

Todas as mudanças relevantes deste projeto são documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.0.0/)
e o projeto adota [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [0.0.2] - 2026-06-17

### Corrigido

- **App:** a foto não era salva ao editar (nem ao criar) um item. O upload era
  enviado sem `Content-Type`, chegando ao backend como `application/octet-stream`
  e sendo descartado pelo filtro de imagens. Na edição isso mantinha a foto
  antiga, dando a impressão de que nada havia sido salvo. Agora o app detecta e
  envia o tipo MIME correto da imagem.
- **Backend:** o filtro de upload (`multer`) agora aceita arquivos também pela
  extensão, além do MIME type, evitando descartar imagens de clientes que não
  informam o `Content-Type`.

## [0.0.1]

### Adicionado

- Versão inicial: app Flutter + backend Express/SQLite, admin web e deploy
  (nginx + pm2, HTTPS).
