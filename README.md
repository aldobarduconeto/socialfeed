<div align="center">

  <img src="assets/icon/socialfeed.png" alt="SocialFeed Logo" width="128" height="128" style="border-radius: 28px; box-shadow: 0 10px 30px rgba(0,0,0,0.25);" />

  # SocialFeed
  
  **O seu feed unificado, cronológico e 100% privado.**  
  *Acompanhe Instagram, TikTok, X (Twitter) e YouTube em um só lugar — sem login, sem algoritmos e sem anúncios.*

  <p align="center">
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter" />
    <img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart" />
    <img src="https://img.shields.io/badge/Plataformas-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20macOS%20%7C%20Linux-4CAF50?style=for-the-badge" alt="Plataformas" />
    <img src="https://img.shields.io/badge/Privacidade-Zero%20Tracking-FF5722?style=for-the-badge&logo=shield" alt="Privacy First" />
    <img src="https://img.shields.io/badge/Licen%C3%A7a-MIT-blue?style=for-the-badge" alt="Licença" />
  </p>

  <p align="center">
    <a href="#-principais-funcionalidades">Funcionalidades</a> •
    <a href="#-design--experiência-liquid-glass">Design & UI</a> •
    <a href="#-redes-suportadas">Redes</a> •
    <a href="#-como-usar">Como Usar</a> •
    <a href="#-instalação-e-execução">Instalação</a> •
    <a href="#-arquitetura-do-projeto">Arquitetura</a> •
    <a href="#-downloads">Downloads</a>
  </p>

</div>

---

## 💡 Sobre o SocialFeed

O **SocialFeed** foi criado para devolver o controle do seu tempo e da sua atenção. As redes sociais modernas foram desenhadas para prender usuários em loops infinitos de algoritmos de recomendação, anúncios invasivos e coletas massivas de dados.

Com o **SocialFeed**, você consome apenas o conteúdo de perfis públicos que você escolheu explicitamente seguir, reunidos em uma única linha do tempo cronológica e elegante, com reprodução direta e **sem necessidade de criar contas ou fazer login em qualquer plataforma**.

---

## ✨ Principais Funcionalidades

### 🌟 Feed Unificado & Cronológico
- **Timeline Centralizada**: Veja postagens do Instagram, vídeos do TikTok, threads do X e novidades do YouTube intercaladas ordenadamente por data de publicação.
- **Zero Algoritmos Viciantes**: As publicações aparecem puramente por ordem cronológica. Sem posts patrocinados e sem sugestões indesejadas.
- **Filtros por Tipo de Mídia**: Alterne instantaneamente entre visualização de **Tudo**, apenas **Vídeos** (Reels/TikToks/YouTube), apenas **Fotos** ou apenas **Texto** (estilo microblog).
- **Ordenação Inteligente**: Ordene o feed por *Mais Recentes*, *Mais Curtidos* ou *Mais Comentados*.
- **Busca em Tempo Real**: Localize qualquer publicação digitando palavras-chave presentes na legenda, nome do autor ou no `@username`.
- **Botão Inteligente de Rolagem**: Retorne ao topo do feed suavemente com o botão flutuante animado com resposta tátil.

### ⭕ Stories Dinâmicos com Progresso
- **Extração Automática**: O SocialFeed reúne os destaques e mídias mais recentes dos perfis seguidos em anéis de Stories no topo da tela.
- **Visualizador Imersivo**: Interface com barras de progresso temporizadas, navegação por gestos de toque lateral e suporte a pausar segurando a tela.
- **Controle de Visualização**: Anéis com gradientes vibrantes para histórias inéditas e visual sutil para histórias já assistidas.

### 🖼️ Visualizador Lightbox com Zoom (Até 4.5x)
- **Pinch-to-Zoom & Pan**: Aproxime imagens com gestos multitoque suaves com suporte até 4.5x de zoom.
- **Double-Tap Inteligente**: Dois toques rápidos focam e ampliam instantaneamente 2.5x no ponto exato do toque.
- **Carrosséis Deslizantes**: Navegue entre múltiplas fotos com indicador flutuante translúcido (`1/3`), atalho de cópia do link original e botão para abrir no navegador nativo.

### 🔖 Aba Exclusiva de Salvos (Favoritos)
- **Marcador com 1 Toque**: Salve qualquer publicação com um toque no ícone de marcador para ler ou assistir mais tarde.
- **Filtro & Busca nos Salvos**: Encontre publicações salvas rapidamente através de busca por texto e chips de filtro por rede social.
- **Persistência Total**: Seus favoritos ficam armazenados com segurança no seu próprio dispositivo.

### 👥 Descoberta e Gerenciamento de Perfis
- **Busca Global Anônima**: Digite qualquer `@arroba` na aba Explorar para encontrar o perfil simultaneamente no Instagram, TikTok, X e YouTube.
- **Pausa Temporária**: Desative temporariamente um perfil para tirá-lo do feed sem precisar excluí-lo da sua lista.
- **Totalmente Local**: As contas que você segue nunca são enviadas para servidores remotos.

