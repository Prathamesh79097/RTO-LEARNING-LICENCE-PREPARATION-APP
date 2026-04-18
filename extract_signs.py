import sys
import subprocess

try:
    import fitz  # PyMuPDF
except ImportError:
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'pymupdf'])
    import fitz

import os
import json

def extract_signs(pdf_path, output_dir, json_path):
    os.makedirs(output_dir, exist_ok=True)
    doc = fitz.open(pdf_path)
    
    signs = []
    image_counter = 1
    
    for page_num in range(len(doc)):
        page = doc[page_num]
        
        # Get all horizontal text blocks to match with images
        text_blocks = page.get_text("blocks")
        images = page.get_images(full=True)
        
        print(f"Page {page_num}: Found {len(images)} images and {len(text_blocks)} text blocks")
        
        # We will try a simple heuristic: simply extract images and we will assign dummy names if we can't map them perfectly
        # or we will try to find text close to the image.
        
        for img_index, img in enumerate(images):
            xref = img[0]
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            image_ext = base_image["ext"]
            
            # Save image
            img_filename = f"sign_{page_num}_{img_index}.{image_ext}"
            img_filepath = os.path.join(output_dir, img_filename)
            
            with open(img_filepath, "wb") as f:
                f.write(image_bytes)
                
            # Attempt to find text related to this image.
            # get_image_rects(xref) returns bounding boxes for this image on the page
            try:
                rects = page.get_image_rects(xref)
                if rects:
                    img_rect = rects[0]
                    # Find text block that is below or near the image
                    # We'll just grab the text block whose coordinates are physically closest or below it.
                    closest_text = "Unknown Sign"
                    min_dist = 99999
                    
                    for b in text_blocks:
                        # b is (x0, y0, x1, y1, "text", block_no, block_type)
                        if b[6] == 0: # 0 means text block
                            text_rect = fitz.Rect(b[:4])
                            text_str = b[4].strip()
                            if len(text_str) < 2: continue
                            
                            # calculate distance from bottom of image to top of text block
                            if text_rect.y0 >= img_rect.y1: # Text is below image
                                dist = text_rect.y0 - img_rect.y1
                                if dist >= 0 and dist < min_dist:
                                    min_dist = dist
                                    # clean up text
                                    text_str = text_str.replace('\n', ' ')
                                    closest_text = text_str
                                    
                    signs.append({
                        "name": closest_text,
                        "image": f"assets/signs/{img_filename}",
                        "description": closest_text
                    })
                else:
                    signs.append({
                        "name": f"Sign {image_counter}",
                        "image": f"assets/signs/{img_filename}",
                        "description": "Traffic Sign"
                    })
            except Exception as e:
                print(f"Error mapping text to image {xref}: {e}")
                signs.append({
                    "name": f"Sign {image_counter}",
                    "image": f"assets/signs/{img_filename}",
                    "description": "Traffic Sign"
                })
                
            image_counter += 1
            
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(signs, f, indent=4)
        print(f"Wrote {len(signs)} signs to {json_path}")

if __name__ == "__main__":
    pdf_file = r"C:\Users\Prathamesh\Downloads\ROAD-SIGNS.pdf"
    out_dir = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\signs"
    json_path = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\data\signs.json"
    
    extract_signs(pdf_file, out_dir, json_path)
