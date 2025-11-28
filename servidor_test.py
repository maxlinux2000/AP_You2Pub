import http.server
import socketserver
import webbrowser
import os
import sys

# --- Configuración ---
PORT = 5555
# Define la ruta absoluta al directorio de Videos
DIRECTORY = os.path.abspath("Videos") 
# El directorio de trabajo inicial
INITIAL_CWD = os.getcwd() 

# Usamos la clase simple pero le decimos que sirva desde un directorio específico
class Handler(http.server.SimpleHTTPRequestHandler):
    
    # Sobreescribimos el constructor para pasar la ruta del directorio
    def __init__(self, *args, directory=None, **kwargs):
        # El directorio a servir debe pasarse a SimpleHTTPRequestHandler
        # Nos aseguramos de servir el directorio 'Videos' (ahora absoluto)
        super().__init__(*args, directory=DIRECTORY, **kwargs)

try:
    # Intenta abrir el puerto y el navegador
    Handler.extensions_map.update({
        '.webapp': 'application/x-web-app-manifest+json',
    })
    
    # Creamos el servidor con el manejador corregido
    with socketserver.TCPServer(("", PORT), Handler) as httpd:
        
        print("-----------------------------------------------------")
        print(f"✅ Servidor HTTP iniciado correctamente en el puerto {PORT}")
        print(f"📂 Sirviendo el contenido del directorio: {DIRECTORY}")
        print("-----------------------------------------------------")
        
        # Abre automáticamente el navegador
        webbrowser.open_new_tab(f"http://localhost:{PORT}/")

        # Inicia el bucle de escucha del servidor
        httpd.serve_forever()

except KeyboardInterrupt:
    print("\n-----------------------------------------------------")
    print("🔌 Servidor detenido por el usuario.")
    print("-----------------------------------------------------")
    sys.exit(0) # Salida limpia
except Exception as e:
    print(f"\n❌ Ocurrió un error: {e}")
    sys.exit(1)