### 📊 Painel de Métricas & Insights
- **Dashboard Integrado**: Acompanhe o total de perfis cadastrados, publicações em cache e o engajamento acumulado (curtidas e comentários).
- **Gráfico de Distribuição**: Barra visual colorida que exibe a porcentagem de conteúdo que cada rede social representa no seu feed.

### 💾 Backup & Restauração Completa
- **Exportação JSON**: Copie com um toque todo o seu conjunto de contas seguidas e publicações salvas para a área de transferência.
- **Restauração Rápida**: Transfira sua configuração para outro dispositivo ou recupere seus dados colando o JSON de backup.

### 🗜️ Modo de Visualização Compacto
- Alterne nas configurações entre os cards visuais imersivos e o layout ultracompacto para leitura rápida.

---

## 🎨 Design & Experiência: Liquid Glass

O SocialFeed adota uma linguagem visual inspirada no **Glassmorphism moderno e na estética fluida**:

| Elemento | Descrição |
| :--- | :--- |
| 🫧 **Liquid Background** | Fundo com gradientes orgânicos, orbes de luz e desfoque gaussiano dinâmico que reage ao tema escolhido. |
| 🪟 **Dock Flutuante de Vidro** | Barra de navegação inferior flutuante (`LiquidGlassNavigationBar`) com efeito de vidro fosco, bordas sutis e indicador ativo que desliza suavemente com física de mola. |
| 🖥️ **Layout Adaptativo** | Responsivo em qualquer tela: dock flutuante no celular, drawer modal em tablets e sidebar fixa elegante em desktops widescreen. |
| 🌓 **Temas Dinâmicos** | Alternância em tempo real entre **Modo Escuro Puro** (OLED-friendly), **Modo Claro Refinado** e sincronização automática com o sistema operacional. |
| 🎬 **Inline Video Player** | Player de vídeo embutido nos próprios cards do feed, sem popups invasivos. |

---

## 🌐 Redes Suportadas

O SocialFeed obtém dados exclusivamente de páginas públicas, sem solicitar suas credenciais:

| Plataforma | Conteúdo Acessado | Player Integrado |
| :---: | :--- | :---: |
| <img src="https://api.iconify.design/skill-icons:instagram.svg" width="20" /> **Instagram** | Fotos, Carrosséis, Vídeos e Reels públicos | ✅ |
| <img src="https://api.iconify.design/logos:tiktok-icon.svg" width="20" /> **TikTok** | Vídeos, legendas e sons de contas abertas | ✅ |
| <img src="https://api.iconify.design/ri:twitter-x-fill.svg" width="20" /> **X (Twitter)** | Tweets, threads de texto, fotos e vídeos da timeline pública | ✅ |
| <img src="https://api.iconify.design/logos:youtube-icon.svg" width="20" /> **YouTube** | Uploads recentes, Shorts e metadados via feed RSS/Atom público | ✅ |

> [!NOTE]
> Por utilizar dados públicos e não exigir autenticação, perfis privados ou conteúdos que exigem confirmação de idade não são exibidos. O app implementa cache offline automático caso uma rede passe por instabilidade temporária.

---

## 📱 Navegação do Aplicativo

A interface é dividida em 5 abas intuitivas:

```text
┌─────────────────────────────────────────────────────────────┐
│                      SOCIALFEED                             │
├─────────┬──────────────┬─────────────┬────────────┬─────────┤
│  Feed   │   Explorar   │   Salvos    │   Contas   │ Ajustes │
│  (Home) │   (Busca)    │ (Favoritos) │ (Perfis)   │(Insights│
└─────────┴──────────────┴─────────────┴────────────┴─────────┘
```

1. **Feed**: Linha do tempo unificada com stories no topo, filtros rápidos de mídia (Vídeos/Fotos/Texto), busca e ordenação.
2. **Explorar**: Busque novos criadores em todas as redes ao mesmo tempo sem precisar abrir cada app individualmente.
3. **Salvos**: Sua biblioteca particular de publicações favoritas para ler ou rever mais tarde, com busca interna.
4. **Contas**: Gerenciador com status ativo/pausado de cada criador e opção de adicionar novos perfis.
5. **Ajustes**: Controle de temas, dashboard de métricas, modo compacto, exportação/importação de backups e limpeza de cache.

---

## 🔒 Privacidade e Segurança

- 🚫 **Sem Login Obrigatório**: Nunca solicitamos seu usuário ou senha de nenhuma rede social.
- 🛡️ **Zero Rastreamento**: Sem SDKs de telemetria, anúncios, Firebase Analytics ou pixels de rastreamento.
- 🏠 **Dados 100% Locais**: Contas seguidas, histórico de busca e posts salvos ficam salvos exclusivamente no `SharedPreferences` do seu aparelho.
- 📦 **Código Aberto**: Você pode inspecionar exatamente o que o aplicativo faz no código-fonte.

---

## 🚀 Instalação e Execução

