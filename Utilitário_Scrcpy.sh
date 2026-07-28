#!/bin/bash

# Este é um utilitário para interagir com o Scrcpy de diversas formas diferentes, incluindo um "modo DEX" falso (modo Desktop)

# /// NO PC:
# É necessário ter o YAD, ADB e Scrcpy instalados. [sudo apt install yad adb scrcpy]

# /// NO CELULAR:
# É necessário ter o modo desenvolvedor ativado.
# Nas opções do desenvolvedor, ativar "Depuração USB". Em celulares Xiaomi, também ativar "Depuração USB (Config. de segurança)"
# Opcional: Instalar o HyperDroid, pela Play Store, para uma experiência mais imersiva.

# É preciso um cabo USB com suporte à ADB conectado entre o celular e o computador.
# Para checar se o cabo funciona, executar [adb devices]. Deverá aparecer o celular listado.



# Tirar qualquer erro para um output mais limpo. Se quiser fazer debug, remova essa linha.
exec 2>/dev/null

# Cancelar a execução se não houver dispositivos conectados no ADB.
if ! adb get-state >/dev/null 2>&1; then
    echo "Não foi possível encontrar dispositivos no ADB."

    yad --error \
        --title="Utilitário Scrcpy" \
        --text="
Não há nenhum dispositivo conectado pelo ADB!

Verifique se:
- O celular está conectado por USB;
- O cabo tem suporte ao ADB;
- A Depuração USB está ativada.
" \
        --width=420

    exit 1
fi

# Janela de seleção dos modos.
#   /// MODOS:
#       - Normal: Executar Scrcpy nas configurações padrões.
#       - Áudio: Receber apenas o áudio de saída do celular.
#       - Desktop: Configurar o celular para se parecer com um computador.
#       - Microfone: Receber apenas o áudio de entrada do celular.
modos=$(yad \
    --title="Utilitário Scrcpy" \
    --list \
    --column="Escolha um modo de execução:" \
        "Normal" \
        "Áudio" \
        "Desktop" \
        "Microfone" \
    --width=300 \
    --height=150
)

# Se fechou a janela ou cancelou...
if [ $? -ne 0 ]; then
    exit 1
fi

# Limpa saída do YAD (evita um bug de selecionar e acontecer nada).
modos=$(echo "$modos" | cut -d'|' -f1 | xargs)

# Função opcional: Faz uso do Hyperdroid para uma experiência mais "imersiva".
setup_hyperdroid() {
    echo "Verificando HyperDroid..."

    if ! adb shell pm list packages | grep -q "^package:com.binary.hyperdroid$"; then
        echo "HyperDroid não encontrado."

        yad --info \
            --title="Utilitário Scrcpy" \
            --text="
HyperDroid não está instalado.

O modo Desktop será iniciado normalmente.
" \
            --width=350 \
            --timeout=2 &

        sleep 2
        return 0
    fi

    echo "HyperDroid encontrado."

    LAUNCHER_PACKAGE=$(
        adb shell cmd package resolve-activity \
            -a android.intent.action.MAIN \
            -c android.intent.category.HOME |
        awk -F= '/packageName=/{print $2; exit}' |
        tr -d '\r'
    )

    # Função para abrir o Hyperdroid sempre que não há aplicativos em primeiro plano.
    verificar_hyperdroid() {
        FOREGROUND_PACKAGE=$(
            adb shell dumpsys activity activities |
            grep -m1 "mResumedActivity\|topResumedActivity" |
            sed -E 's/.* ([^ ]+)\/.*/\1/' |
            tr -d '\r'
        )

        if [ "$FOREGROUND_PACKAGE" = "$LAUNCHER_PACKAGE" ]; then
            adb shell monkey -p com.binary.hyperdroid 1 >/dev/null 2>&1
            sleep 2
        fi
    }

    echo "Launcher padrão: $LAUNCHER_PACKAGE"
    echo "Abrindo HyperDroid..."

    while true; do
        verificar_hyperdroid
        sleep 0.5
    done &

    HYPERDROID_MONITOR=$!
}


