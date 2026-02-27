from PIL import Image
import os

images = {
    "sofa": r"C:\Users\royal\.gemini\antigravity\brain\522c5b4c-ff17-4808-b331-61bd7c07d9be\sofa_model_1771813484287.png",
    "lamp": r"C:\Users\royal\.gemini\antigravity\brain\522c5b4c-ff17-4808-b331-61bd7c07d9be\lamp_model_1771813503111.png",
    "table": r"C:\Users\royal\.gemini\antigravity\brain\522c5b4c-ff17-4808-b331-61bd7c07d9be\table_model_1771813521563.png",
    "ac": r"C:\Users\royal\.gemini\antigravity\brain\522c5b4c-ff17-4808-b331-61bd7c07d9be\ac_model_1771813536536.png"
}

out_dir = r"c:\Users\royal\Desktop\Resources\Projects\EcoSnap\ecosnap_frontend\assets\images"
os.makedirs(out_dir, exist_ok=True)

for name, path in images.items():
    print(f"Processing {name}...")
    try:
        img = Image.open(path)
        img = img.convert("RGBA")
        datas = img.getdata()

        newData = []
        for item in datas:
            # Tolerant white removal
            if item[0] > 235 and item[1] > 235 and item[2] > 235:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)

        img.putdata(newData)
        
        # Crop the transparent edges for a tighter bounding box
        bbox = img.getbbox()
        if bbox:
            img = img.crop(bbox)
            
        out_path = os.path.join(out_dir, f"{name}_ar.png")
        img.save(out_path, "PNG")
        print(f"Saved {out_path}")
    except Exception as e:
        print(f"Error on {name}: {e}")