### Pré-requisitos
- [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado (versão 3.x recomendada).
- SDK da plataforma alvo configurado (Android Studio, Xcode, Visual Studio C++, etc.).

### Rodando em Modo de Desenvolvimento

1. **Clone o repositório:**
   ```bash
   git clone https://github.com/aldobarduconeto/socialfeed.git
   cd socialfeed
   ```

2. **Instale as dependências:**
   ```bash
   flutter pub get
   ```

3. **Verifique os dispositivos conectados:**
   ```bash
   flutter devices
   ```

4. **Execute o projeto:**
   ```bash
   flutter run -d <id-do-dispositivo>
   ```

---

## 📦 Compilação para Produção

O SocialFeed é compatível com compilações nativas para todas as plataformas:

| Plataforma | Formato Gerado | Comando de Build |
| :--- | :--- | :--- |
| **Android** | `.apk` | `flutter build apk --release` |
| **Windows** | `.exe` (Inno Setup) | `flutter build windows --release` |
| **Linux** | `.deb` | `flutter build linux --release` |
| **macOS** | `.dmg` | `flutter build macos --release` |
| **iOS** | `.ipa` | `flutter build ipa --release` |

---

## 🏗️ Arquitetura do Projeto

O código segue padrões limpos, divididos por responsabilidade e sem dependência de gerenciadores de estado externos pesados:

```text
socialfeed/
├── lib/
│   ├── main.dart                  # Ponto de entrada, configuração de temas e rotas
│   ├── models/                    # Modelagem de dados
│   │   ├── feed_item.dart         # Estrutura unificada de posts, mídias e estatísticas
│   │   ├── platform_type.dart     # Enum com cores, ícones e metadados das plataformas
│   │   ├── social_account.dart    # Estrutura dos perfis seguidos
│   │   └── story_item.dart        # Modelo para stories e status de visualização
│   ├── screens/                   # Telas principais
│   │   ├── main_screen.dart       # Shell de navegação responsiva (Dock / Sidebar)
│   │   ├── feed_screen.dart       # Feed principal com busca, filtros e stories
│   │   ├── anonymous_search_screen.dart # Busca universal de perfis
│   │   ├── saved_posts_screen.dart# Aba dedicada de publicações salvas
│   │   ├── accounts_screen.dart   # Gerenciamento de perfis ativos/pausados
│   │   └── settings_screen.dart   # Ajustes, métricas, temas e backup
│   ├── services/                  # Serviços de infraestrutura
│   │   ├── social_service.dart    # Extratores HTTP e parsers de conteúdo público
│   │   └── storage_service.dart   # Persistência local (Cache, Salvos, Backup JSON)
│   └── widgets/                   # Componentes reutilizáveis
│       ├── unified_post_card.dart # Card completo de postagem (Mídia, Legenda, Ações)
│       ├── image_viewer_screen.dart # Lightbox com pinch-to-zoom (4.5x) e carrossel
│       ├── story_viewer_screen.dart # Visualizador de stories em tela cheia com progresso
│       ├── liquid_glass.dart      # Efeitos visuais de vidro fosco e desfoque
│       ├── liquid_glass_navigation_bar.dart # Dock inferior flutuante estilizado
│       ├── liquid_background.dart # Fundo orgânico com iluminação dinâmica
│       └── feed_video_player.dart # Player de vídeo multiplataforma
├── .github/workflows/
│   └── main.yml                   # Pipeline de CI/CD para compilação multi-OS
└── pubspec.yaml                   # Dependências e metadados do app
```

---

## 🤖 Pipeline de CI/CD Multiplataforma

O repositório conta com um workflow automatizado no **GitHub Actions** (`.github/workflows/main.yml`) que compila e empacota simultaneamente todos os instaladores em máquinas virtuais Ubuntu, Windows e macOS a cada nova tag:

- 📱 **Android**: Compilação com JDK 17 e Flutter estável gerando `socialfeed-android.apk`.
- 🐧 **Linux**: Empacotamento Debian gerando pacote instalável `socialfeed-linux.deb`.
- 🪟 **Windows**: Compilação Release nativa e geração de instalador via Inno Setup (`SocialFeed-Setup.exe`).
- 🍏 **macOS**: Bundle nativo empacotado em imagem de disco montável (`socialfeed-macos.dmg`).
- 📱 **iOS**: Arquivo de distribuição assinado (`socialfeed-ios.ipa`).

Todos os binários gerados são anexados automaticamente nas **GitHub Releases** do projeto.

---

## 🤝 Como Contribuir

Contribuições são muito bem-vindas! Se você deseja sugerir novas funcionalidades, melhorar o visual ou adicionar novos scrapers públicos:

1. Faça um **Fork** do repositório.
2. Crie uma branch para a sua feature (`git checkout -b feature/nova-funcionalidade`).
3. Faça commit das suas alterações (`git commit -m 'feat: Adiciona visualizador aprimorado'`).
4. Envie para o seu fork (`git push origin feature/nova-funcionalidade`).
5. Abra um **Pull Request**.

---

## 📄 Licença

Este projeto é distribuído sob a licença **MIT**. Consulte o arquivo `LICENSE` para mais detalhes.

<div align="center">
  <sub>Construído com ❤️ em Flutter para uma web mais livre, rápida e sem distrações.</sub>
</div>
