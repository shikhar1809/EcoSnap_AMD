from transformers import pipeline
from PIL import Image
import io
import base64
import matplotlib.pyplot as plt
import numpy as np
import torch

# Initialize Depth Estimation Pipeline
# Using 'depth-anything-small' for speed and good accuracy
try:
    pipe = pipeline(task="depth-estimation", model="LiheYoung/depth-anything-small-hf")
except Exception as e:
    print(f"Error loading depth model: {e}")
    pipe = None

class DepthService:
    @staticmethod
    def generate_depth_map(image_bytes: bytes) -> str:
        """
        Generates a colorized depth map heatmap from image bytes.
        Returns: Base64 string of the depth map image.
        """
        if not pipe:
            return None

        try:
            # 1. Load Image
            image = Image.open(io.BytesIO(image_bytes))
            
            # 2. Estimate Depth
            # result['depth'] is a PIL Image object
            depth_result = pipe(image)
            depth_pil = depth_result["depth"]
            
            # 3. Apply Colormap (Inferno/Magma looks cool for heatmaps)
            depth_array = np.array(depth_pil)
            
            # Normalize to 0-1
            depth_min = depth_array.min()
            depth_max = depth_array.max()
            depth_norm = (depth_array - depth_min) / (depth_max - depth_min)
            
            # Apply colormap (matplotlib)
            # 'viridis' is excellent for depth perception (Yellow=Close, Blue=Far)
            colormap = plt.get_cmap("viridis") 
            depth_colored = colormap(depth_norm)
            
            # Convert RGBA to RGB (drop alpha) and scale to 0-255
            depth_rgb = (depth_colored[:, :, :3] * 255).astype(np.uint8)
            depth_colored_pil = Image.fromarray(depth_rgb)
            
            # 4. Convert to Base64
            buffered = io.BytesIO()
            depth_colored_pil.save(buffered, format="JPEG")
            img_str = base64.b64encode(buffered.getvalue()).decode("utf-8")
            
            return img_str
            
        except Exception as e:
            print(f"Depth Generation Error: {e}")
            return None
