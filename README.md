# 🏦 Caixa Fácil App

O **Caixa Fácil App** é um aplicativo mobile desenvolvido em Flutter que tem como objetivo auxiliar usuários a localizar agências da Caixa Econômica Federal próximas, visualizar o nível de ocupação atual e receber recomendações de agências com menor tempo de espera.

## ✨ Funcionalidades

O aplicativo oferece as seguintes funcionalidades principais:

* **Visualização de Mapa:** Exibe as agências em um mapa interativo, permitindo a navegação e o zoom.
* **Localização Atual:** Botão flutuante para centralizar o mapa na localização atual do usuário (requer permissão de GPS).
* **Busca por Endereço/Coordenadas:** Permite buscar agências próximas a um endereço ou coordenadas específicas.
* **Marcadores Interativos:** Ao tocar no marcador de uma agência, um *bottom sheet* (folha inferior) exibe detalhes como nome, endereço, serviços, ocupação e tempo de espera estimado.
* **Estimativa de Espera:** Calcula o tempo de espera estimado com base na ocupação e capacidade da agência.
* **Recomendação Inteligente:** A função "Recomendar" sugere a melhor agência nas proximidades, priorizando o **menor tempo de espera** sobre a distância.
* **Dados de Exemplo:** Funcionalidade para gerar agências de exemplo com ocupação aleatória ao redor da posição atual do mapa para testes e demonstração.

## ⚙️ Tecnologias e Pacotes Utilizados

O projeto é construído em Flutter e utiliza os seguintes pacotes essenciais:

| Pacote | Uso |
| :--- | :--- |
| `flutter_map` | Componente de mapa interativo baseado em OpenStreetMap. |
| `latlong2` | Utilitários para manipulação de coordenadas geográficas. |
| `geolocator` | Acesso à geolocalização do dispositivo (GPS). |
| `url_launcher` | Abrir links externos, como direções no Google Maps. |
| `geocoding_service` | Serviço para converter endereços em coordenadas (necessário implementar). |

## 🚀 Como Executar o Projeto

### Pré-requisitos

Certifique-se de ter o Flutter SDK instalado e configurado em sua máquina.

### Instalação

1.  **Clone o repositório:**
    ```bash
    git clone https://github.com/CC-UNIPE-MARLONRN/CaixaFacil_App.git
    cd caixafacil_app
    ```

2.  **Instale as dependências:**
    ```bash
    flutter pub get
    ```

3.  **Execute o aplicativo:**
    ```bash
    flutter run
    ```

    > **Nota:** Certifique-se de que um emulador Android/iOS ou um dispositivo físico esteja conectado e rodando.

### Configurações Nativas (Ícone e Nome)

Para que o aplicativo seja exibido corretamente no seu celular, certifique-se de que as configurações nativas foram aplicadas:

1.  **Nome do Aplicativo:** Verifique se o nome `"Caixa Fácil"` está definido corretamente nos arquivos `AndroidManifest.xml` (Android) e `Info.plist` (iOS).
2.  **Ícone do Aplicativo:** Se você usou o pacote `flutter_launcher_icons`, certifique-se de ter rodado o comando de geração do ícone:
    ```bash
    flutter pub run flutter_launcher_icons:main
    ```
    E, em seguida, reconstrua o projeto (`flutter clean` seguido de `flutter run`).

## ✍️ Contribuição

Sinta-se à vontade para contribuir com o projeto. Abra *issues* para relatar bugs ou *pull requests* com novas funcionalidades.

## ⚖️ Licença

[Selecione a licença do seu projeto, por exemplo, MIT ou GPL]
