import sys, json
import numpy as np
from PIL import Image

# Clock widget dimensions
CLOCK_WIDTH = 400
CLOCK_HEIGHT = 500
# Target screen resolution for calculation
SCREEN_WIDTH = 1920
SCREEN_HEIGHT = 1080

def analyze_wallpaper(image_path, output_json_path):
    try:
        img = Image.open(image_path).convert("RGB")
        # Resize for faster analysis
        analysis_size = 300
        img.thumbnail((analysis_size, analysis_size))
        w, h = img.size
        data = np.array(img).astype(float)
        
        # Calculate clock dimensions relative to the analysis image size
        clock_w = int(w * (CLOCK_WIDTH / SCREEN_WIDTH))
        clock_h = int(h * (CLOCK_HEIGHT / SCREEN_HEIGHT))
        
        edge_safe = int(w * 0.05)
        best_score = float('inf')
        best_pos = (edge_safe, edge_safe)
        
        # Scan for the area with the least amount of detail (lowest standard deviation)
        # while preferring corners/edges
        for y in range(edge_safe, h - clock_h - edge_safe, 4):
            for x in range(edge_safe, w - clock_w - edge_safe, 4):
                window = data[y:y+clock_h, x:x+clock_w]
                # Detail level
                std = np.std(window[:,:,0]) + np.std(window[:,:,1]) + np.std(window[:,:,2])
                # Prefer edges: dist is smaller when closer to any edge_safe boundary
                dist = min(x-edge_safe, (w-clock_w-edge_safe)-x) + min(y-edge_safe, (h-clock_h-edge_safe)-y)
                score = std + (dist * 5.0)
                
                if score < best_score:
                    best_score, best_pos = score, (x, y)
        
        is_bottom = best_pos[1] > (h // 2)
        is_right = best_pos[0] > (w // 2)
        
        # Map back to screen coordinates
        mx = int((best_pos[0] / w) * SCREEN_WIDTH)
        my = int((best_pos[1] / h) * SCREEN_HEIGHT)
        
        # Calculate margins for the JSON output
        # If right-aligned, we calculate distance from right edge
        final_mx = (SCREEN_WIDTH - mx - CLOCK_WIDTH) if is_right else mx
        # If bottom-aligned, we calculate distance from bottom edge
        final_my = (SCREEN_HEIGHT - my - CLOCK_HEIGHT) if is_bottom else my
        
        data = {
            "anchorBottom": final_my if is_bottom else 0,
            "anchorTop": 0 if is_bottom else final_my,
            "anchorRight": final_mx if is_right else 0,
            "anchorLeft": 0 if is_right else final_mx,
            "isBottom": is_bottom,
            "isRight": is_right
        }
        
        with open(output_json_path, "w") as f:
            json.dump(data, f, indent=4)
            
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    if len(sys.argv) > 2:
        analyze_wallpaper(sys.argv[1], sys.argv[2])
