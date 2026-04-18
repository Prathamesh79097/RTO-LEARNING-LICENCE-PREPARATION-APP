import fitz
import os

pdf_file = r"C:\Users\Prathamesh\Downloads\ROAD-SIGNS.pdf"
out_dir = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\signs_pdf"

os.makedirs(out_dir, exist_ok=True)
doc = fitz.open(pdf_file)

zoom = 3.0
mat = fitz.Matrix(zoom, zoom)

for page_num in range(len(doc)):
    page = doc[page_num]
    pix = page.get_pixmap(matrix=mat)
    img_path = os.path.join(out_dir, f"road_signs_page_{page_num + 1}.png")
    pix.save(img_path)
    print(f"Rendered Page {page_num + 1} to {img_path}")
