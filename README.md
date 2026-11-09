# SocialFeed

<img src="assets/icon/socialfeed.png" alt="Ícone do SocialFeed" width="96">

O SocialFeed reúne publicações públicas do Instagram, TikTok, X e YouTube em um feed cronológico. Você escolhe os perfis e canais que quer acompanhar e pode consultar as publicações em um só lugar, sem fazer login nas redes sociais.

## Como usar

1. Abra **Pesquisa**, digite um `@usuário` ou cole o link de um perfil. O SocialFeed procura o identificador nas redes compatíveis. Nos resultados, toque em **Seguir** para incluir um perfil no seu feed.
2. Use **+** no cabeçalho para adicionar um perfil de uma rede específica. Para o YouTube, você pode informar o `@handle`, o link ou o ID do canal.
3. Abra **Feed** para ver as publicações mais recentes. Use os filtros por rede ou por perfil e o botão de atualização no cabeçalho para buscar novas publicações.
4. Em **Contas**, pause um perfil para retirá-lo temporariamente do feed ou remova-o da lista. Seguir um perfil no SocialFeed salva a escolha apenas no aplicativo.
5. Em **Ajustes**, escolha o tema claro, escuro ou do sistema, limpe o cache do feed ou restaure a lista inicial de contas.

## Fontes de conteúdo

| Rede | Conteúdo consultado |
| --- | --- |
| Instagram | Publicações e Reels disponíveis nos perfis públicos e nas páginas de incorporação. |
| TikTok | Vídeos disponíveis nas páginas públicas dos perfis e nas páginas de incorporação. |
| X | Posts disponíveis na linha do tempo pública incorporada ou na página do perfil. |
| YouTube | Vídeos recentes do feed Atom público do canal, com consulta à página de vídeos como alternativa quando o feed falha. |

O conteúdo depende do que cada rede retorna em suas páginas públicas. Perfis privados, exigência de login, limites de acesso e mudanças nas páginas podem impedir a atualização. O feed exibe as publicações disponíveis nessas fontes e pode mostrar apenas parte do histórico de um perfil.

Quando a atualização de um perfil falha, o SocialFeed mantém as publicações daquele perfil que já estavam no cache. O aplicativo armazena no dispositivo a lista de contas, o cache do feed, as buscas recentes e a preferência de tema. Consultar novas publicações e carregar mídias remotas exige conexão com a internet.

O player integrado está disponível no Android, iOS, macOS e Windows quando a mídia pode ser carregada diretamente ou incorporada pela rede. No Windows, ele usa o runtime WebView2.

## Executar a partir do código-fonte

Instale o Flutter SDK e configure as ferramentas da plataforma de destino. O projeto inclui os arquivos nativos de Android, iOS, Windows, macOS e Linux.

| Destino | Ambiente de desenvolvimento |
| --- | --- |
| Android | Android SDK, JDK 17 e emulador ou dispositivo Android. |
| iOS | macOS com Xcode e simulador ou dispositivo iOS. Um dispositivo físico requer assinatura configurada. |
| Windows | Windows com Visual Studio e a carga de trabalho de desenvolvimento para desktop com C++. |
| macOS | macOS com Xcode. |
| Linux | Linux com Clang, CMake, Ninja, pkg-config e bibliotecas de desenvolvimento do GTK 3. |

Na raiz do projeto, execute:

```sh
flutter doctor -v
flutter pub get
flutter devices
flutter run -d <id-do-dispositivo>
```

Substitua `<id-do-dispositivo>` pelo identificador exibido por `flutter devices`. Se houver apenas um destino disponível, use `flutter run`.

## Compilar uma versão de lançamento

| Destino | Comando |
| --- | --- |
| Android | `flutter build apk --release` |
| iOS | `flutter build ipa --release` |
| Windows | `flutter build windows --release` |
| macOS | `flutter build macos --release` |
| Linux | `flutter build linux --release` |

- **Android.** O Gradle do projeto usa JDK 17. Se o JDK não for detectado, aponte `SOCIALFEED_JDK17` para o diretório da instalação. O APK é gerado em `build/app/outputs/flutter-apk/app-release.apk`. O projeto usa a chave de depuração nesse build. Configure uma assinatura de produção antes de distribuí-lo.
- **iOS.** Para gerar o IPA, configure a equipe de desenvolvimento e a assinatura no Xcode.
- **Windows.** O CMake procura `nuget.exe` no `PATH`. Se ele estiver ausente, o projeto tenta baixar a versão fixada para compilar a dependência do WebView.

## Estrutura do projeto

| Caminho | Responsabilidade |
| --- | --- |
| [lib/main.dart](lib/main.dart) | Inicialização do Flutter e configuração dos temas. |
| [lib/screens/](lib/screens/) | Telas de feed, pesquisa, contas e ajustes. |
| [lib/models/](lib/models/) | Modelos de perfis, redes sociais e publicações. |
| [lib/services/social_service.dart](lib/services/social_service.dart) | Busca de perfis e coleta de publicações em fontes públicas. |
| [lib/services/storage_service.dart](lib/services/storage_service.dart) | Persistência local das contas e do cache do feed. |
| [lib/widgets/](lib/widgets/) | Cartões, navegação adaptável e player integrado. |
| [assets/icon/](assets/icon/) | Imagem usada no cabeçalho e como fonte dos ícones nativos. |

Depois de alterar [assets/icon/socialfeed.png](assets/icon/socialfeed.png), gere novamente os ícones de Android, iOS, Windows e macOS com:

```sh
dart run flutter_launcher_icons
```

A janela do Linux usa a imagem do pacote de recursos do Flutter. O ícone do cabeçalho também é carregado desse pacote.
