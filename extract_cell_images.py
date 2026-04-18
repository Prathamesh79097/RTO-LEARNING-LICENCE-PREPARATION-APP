import pdfplumber
import json
import os

pdf_path = r"C:\Users\Prathamesh\Downloads\RTO_QUIZ_QUESTIONS.pdf"
out_dir = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\data\question_images"
json_path = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\data\questions.json"

os.makedirs(out_dir, exist_ok=True)

with open(json_path, 'r', encoding='utf-8') as f:
    questions = json.load(f)

# Create a mapping from question number to index in the questions array
# Since we used the sequence earlier, let's just re-extract the Q_NUMBERs to match safely or assume sequential.
# But looking at pdfplumber's extract_table, we can also get bounding boxes!
# page.find_tables() returns tables. table.cells returns the bounding boxes of each cell!

def crop_and_extract():
    q_index = 0
    updated_count = 0
    
    with pdfplumber.open(pdf_path) as pdf:
        for page_num, page in enumerate(pdf.pages):
            tables = page.find_tables()
            for table in tables:
                # table.cells is a list of rows, each row is a list of cell bounding boxes (x0, y0, x1, y1)
                # table.extract() gives the text
                cells = table.cells
                texts = table.extract()
                
                for row_idx, row_text in enumerate(texts):
                    if not row_text or row_text[0] == "Q_NUMBER":
                        continue
                    
                    if len(row_text) >= 6 and len(cells[row_idx]) >= 6:
                        question_text = str(row_text[1]).strip()
                        if not question_text:
                            continue
                        
                        question_cell_bbox = cells[row_idx][1] # Bounding box of the QUESTION column
                        
                        # We want to check if this cell actually contains an image or graphic.
                        # Instead of checking, let's just crop the QUESTION cell and save it as the image!
                        # But wait, cropping 400+ cells as images is fine, but maybe we only do it if the cell height is large enough?
                        # A normal text row height is around 20-30. If a cell has an image, its height is usually > 50.
                        # Let's check the height of the question cell.
                        x0, y0, x1, y1 = question_cell_bbox
                        height = y1 - y0
                        
                        if height > 40: # Likely contains an image
                            # Crop the page to this bounding box
                            # Add a small padding
                            crop_box = (x0, y0, x1, y1)
                            try:
                                cropped_page = page.within_bbox(crop_box)
                                im = cropped_page.to_image(resolution=300)
                                
                                img_filename = f"q_img_crop_{q_index}.png"
                                img_filepath = os.path.join(out_dir, img_filename)
                                im.save(img_filepath)
                                
                                if q_index < len(questions):
                                    questions[q_index]["image"] = f"assets/data/question_images/{img_filename}"
                                    updated_count += 1
                                    print(f"[{q_index}] Cropped image for: {question_text[:30]}... (Height: {height:.1f})")
                            except Exception as e:
                                print(f"Error cropping {q_index}: {e}")
                                
                        q_index += 1

    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(questions, f, indent=4)
        
    print(f"Successfully processed and updated {updated_count} question images via cropping!")

if __name__ == "__main__":
    crop_and_extract()