modo_desktop() {
    # Janela de seleção dos perfis de qualidade.
    qualidade=$(yad \
        --title="Utilitário Scrcpy" \
        --list \
        --column="Escolha o perfil para o modo Desktop:" \
        "Performance" \
        "Balanceado" \
        "Qualidade" \
        --width=300 \
        --height=150
    )

    # Se fechou a janela ou cancelou.
    if [ $? -ne 0 ]; then
        return 1
    fi

    # Limpa saída do YAD (evita um bug de selecionar e acontecer nada).
    qualidade=$(echo "$qualidade" | cut -d'|' -f1 | xargs)

    case "$qualidade" in
        Performance)
            VIDEO_BITRATE="1M"
            MAX_SIZE="512"
            ;;
        Balanceado)
            VIDEO_BITRATE="2M"
            MAX_SIZE="1024"
            ;;
        Qualidade)
            VIDEO_BITRATE="3M"
            MAX_SIZE="2048"
            ;;
        *)
            return 1
            ;;
    esac

    echo "Perfil selecionado: $qualidade"
    echo "Bitrate: $VIDEO_BITRATE"
    echo "Resolução máxima: $MAX_SIZE"

    # Obtém resolução do monitor do computador.
    local RESOLUCAO
    RESOLUCAO=$(xrandr | awk '/\*/ {print $1; exit}')

    # Obtém a rotação atual selecionada.
    ROTACAO=$(adb shell wm user-rotation | tr -d '\r')

    # Obtém rotação em modo paisagem do Android.
    local PAISAGEM
    PAISAGEM=$(adb shell dumpsys display | grep -m1 "mCurrentOrientation" | awk -F= '{print $2}' | tr -d '\r')

    echo "Resolução detectada: $RESOLUCAO"
    echo "Configurando modo desktop..."

    setup_hyperdroid

    yad --info \
        --title="Utilitário Scrcpy" \
        --text="Iniciando modo Desktop..." \
        --width=350 \
        --timeout=5 &

    adb shell wm fixed-to-user-rotation enabled
    sleep 2
    adb shell wm density 150
    adb shell wm size "$RESOLUCAO"
    adb shell wm user-rotation lock "$PAISAGEM"

    scrcpy \
        --fullscreen \
        --turn-screen-off \
        --mouse-bind=++++:++++ \
        --mouse=uhid \
        --keyboard=uhid \
        --audio-buffer=100 \
        --video-bit-rate="$VIDEO_BITRATE" \
        --max-size="$MAX_SIZE" \
        --max-fps=60

    # Ao fechar o Scrcpy...
    echo "Scrcpy fechado. Restaurando configurações..."

    adb shell wm fixed-to-user-rotation disabled
    adb shell wm user-rotation "$ROTACAO"
    adb shell wm size reset
    sleep 1
    adb shell wm density reset

    echo "Fechando HyperDroid..."
    if [ -n "$HYPERDROID_MONITOR" ]; then
        kill "$HYPERDROID_MONITOR" 2>/dev/null
    fi
    adb shell am force-stop com.binary.hyperdroid
}

modo_microfone() {
    # Criar e configurar microfone virtual

    echo "Configurando microfone virtual..."

    MODULE_ID=$(
        pactl load-module module-pipe-source \
            source_name="Microfone do celular" \
            channels=2 \
            format=16 \
            rate=48000 \
            file=/tmp/scrcpy_mic
        )
    parec --raw > /dev/null &
    PAREC_PID=$!

    yad --info --title="Utilitário Scrcpy" \
        --text='O microfone está sendo configurado. Selecione "Microfone do celular" como microfone para usa-lo.' \
        --width=350 --delay=4 --timeout=10 &

    sleep 2

    scrcpy \
        --no-playback \
        --no-video \
        --audio-source=mic \
        --audio-codec=raw \
        --record-format=wav \
        --record=/tmp/scrcpy_mic \

    echo "Removendo microfone virtual..."

    kill $PAREC_PID
    pactl unload-module $MODULE_ID
}

case "$modos" in
    Normal)
        echo "Iniciando modo Normal..."
        scrcpy
        ;;
    Áudio)
        echo "Iniciando modo Áudio..."
        scrcpy \
            --no-video \
            --no-control \
            --audio-buffer=200
        ;;
    Desktop)
        echo "Iniciando modo Desktop..."
        modo_desktop
        ;;
    Microfone)
        echo "Iniciando modo Microfone..."
        modo_microfone
        ;;
    *)
        return 1
        ;;
esac

echo "Finalizado."
