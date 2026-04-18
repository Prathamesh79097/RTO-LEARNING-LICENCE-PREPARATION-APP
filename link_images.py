import json
import fitz
import os

def link_images(pdf_path, json_path, output_dir):
    os.makedirs(output_dir, exist_ok=True)
    doc = fitz.open(pdf_path)
    
    with open(json_path, 'r', encoding='utf-8') as f:
        questions = json.load(f)
        
    img_counter = {}
    
    # We will iterate through PDF pages, find images, and associate them with the nearest text.
    for page_num in range(len(doc)):
        page = doc[page_num]
        
        # Get all text blocks
        blocks = page.get_text("blocks")
        images = page.get_images(full=True)
        
        for img_index, img in enumerate(images):
            xref = img[0]
            try:
                rects = page.get_image_rects(xref)
            except Exception:
                continue
            if not rects: continue
            
            img_rect = rects[0]
            
            # Find the text block that is closest ABOVE or TO THE LEFT of the image, or simply the closest text
            closest_text = ""
            min_dist = 99999
            
            for b in blocks:
                if b[6] == 0:  # Text block
                    text_rect = fitz.Rect(b[:4])
                    text_str = b[4].strip().replace('\n', ' ')
                    
                    if len(text_str) < 5: continue
                    
                    # Distance logic: we want text that is near the image.
                    # Since questions could be "Q_NUMBER: What does this sign mean?", we check distance.
                    # Usually, the image is right next to or below the question text.
                    dy = abs((text_rect.y0 + text_rect.y1)/2 - (img_rect.y0 + img_rect.y1)/2)
                    dx = abs((text_rect.x0 + text_rect.x1)/2 - (img_rect.x0 + img_rect.x1)/2)
                    dist = dy + dx
                    
                    if dist < min_dist:
                        min_dist = dist
                        closest_text = text_str
            
            # Now we find which question in our list matches this closest text best
            best_match_idx = -1
            best_match_score = 0
            
            closest_text_lower = closest_text.lower()
            
            for i, q in enumerate(questions):
                q_text = q['question'].lower()
                # Simple substring match or overlap
                overlap = len(set(closest_text_lower.split()) & set(q_text.split()))
                if overlap > best_match_score:
                    best_match_score = overlap
                    best_match_idx = i
                    
            if best_match_idx != -1 and best_match_score >= 1: # at least some words match
                # Extract image
                base_image = doc.extract_image(xref)
                image_bytes = base_image["image"]
                image_ext = base_image["ext"]
                
                img_filename = f"q_img_{best_match_idx}.{image_ext}"
                img_filepath = os.path.join(output_dir, img_filename)
                
                with open(img_filepath, "wb") as f:
                    f.write(image_bytes)
                    
                questions[best_match_idx]["image"] = f"assets/data/question_images/{img_filename}"
                print(f"Matched image page {page_num} to question '{questions[best_match_idx]['question'][:30]}...'")

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=4)
    print(f"Updated questions.json with images.")

if __name__ == "__main__":
    pdf_path = r"C:\Users\Prathamesh\Downloads\RTO_QUIZ_QUESTIONS.pdf"
    json_path = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\data\questions.json"
    out_dir = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\data\question_images"
    link_images(pdf_path, json_path, out_dir)
