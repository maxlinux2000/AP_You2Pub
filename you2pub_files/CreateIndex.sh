#!/bin/bash

# 1. Ir a la raíz del proyecto
cd "$HOME/public_html/You2Pub" || exit 1

# 2. Buscar carpetas de canales (Nivel 1)
# Excluimos carpetas de sistema con el truco del maxdepth que vimos
find . -maxdepth 1 -mindepth 1 -type d ! -name "img" ! -name "js" ! -name "css" | while read -r Channel; do
    
    echo "📂 Entrando al Canal: $Channel"

    # Usamos ( ) para crear un subshell. Al cerrarse el paréntesis, 
    # volvemos automáticamente a la carpeta de origen sin necesidad de cd .. o cd -
    (
        cd "$Channel" || exit
        
        # 3. Buscar carpetas de videos dentro del canal (Nivel 1 de la subcarpeta)
        find . -maxdepth 1 -mindepth 1 -type d ! -name "img" ! -name "js" ! -name "css" | while read -r Video; do
            (
                cd "$Video" || exit
                echo "   🎥 Generando video en: $Video"
                # Ejecutamos el generador pasándole la ruta actual
                # Asegúrate que generate_video.sh esté en tu PATH o usa la ruta completa
                generate_video.sh "." #  "tudominio.com" "/You2Pub"
            )
        done
        
        # 4. Al terminar los videos, actualizamos el canal
        echo "   ✨ Actualizando índice del canal..."
        generate_channel.sh "."
    )

done

# 5. Al final de todo, actualizamos la raíz
echo "🚀 Actualizando Home principal..."
generate_root.sh .
generate_menu.sh .

echo "✅ Conversión completa."
