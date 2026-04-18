import json
import re

def parse_rules(txt_path, json_path):
    with open(txt_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The text has rules like "2. Keep Left.-The driver..."
    # We will split by newlines and try to merge lines since paragraphs are broken
    content = content.replace('\n', ' ')
    
    # regex to match rule number, title, and description
    # e.g. " 2. Keep Left.-The driver..."
    
    pattern = re.compile(r'\b(\d{1,2})\.\s+(.*?)\.-(.*?)(?=\b\d{1,2}\.\s+|$)', re.DOTALL)
    matches = pattern.findall(content)
    
    rules = []
    for match in matches:
        num, title, desc = match
        # skip rule 1 (Short title and commencement) if present, and only include actual driving rules
        if num == "1" or "Short title" in title:
            continue
            
        desc = desc.strip()
        # Clean up some OCR or formatting artifacts
        desc = re.sub(r'\s+', ' ', desc)
        
        # some titles have numbering or formatting attached, but mostly clean.
        title = title.strip()
        
        rules.append({
            "title": title,
            "description": desc
        })
        
    import os
    os.makedirs(os.path.dirname(json_path), exist_ok=True)
    with open(json_path, 'w', encoding='utf-8') as f:
        json.dump(rules, f, indent=4)
    print(f"Generated {len(rules)} rules to {json_path}")

if __name__ == "__main__":
    txt_file = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\extracted_rules.txt"
    json_file = r"C:\Users\Prathamesh\OneDrive\Desktop\RTO_LL_APP\assets\data\rules.json"
    parse_rules(txt_file, json_file)
