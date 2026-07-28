# Utilitário Scrcpy
### Um pequeno utilitário para [Scrcpy](https://github.com/Genymobile/scrcpy) feito com [Bash](https://www.gnu.org/software/bash/) e [YAD](https://github.com/v1cont/yad).

Este é um utilitário para interagir com o Scrcpy de diversos modos diferentes, sendo eles:
- Normal
- Áudio
- Desktop
- Microfone

## Pré-requisitos
É preciso um cabo USB com suporte à ADB conectado entre o celular e o computador.
Para checar se o cabo funciona, executar `adb devices` com o celular conectado. Ele deverá aparecer listado.

### No PC:
- Estar no Linux.
- Ter o YAD, ADB e Scrcpy instalados. Para instalar no Debian/Ubuntu & derivados: `sudo apt install yad adb scrcpy`

### No celular:
- Ter o modo desenvolvedor ativado.
- Nas opções de desenvolvedor, ter "Depuração USB" ativada. Em celulares Xiaomi, também ter ativada "Depuração USB (Config. de Segurança).
- Opcional: Instalar o HyperDroid, pela Play Store, para uma experiência mais imersiva.

# Informações adicionais
O script foi testado no Redmi Note 8 e Redmi 12, o posterior sendo um celular recente.

No Redmi 12, com Minecraft rodando, a latência no modo Desktop/perfil Qualidade ficou comparável à jogar um jogo pela nuvem. Eu considero isso bem jogável.

No modo Desktop, com o HyperDroid instalado, o script irá colocar automaticamente o HyperDroid em primeiro plano sempre que estiver na tela inicial do celular. Para desabilitar isso, desinstale o HyperDroid ou retire qualquer parte envolvendo o HyperDroid do script.

> Vídeo: Executando Minecraft Bedrock no modo Desktop, perfil Qualidade...

https://github.com/user-attachments/assets/53bc4532-cd22-4927-96fd-da591c2e37bc

**Sinta-se à vontade para fazer um fork, modificar ou redistribuir esse script.**
