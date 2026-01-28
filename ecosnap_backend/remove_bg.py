from PIL import Image
import os

def remove_background(input_path, output_path):
    print(f"Processing {input_path}...")
    try:
        img = Image.open(input_path)
        img = img.convert("RGBA")
        datas = img.getdata()

        newData = []
        for item in datas:
            # If pixel is white (or very light gray), make it transparent
            if item[0] > 240 and item[1] > 240 and item[2] > 240:
                newData.append((255, 255, 255, 0))
            else:
                newData.append(item)

        img.putdata(newData)
        img.save(output_path, "PNG")
        print(f"Saved transparent image to {output_path}")
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    input_file = r"C:/Users/royal/.gemini/antigravity/brain/e27a24b0-cb40-4d37-b087-e3680810bb89/leaf_on_white_1769565243852.png"
    output_file = r"C:/Users/royal/.gemini/antigravity/brain/e27a24b0-cb40-4d37-b087-e3680810bb89/transparent_logo.png"
    remove_background(input_file, output_file)
