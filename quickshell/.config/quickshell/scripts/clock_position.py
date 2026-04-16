import sys
import numpy as np
from PIL import Image

def analyze_wallpaper(image_path, output_qml_path):
    try:
        img = Image.open(image_path).convert("RGB")
        img.thumbnail((300, 300))
        w, h = img.size
        data = np.array(img).astype(float)
        
        clock_w, clock_h = int(w * 0.22), int(h * 0.32)
        edge_safe = int(w * 0.05)
        
        best_score = float('inf')
        best_pos = (edge_safe, edge_safe)
        
        # Skanujemy obraz
        for y in range(edge_safe, h - clock_h - edge_safe, 4):
            for x in range(edge_safe, w - clock_w - edge_safe, 4):
                window = data[y:y+clock_h, x:x+clock_w]
                
                # 1. Obliczamy wariancję (zróżnicowanie kolorów) - im mniej, tym lepiej
                std_r = np.std(window[:,:,0])
                std_g = np.std(window[:,:,1])
                std_b = np.std(window[:,:,2])
                total_variation = std_r + std_g + std_b
                
                # 2. Obliczamy dystans od najbliższego rogu (faworyzacja rogów)
                # Dystans to suma odległości od najbliższej krawędzi X i Y
                dist_x = min(x - edge_safe, (w - clock_w - edge_safe) - x)
                dist_y = min(y - edge_safe, (h - clock_h - edge_safe) - y)
                dist_to_corner = dist_x + dist_y
                
                # SYSTEM WAG:
                # Mnożnik dystansu jest wysoki (5.0), co sprawia, że zegar "trzyma się" rogów.
                # Dopiero gdy total_variation w rogu jest drastycznie większa niż kawałek dalej,
                # zegar zdecyduje się na przesunięcie.
                score = (total_variation * 1.0) + (dist_to_corner * 5.0)
                
                if score < best_score:
                    best_score = score
                    best_pos = (x, y)

        # Wyznaczamy flagi kierunku i marginesy (skala 1920x1080)
        is_bottom = best_pos[1] > (h // 2)
        is_right = best_pos[0] > (w // 2)
        
        mx = int((best_pos[0] / w) * 1920)
        my = int((best_pos[1] / h) * 1080)
        
        # Rozmiar widgetu w 1080p
        final_mx = (1920 - mx - 260) if is_right else mx
        final_my = (1080 - my - 380) if is_bottom else my

        # Twarda blokada granic
        final_mx = max(40, min(1600, final_mx))
        final_my = max(40, min(650, final_my))

        content = f"""pragma Singleton
import QtQuick

QtObject {{
    property int anchorBottom: {final_my if is_bottom else 0}
    property int anchorTop: {0 if is_bottom else final_my}
    property int anchorRight: {final_mx if is_right else 0}
    property int anchorLeft: {0 if is_right else final_mx}
    property bool isBottom: {'true' if is_bottom else 'false'}
    property bool isRight: {'true' if is_right else 'false'}
}}
"""
        with open(output_qml_path, "w") as f: f.write(content)

    except Exception as e: print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 2: analyze_wallpaper(sys.argv[1], sys.argv[2])
