import sys
import subprocess
try:
    import pdfplumber
except ImportError:
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'pdfplumber'])
    import pdfplumber

import json

pdf_path = r"C:\Users\Prathamesh\Downloads\RTO_QUIZ_QUESTIONS.pdf"
out_json = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\data\questions.json"

questions = []

try:
    with pdfplumber.open(pdf_path) as pdf:
        # Assuming the first page has headers, we extract tables
        for page_num, page in enumerate(pdf.pages):
            tables = page.extract_tables()
            for table in tables:
                for row in table:
                    # Filter out headers and empty rows
                    if not row or row[0] == "Q_NUMBER":
                        continue
                    
                    # Typical row: [Q_NUMBER, QUESTION, OPTION1, OPTION2, OPTION3, ANSWER]
                    if len(row) >= 6:
                        q_num = row[0]
                        question_text = row[1]
                        options = [row[2], row[3], row[4]]
                        answer = row[5]
                        
                        # Clean up
                        if not question_text: continue
                        question_text = str(question_text).replace('\n', ' ').strip()
                        options = [str(opt).replace('\n', ' ').strip() for opt in options if opt]
                        answer = str(answer).replace('\n', ' ').strip()
                        
                        questions.append({
                            "question": question_text,
                            "options": options,
                            "answer": answer
                        })
    
    with open(out_json, "w", encoding="utf-8") as f:
        json.dump(questions, f, indent=4)
        
    print(f"Successfully extracted {len(questions)} questions!")
except Exception as e:
    print(f"Error: {e}")
