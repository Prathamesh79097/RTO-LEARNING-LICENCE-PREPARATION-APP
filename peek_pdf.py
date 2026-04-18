import fitz

pdf_path = r"C:\Users\Prathamesh\Downloads\RTO_QUIZ_QUESTIONS.pdf"
try:
    doc = fitz.open(pdf_path)
    for i in range(min(3, len(doc))):
        page = doc[i]
        print(f"--- PAGE {i} ---")
        print(page.get_text("text"))
        images = page.get_images()
        print(f"Images on page {i}: {len(images)}")
except Exception as e:
    print(e)
