# Pink Flamingo 🦩

App de catálogo, kits e pedidos da **Pink Flamingo** (decoração de festas), feito em Flutter.

## Telas

- **Home** — logo, boas-vindas e atalhos para as categorias.
- **Produtos** — catálogo completo (448 itens) com busca, filtro por categoria e cadastro.
- **Categorias** — 12 categorias com descrição e contagem de itens.
- **Kits** — temas/kits prontos (Barbie, Frozen, Harry Potter, …).
- **Pedidos** — montagem de pedidos com cliente, data do evento, itens e total.

## Rodando

```bash
flutter pub get
flutter run            # com um simulador/dispositivo conectado
```

No iOS, o Xcode precisa estar instalado e selecionado:

```bash
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
open -a Simulator
flutter run
```

## Backend / API

O app conversa com a API em [`backend/`](backend/README.md) (Express + SQLite + multer):

```bash
cd backend && npm install && npm run seed && npm start   # http://localhost:3333
```

Fluxo no app (`lib/state/app_state.dart` + `lib/services/api_service.dart`):

- Na inicialização busca catálogo/categorias/kits da API. **Se o servidor estiver
  offline, usa o seed local** (`lib/data/seed_data.dart`) — o app nunca quebra.
- **Imagens** carregam por URL (`Image.network`, com cache em memória).
- **Admin (entrada escondida)**: **segure (long-press) o logo "Pink Flamingo"** na
  Home (ou o título de Produtos/Categorias/Kits) → login `admin` / `pinkflamingo`.
  Só então aparecem **“+ Add”**, **editar/excluir** e **Pedidos recebidos**. O
  cliente comum não vê nada disso.
- **Foto pelo app**: no formulário de produto (admin) dá pra escolher da galeria/
  câmera (`image_picker`) e enviar via multipart pro backend. *No simulador use a
  galeria — a câmera só funciona em device físico.*
- **Pedidos**: o cliente monta e toca **“Enviar pedido”** → `POST /api/orders`.

Base URL configurável: `flutter run --dart-define=API_BASE_URL=http://SEU_IP:3333`
(use o IP da máquina para rodar em celular físico).

## Dados (seed)

`lib/data/seed_data.dart` (e o seed do backend) vêm do inventário `report001.pdf`,
processado por `tools/segment.py`. Nomes com `…` são truncados na própria fonte (PDF).
Regenerar: `python3 tools/segment.py`.
