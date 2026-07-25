healthcare

healthcare desenvolvimento solo.

## Quem sou eu (autor)

Cosmo (Diogo Boeno Pereira) — solo dev brasileiro.
Trabalho em PT-BR. **Comentários no código em EN.**
Prefiro respostas diretas, sem preamble. Não explica o óbvio. Cortar fluff.

## Stack

- **IDE**: Antigravity (fork do VS Code)
- **Build**: Rojo (`default.project.json`)
- **Packages**: Wally — vide, ui-labs
- **Tooling**: Aftman gerencia Selene + StyLua + Rojo
- **DataStore**: ProfileService (Madwork) via `PlayerDataService`
- **UI lib**: Vide (Solid.js-inspired, reativo — NUNCA usar Roact)
- **UI dev**: UI Labs pra stories isoladas em `ReplicatedStorage/Stories/`

## Comandos

Aftman gerencia os binários (`rojo`, `wally`, `selene`, `stylua`) — versões pinadas em `aftman.toml`.
**Não existe test runner.** "Testar" = lint limpo + format + `rojo build` compila sem erro.

```bash
aftman install   # instala tooling pinado
wally install    # baixa deps (vide, ui-labs) em Packages/

rojo serve       # dev: serve pro plugin Rojo no Studio

selene src/      # lint (passa arquivos/pastas alterados em vez de src/ inteiro)
stylua src/      # format (idem)

# sanity check: compila tudo num .rbxlx, NÃO abre no Studio
rojo build default.project.json -o "$env:TEMP/lumbersim_test.rbxlx"
```

Stories (UI Labs) rodam dentro do Studio via plugin — não há CLI pra elas.

## Framework custom

Em `src/ReplicatedStorage/Shared/Framework/`:

- **Loader** — `LoadDescendants(folder)` + `Start()`. `Init()` de todos roda em
  sequência, depois cada `Start()` em `task.spawn` (paralelo). Ambos são opcionais
  e protegidos por pcall — falha de um módulo só dá `warn`, não derruba o boot.
  Entry points: `ServerScriptService/Bootstrap.server.luau` carrega `Services/`,
  `StarterPlayerScripts/Bootstrap.client.luau` carrega `Controllers/`. Pra registrar
  um service/controller novo, basta o ModuleScript retornar uma table (com `Init`/`Start`
  opcionais) na pasta certa — é auto-descoberto, sem require manual.
- **Net** — `Ensure`, `FireClient`, `FireAllClients`, `FireServer`, `On`
- **Signal** — `new`, `Connect`, `Once`, `Fire`, `Wait`, `Destroy`
- **State** — key-value global com signals por chave (`Set`, `Get`, `Update`, `OnChange`, `Observe`)

Detalhes: `docs/framework/`

## Estrutura de pastas

```
src/
├── ReplicatedFirst/Loading.client.luau      <-- loading screen pré-tudo
├── ReplicatedStorage/
│   ├── Shared/
│   │   ├── Framework/     <-- Loader, Net, Signal, State
│   │   ├── Modules/       <-- Axe, Dialog, Inventory, TreeSpawner, etc
│   │   └── UI/            <-- componentes Vide (+ UI/Common/ reutilizáveis)
│   └── Stories/           <-- UI Labs stories (*.story.luau), fora de Shared/
├── ServerStorage/                          <-- assets server-only (vazio por ora)
├── ServerScriptService/
│   ├── Bootstrap.server.luau
│   └── Services/          <-- *Service.luau
└── StarterPlayerScripts/
    ├── Bootstrap.client.luau
    └── Controllers/       <-- *Controller.luau
```

Detalhes: `docs/ARCHITECTURE.md`

## Convenções principais

- **Comentários em English**, explicam o **por quê** não o **o quê**
- `--!strict` em arquivos novos quando possível
- Naming:
  - Módulos / Services / Controllers: PascalCase (`PlayerDataService`)
  - Lifecycle methods (Start, Init) e Signals públicas: PascalCase (`:Start()`, `OnSomething`)
  - API helpers públicas de modules: **camelCase com `.`** (`Service.addCoins(player, n)`)
  - Variáveis e funções locais: camelCase
  - Constantes module-level: UPPER_SNAKE
- **Module-level state** (`local active`, `local menuRig`), não OOP self-heavy
- UI sempre Vide, sintaxe `create "Frame" { ... }` (sem parênteses)
- Events Vide direto na props: `Activated = function() end`
- Stylua decide formatação — não brigar com ele

Detalhes: `docs/CONVENTIONS.md`

## Estado: 3 mecanismos

| Mecanismo | Pra quê |
|---|---|
| `PlayerDataService` (ProfileService) | Dados persistentes (coins, level, inventory) |
| `player:SetAttribute(...)` | Replicação simples server→client (CurrentAxe, Coins) |
| `Vide.source()` | UI local reativa em Controllers |

`Framework/State.luau` existe como fallback global (raro). Detalhes em `docs/framework/STATE.md`.

## UI Design

**Estilo: AAA indie.**
NÃO usar visual cartoon-simulator genérico de Roblox.

Princípios: paleta restrita (preto/branco/cinza), corner brackets como assinatura,
dot pattern sutil, tipografia chunky bold, amber como único accent ocasional.

Detalhes: `docs/ui/DESIGN_SYSTEM.md`
Componentes (sintaxe Vide real): `docs/ui/COMPONENTS.md`
Referência visual: `docs/ui/references/`

## Workflows

- Criar service novo → `docs/workflow/NEW_SERVICE.md`
- Criar UI nova → `docs/workflow/NEW_UI.md`
- Debugging → `docs/workflow/DEBUGGING.md`

Não há pasta `templates/`. Pra padrão canônico, copia um Service/Controller/UI
existente (ex.: `Services/AxeService.luau`, `Controllers/EquipController.luau`,
`UI/Common/Button.luau`).

## Regras absolutas

- Nunca usar Roact (sempre Vide)
- Nunca usar verde Roblox saturado (#2ecc71) em CTAs de UI
- Nunca usar RemoteEvent direto — sempre via Net
- Nunca manipular `profile.Data` direto — sempre via API do PlayerDataService
- Nunca usar `wait()` — usa `task.wait()`
- Comentários explicam **por quê**, não **o quê**, em Inglês

## Como me ajudar de verdade

- Se eu pedir algo que viola as regras acima, me avise antes de fazer
- Se uma decisão de arquitetura é ambígua, pergunta antes de escolher
- Quando criar arquivo novo, segue o template em `templates/` e o workflow correspondente
- Quando tiver dúvida sobre estilo de UI, consulta `docs/ui/DESIGN_SYSTEM.md`
- Pra exemplos reais do meu jeito de codar, olha os Services existentes em
  `src/ServerScriptService/Services/` e Controllers em
  `src/StarterPlayerScripts/Controllers/`
- Não usa biblioteca externa nova sem perguntar — Wally já tem o que preciso
