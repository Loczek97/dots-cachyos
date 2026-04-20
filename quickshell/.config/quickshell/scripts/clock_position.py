import sys, json
import numpy as np
from PIL import Image

def analyze_wallpaper(image_path, output_json_path):
    try:
        img = Image.open(image_path).convert("RGB")
        img.thumbnail((300, 300))
        w, h = img.size
        data = np.array(img).astype(float)
        clock_w, clock_h = int(w * 0.22), int(h * 0.32)
        edge_safe = int(w * 0.05)
        best_score = float('inf')
        best_pos = (edge_safe, edge_safe)
        for y in range(edge_safe, h - clock_h - edge_safe, 4):
            for x in range(edge_safe, w - clock_w - edge_safe, 4):
                window = data[y:y+clock_h, x:x+clock_w]
                std = np.std(window[:,:,0]) + np.std(window[:,:,1]) + np.std(window[:,:,2])
                dist = min(x-edge_safe, (w-clock_w-edge_safe)-x) + min(y-edge_safe, (h-clock_h-edge_safe)-y)
                score = std + (dist * 5.0)
                if score < best_score:
                    best_score, best_pos = score, (x, y)
        is_bottom, is_right = best_pos[1] > (h // 2), best_pos[0] > (w // 2)
        mx, my = int((best_pos[0] / w) * 1920), int((best_pos[1] / h) * 1080)
        final_mx = (1920 - mx - 260) if is_right else mx
        final_my = (1080 - my - 380) if is_bottom else my
        data = {
            "anchorBottom": final_my if is_bottom else 0,
            "anchorTop": 0 if is_bottom else final_my,
            "anchorRight": final_mx if is_right else 0,
            "anchorLeft": 0 if is_right else final_mx,
            "isBottom": is_bottom,
            "isRight": is_right
        }
        with open(output_json_path, "w") as f: json.dump(data, f)
    except Exception as e: print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 2: analyze_wallpaper(sys.argv[1], sys.argv[2])
