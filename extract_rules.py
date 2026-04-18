import sys
import json

try:
    import PyPDF2
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'PyPDF2'])
    import PyPDF2

def extract_text_from_pdf(pdf_path):
    text = ""
    with open(pdf_path, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        for page_num in range(len(reader.pages)):
            page = reader.pages[page_num]
            text += page.extract_text() + "\n"
    return text

if __name__ == "__main__":
    pdf_path = r"C:\Users\Prathamesh\Downloads\RTO_RULES.pdf"
    try:
        text = extract_text_from_pdf(pdf_path)
        with open(r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\extracted_rules.txt", "w", encoding="utf-8") as f:
            f.write(text)
        print("Successfully extracted text to extracted_rules.txt")
    except Exception as e:
        print(f"Error: {e}")
